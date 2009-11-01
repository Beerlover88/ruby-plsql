# encoding: utf-8

require File.dirname(__FILE__) + '/../spec_helper'

describe "Function with string parameters" do
  
  before(:all) do
    plsql.connection = get_connection
    plsql.connection.exec <<-EOS
      CREATE OR REPLACE FUNCTION test_uppercase
        ( p_string VARCHAR2 )
        RETURN VARCHAR2
      IS
      BEGIN
        RETURN UPPER(p_string);
      END test_uppercase;
    EOS
  end
  
  after(:all) do
    plsql.logoff
  end
  
  it "should find existing procedure" do
    PLSQL::Procedure.find(plsql, :test_uppercase).should_not be_nil
  end

  it "should not find nonexisting procedure" do
    PLSQL::Procedure.find(plsql, :qwerty123456).should be_nil
  end

  it "should execute function and return correct value" do
    plsql.test_uppercase('xxx').should == 'XXX'
  end

  it "should execute function with named parameters and return correct value" do
    plsql.test_uppercase(:p_string => 'xxx').should == 'XXX'
  end

  it "should raise error if wrong number of arguments is passed" do
    lambda { plsql.test_uppercase('xxx','yyy') }.should raise_error(ArgumentError)
  end

  it "should raise error if wrong named argument is passed" do
    lambda { plsql.test_uppercase(:p_string2 => 'xxx') }.should raise_error(ArgumentError)
  end
  
  it "should execute function with schema name specified" do
    plsql.hr.test_uppercase('xxx').should == 'XXX'
  end

  it "should process nil parameter as NULL" do
    plsql.test_uppercase(nil).should be_nil
  end

end

describe "Function with numeric parameters" do
  
  before(:all) do
    plsql.connection = get_connection
    plsql.connection.exec <<-SQL
      CREATE OR REPLACE FUNCTION test_sum
        ( p_num1 NUMBER, p_num2 NUMBER )
        RETURN NUMBER
      IS
      BEGIN
        RETURN p_num1 + p_num2;
      END test_sum;
    SQL
    plsql.connection.exec <<-SQL
      CREATE OR REPLACE FUNCTION test_number_1
        ( p_num NUMBER )
        RETURN VARCHAR2
      IS
      BEGIN
        IF p_num = 1 THEN
          RETURN 'Y';
        ELSIF p_num = 0 THEN
          RETURN 'N';
        ELSIF p_num IS NULL THEN
          RETURN NULL;
        ELSE
          RETURN 'UNKNOWN';
        END IF;
      END test_number_1;
    SQL
  end
  
  after(:all) do
    plsql.connection.exec "DROP FUNCTION test_sum"
    plsql.connection.exec "DROP FUNCTION test_number_1"
    plsql.logoff
  end
  
  it "should process integer parameters" do
    plsql.test_sum(123,456).should == 579
  end

  it "should process big integer parameters" do
    plsql.test_sum(123123123123,456456456456).should == 579579579579
  end

  it "should process float parameters and return BigDecimal" do
    plsql.test_sum(123.123,456.456).should == BigDecimal("579.579")
  end

  it "should process BigDecimal parameters and return BigDecimal" do
    plsql.test_sum(:p_num1 => BigDecimal("123.123"), :p_num2 => BigDecimal("456.456")).should == BigDecimal("579.579")
  end

  it "should process nil parameter as NULL" do
    plsql.test_sum(123,nil).should be_nil
  end

  it "should convert true value to 1 for NUMBER parameter" do
    plsql.test_number_1(true).should == 'Y'
  end

  it "should convert false value to 0 for NUMBER parameter" do
    plsql.test_number_1(false).should == 'N'
  end

end

describe "Function with date parameters" do
  
  before(:all) do
    plsql.connection = get_connection
    plsql.connection.exec <<-EOS
      CREATE OR REPLACE FUNCTION test_date
        ( p_date DATE )
        RETURN DATE
      IS
      BEGIN
        RETURN p_date + 1;
      END test_date;
    EOS
  end
  
  before(:each) do
    plsql.default_timezone = :local
  end

  after(:all) do
    plsql.logoff
  end
  
  it "should process Time parameters" do
    now = Time.local(2008,8,12,14,28,0)
    plsql.test_date(now).should == now + 60*60*24
  end

  it "should process UTC Time parameters" do
    plsql.default_timezone = :utc
    now = Time.utc(2008,8,12,14,28,0)
    plsql.test_date(now).should == now + 60*60*24
  end

  it "should process DateTime parameters" do
    now = DateTime.parse(Time.local(2008,8,12,14,28,0).iso8601)
    result = plsql.test_date(now)
    result.class.should == Time
    result.should == Time.parse((now + 1).strftime("%c"))
  end
  
  it "should process old DateTime parameters" do
    now = DateTime.civil(1901,1,1,12,0,0,plsql.local_timezone_offset)
    result = plsql.test_date(now)
    result.class.should == Time
    result.should == Time.parse((now + 1).strftime("%c"))
  end

  it "should process Date parameters" do
    now = Date.new(2008,8,12)
    result = plsql.test_date(now)
    result.class.should == Time    
    result.should == Time.parse((now + 1).strftime("%c"))
  end
  
  it "should process old Date parameters" do
    now = Date.new(1901,1,1)
    result = plsql.test_date(now)
    result.class.should == Time
    result.should == Time.parse((now + 1).strftime("%c"))
  end
  
  it "should process nil date parameter as NULL" do
    plsql.test_date(nil).should be_nil
  end

end

describe "Function with timestamp parameters" do
  
  before(:all) do
    plsql.connection = get_connection
    plsql.connection.exec <<-EOS
      CREATE OR REPLACE FUNCTION test_timestamp
        ( p_time TIMESTAMP )
        RETURN TIMESTAMP
      IS
      BEGIN
        RETURN p_time + 1;
      END test_timestamp;
    EOS
  end
  
  after(:all) do
    plsql.logoff
  end
  
  it "should process timestamp parameters" do
    now = Time.local(2008,8,12,14,28,0)
    plsql.test_timestamp(now).should == now + 60*60*24
  end

end

describe "Procedure with output parameters" do
  before(:all) do
    plsql.connection = get_connection
    plsql.connection.exec <<-EOS
      CREATE OR REPLACE PROCEDURE test_copy
        ( p_from VARCHAR2, p_to OUT VARCHAR2, p_to_double OUT VARCHAR2 )
      IS
      BEGIN
        p_to := p_from;
        p_to_double := p_from || p_from;
      END test_copy;
    EOS
  end
  
  after(:all) do
    plsql.logoff
  end
  
  it "should return hash with output parameters" do
    plsql.test_copy("abc", nil, nil).should == { :p_to => "abc", :p_to_double => "abcabc" }
  end

  it "should return hash with output parameters when called with named parameters" do
    plsql.test_copy(:p_from => "abc", :p_to => nil, :p_to_double => nil).should == { :p_to => "abc", :p_to_double => "abcabc" }
  end

  it "should substitute output parameters with nil if they are not specified" do
    plsql.test_copy("abc").should == { :p_to => "abc", :p_to_double => "abcabc" }
  end

  it "should substitute all parementers with nil if none are specified" do
    plsql.test_copy.should == { :p_to => nil, :p_to_double => nil }
  end

end

describe "Package with procedures with same name but different argument lists" do
  before(:all) do
    plsql.connection = get_connection
    plsql.connection.exec <<-EOS
      CREATE OR REPLACE PACKAGE test_package2 IS
        FUNCTION test_procedure ( p_string VARCHAR2 )
          RETURN VARCHAR2;
        PROCEDURE test_procedure ( p_string VARCHAR2, p_result OUT VARCHAR2 )
          ;
        PROCEDURE test_procedure ( p_number NUMBER, p_result OUT VARCHAR2 )
          ;
        FUNCTION test_procedure2 ( p_string VARCHAR2 )
          RETURN VARCHAR2;
      END;
    EOS
    plsql.connection.exec <<-EOS
      CREATE OR REPLACE PACKAGE BODY test_package2 IS
        FUNCTION test_procedure ( p_string VARCHAR2 )
          RETURN VARCHAR2
        IS
        BEGIN
          RETURN UPPER(p_string);
        END test_procedure;
        PROCEDURE test_procedure ( p_string VARCHAR2, p_result OUT VARCHAR2 )
        IS
        BEGIN
          p_result := UPPER(p_string);
        END test_procedure;
        PROCEDURE test_procedure ( p_number NUMBER, p_result OUT VARCHAR2 )
        IS
        BEGIN
          p_result := LOWER(TO_CHAR(p_number));
        END test_procedure;
        FUNCTION test_procedure2 ( p_string VARCHAR2 )
          RETURN VARCHAR2
        IS
        BEGIN
          RETURN UPPER(p_string);
        END test_procedure2;
      END;
    EOS

  end
  
  after(:all) do
    plsql.logoff
  end
    
  it "should find existing package" do
    PLSQL::Package.find(plsql, :test_package2).should_not be_nil
  end

  it "should identify overloaded procedure definition" do
    @procedure = PLSQL::Procedure.find(plsql, :test_procedure, "TEST_PACKAGE2")
    @procedure.should_not be_nil
    @procedure.should be_overloaded
  end

  it "should identify non-overloaded procedure definition" do
    @procedure = PLSQL::Procedure.find(plsql, :test_procedure2, "TEST_PACKAGE2")
    @procedure.should_not be_nil
    @procedure.should_not be_overloaded
  end

  it "should execute correct procedures based on number of arguments and return correct value" do
    plsql.test_package2.test_procedure('xxx').should == 'XXX'
    plsql.test_package2.test_procedure('xxx', nil).should == {:p_result => 'XXX'}
  end

  it "should execute correct procedures based on number of named arguments and return correct value" do
    plsql.test_package2.test_procedure(:p_string => 'xxx').should == 'XXX'
    plsql.test_package2.test_procedure(:p_string => 'xxx', :p_result => nil).should == {:p_result => 'XXX'}
  end

  it "should raise exception if procedure cannot be found based on number of arguments" do
    lambda { plsql.test_package2.test_procedure() }.should raise_error(ArgumentError)
  end
  
  # TODO: should try to implement matching by types of arguments
  # it "should find procedure based on types of arguments" do
  #   plsql.test_package2.test_procedure(111, nil).should == {:p_result => '111'}
  # end

  it "should find procedure based on names of named arguments" do
    plsql.test_package2.test_procedure(:p_number => 111, :p_result => nil).should == {:p_result => '111'}
  end

end

describe "Function with output parameters" do
  before(:all) do
    plsql.connection = get_connection
    plsql.connection.exec <<-EOS
      CREATE OR REPLACE FUNCTION test_copy_function
        ( p_from VARCHAR2, p_to OUT VARCHAR2, p_to_double OUT VARCHAR2 )
        RETURN NUMBER
      IS
      BEGIN
        p_to := p_from;
        p_to_double := p_from || p_from;
        RETURN LENGTH(p_from);
      END test_copy_function;
    EOS
  end
  
  after(:all) do
    plsql.logoff
  end
  
  it "should return array with return value and hash of output parameters" do
    plsql.test_copy_function("abc", nil, nil).should == [3, { :p_to => "abc", :p_to_double => "abcabc" }]
  end

  it "should return array with return value and hash of output parameters when called with named parameters" do
    plsql.test_copy_function(:p_from => "abc", :p_to => nil, :p_to_double => nil).should == 
      [3, { :p_to => "abc", :p_to_double => "abcabc" }]
  end

  it "should substitute output parameters with nil if they are not specified" do
    plsql.test_copy_function("abc").should == [3, { :p_to => "abc", :p_to_double => "abcabc" }]
  end

  it "should substitute all parementers with nil if none are specified" do
    plsql.test_copy_function.should == [nil, { :p_to => nil, :p_to_double => nil }]
  end

end

describe "Function or procedure without parameters" do
  before(:all) do
    plsql.connection = get_connection
    plsql.connection.exec <<-EOS
      CREATE OR REPLACE FUNCTION test_no_params
        RETURN VARCHAR2
      IS
      BEGIN
        RETURN 'dummy';
      END test_no_params;
    EOS
    plsql.connection.exec <<-EOS
      CREATE OR REPLACE PROCEDURE test_proc_no_params
      IS
      BEGIN
        NULL;
      END test_proc_no_params;
    EOS
  end
  
  after(:all) do
    plsql.logoff
  end

  it "should find function" do
    PLSQL::Procedure.find(plsql, :test_no_params).should_not be_nil
  end

  it "should return function value" do
    plsql.test_no_params.should == "dummy"
  end

  it "should find procedure" do
    PLSQL::Procedure.find(plsql, :test_proc_no_params).should_not be_nil
  end

  it "should execute procedure" do
    plsql.test_proc_no_params.should be_nil
  end

end

describe "Function with CLOB parameter and return value" do
  
  before(:all) do
    plsql.connection = get_connection
    plsql.connection.exec <<-EOS
      CREATE OR REPLACE FUNCTION test_clob
        ( p_clob CLOB )
        RETURN CLOB
      IS
      BEGIN
        RETURN p_clob;
      END test_clob;
    EOS
  end
  
  after(:all) do
    plsql.logoff
  end
  
  it "should find existing procedure" do
    PLSQL::Procedure.find(plsql, :test_clob).should_not be_nil
  end

  it "should execute function and return correct value" do
    large_text = 'ābčdēfghij' * 10_000
    plsql.test_clob(large_text).should == large_text
  end

  unless defined?(JRUBY_VERSION)

    it "should execute function with empty string and return nil (oci8 cannot pass empty CLOB parameter)" do
      text = ''
      plsql.test_clob(text).should be_nil
    end
    
  else

    it "should execute function with empty string and return empty string" do
      text = ''
      plsql.test_clob(text).should == text
    end
    
  end

  it "should execute function with nil and return nil" do
    plsql.test_clob(nil).should be_nil
  end

end

describe "Procedrue with CLOB parameter and return value" do
  
  before(:all) do
    plsql.connection = get_connection
    plsql.connection.exec <<-EOS
      CREATE OR REPLACE PROCEDURE test_clob_proc
        ( p_clob CLOB,
          p_return OUT CLOB)
      IS
      BEGIN
        p_return := p_clob;
      END test_clob_proc;
    EOS
  end
  
  after(:all) do
    plsql.logoff
  end
  
  it "should find existing procedure" do
    PLSQL::Procedure.find(plsql, :test_clob_proc).should_not be_nil
  end

  it "should execute function and return correct value" do
    large_text = 'ābčdēfghij' * 10_000
    plsql.test_clob_proc(large_text)[:p_return].should == large_text
  end
end

describe "Procedrue with BLOB parameter and return value" do
  
  before(:all) do
    plsql.connection = get_connection
    plsql.connection.exec <<-EOS
      CREATE OR REPLACE PROCEDURE test_blob_proc
        ( p_blob BLOB,
          p_return OUT BLOB)
      IS
      BEGIN
        p_return := p_blob;
      END test_blob_proc;
    EOS
  end
  
  after(:all) do
    plsql.logoff
  end
  
  it "should find existing procedure" do
    PLSQL::Procedure.find(plsql, :test_blob_proc).should_not be_nil
  end

  it "should execute function and return correct value" do
    large_binary = '\000\001\002\003\004\005\006\007\010\011' * 10_000
    plsql.test_blob_proc(large_binary)[:p_return].should == large_binary
  end
end

describe "Function with record parameter" do

  before(:all) do
    plsql.connection = get_connection
    plsql.connection.exec "DROP TABLE test_employees" rescue nil
    plsql.connection.exec <<-SQL
      CREATE TABLE test_employees (
        employee_id   NUMBER(15),
        first_name    VARCHAR2(50),
        last_name     VARCHAR2(50),
        hire_date     DATE
      )
    SQL
    plsql.connection.exec <<-SQL
      CREATE OR REPLACE FUNCTION test_full_name (p_employee test_employees%ROWTYPE)
        RETURN VARCHAR2
      IS
      BEGIN
        RETURN p_employee.first_name || ' ' || p_employee.last_name;
      END test_full_name;
    SQL
    plsql.connection.exec <<-SQL
      CREATE OR REPLACE FUNCTION test_employee_record (p_employee test_employees%ROWTYPE)
        RETURN test_employees%ROWTYPE
      IS
      BEGIN
        RETURN p_employee;
      END test_employee_record;
    SQL
    plsql.connection.exec <<-SQL
      CREATE OR REPLACE FUNCTION test_employee_record2 (p_employee test_employees%ROWTYPE, x_employee OUT test_employees%ROWTYPE)
        RETURN test_employees%ROWTYPE
      IS
      BEGIN
        x_employee.employee_id := p_employee.employee_id;
        x_employee.first_name := p_employee.first_name;
        x_employee.last_name := p_employee.last_name;
        x_employee.hire_date := p_employee.hire_date;
        RETURN p_employee;
      END test_employee_record2;
    SQL
    @p_employee = {
      :employee_id => 1,
      :first_name => 'First',
      :last_name => 'Last',
      :hire_date => Time.local(2000,01,31)
    }
    @p_employee2 = {
      'employee_id' => 1,
      'FIRST_NAME' => 'Second',
      'last_name' => 'Last',
      'hire_date' => Time.local(2000,01,31)
    }
  end

  after(:all) do
    plsql.connection.exec "DROP FUNCTION test_full_name"
    plsql.connection.exec "DROP FUNCTION test_employee_record"
    plsql.connection.exec "DROP FUNCTION test_employee_record2"
    plsql.connection.exec "DROP TABLE test_employees"
    plsql.logoff
  end

  it "should find existing function" do
    PLSQL::Procedure.find(plsql, :test_full_name).should_not be_nil
  end

  it "should execute function with named parameter and return correct value" do
    plsql.test_full_name(:p_employee => @p_employee).should == 'First Last'
  end

  it "should execute function with sequential parameter and return correct value" do
    plsql.test_full_name(@p_employee).should == 'First Last'
  end

  it "should execute function with Hash parameter using strings as keys" do
    plsql.test_full_name(@p_employee2).should == 'Second Last'
  end

  it "should raise error if wrong field name is passed for record parameter" do
    lambda do
      plsql.test_full_name(@p_employee.merge :xxx => 'xxx').should == 'Second Last'
    end.should raise_error(ArgumentError)
  end

  it "should return record return value" do
    plsql.test_employee_record(@p_employee).should == @p_employee
  end

  it "should return record return value and output record parameter value" do
    plsql.test_employee_record2(@p_employee, nil).should == [@p_employee, {:x_employee => @p_employee}]
  end

end

describe "Function with boolean parameters" do

  before(:all) do
    plsql.connection = get_connection
    plsql.connection.exec <<-SQL
      CREATE OR REPLACE FUNCTION test_boolean
        ( p_boolean BOOLEAN )
        RETURN BOOLEAN
      IS
      BEGIN
        RETURN p_boolean;
      END test_boolean;
    SQL
    plsql.connection.exec <<-SQL
      CREATE OR REPLACE PROCEDURE test_boolean2
          ( p_boolean BOOLEAN, x_boolean OUT BOOLEAN )
      IS
      BEGIN
        x_boolean := p_boolean;
      END test_boolean2;
    SQL
  end

  after(:all) do
    plsql.connection.exec "DROP FUNCTION test_boolean"
    plsql.connection.exec "DROP PROCEDURE test_boolean2"
    plsql.logoff
  end

  it "should accept true value and return true value" do
    plsql.test_boolean(true).should == true
  end

  it "should accept false value and return false value" do
    plsql.test_boolean(false).should == false
  end

  it "should accept nil value and return nil value" do
    plsql.test_boolean(nil).should be_nil
  end

  it "should accept true value and assign true value to output parameter" do
    plsql.test_boolean2(true, nil).should == {:x_boolean => true}
  end

  it "should accept false value and assign false value to output parameter" do
    plsql.test_boolean2(false, nil).should == {:x_boolean => false}
  end

  it "should accept nil value and assign nil value to output parameter" do
    plsql.test_boolean2(nil, nil).should == {:x_boolean => nil}
  end

end

describe "Function with table parameter" do

  before(:all) do
    plsql.connection = get_connection

    # Array of numbers
    plsql.connection.exec <<-SQL
      CREATE OR REPLACE TYPE t_numbers AS TABLE OF NUMBER(15)
    SQL
    plsql.connection.exec <<-SQL
      CREATE OR REPLACE FUNCTION test_sum (p_numbers IN t_numbers)
        RETURN NUMBER
      IS
        l_sum   NUMBER(15) := 0;
      BEGIN
        IF p_numbers.COUNT > 0 THEN
          FOR i IN p_numbers.FIRST..p_numbers.LAST LOOP
            IF p_numbers.EXISTS(i) THEN
              l_sum := l_sum + p_numbers(i);
            END IF;
          END LOOP;
          RETURN l_sum;
        ELSE
          RETURN NULL;
        END IF;
      END;
    SQL

    plsql.connection.exec <<-SQL
      CREATE OR REPLACE FUNCTION test_increment(p_numbers IN t_numbers, p_increment_by IN NUMBER DEFAULT 1)
        RETURN t_numbers
      IS
        l_numbers t_numbers := t_numbers();
      BEGIN
        FOR i IN p_numbers.FIRST..p_numbers.LAST LOOP
          IF p_numbers.EXISTS(i) THEN
            l_numbers.EXTEND;
            l_numbers(i) := p_numbers(i) + p_increment_by;
          END IF;
        END LOOP;
        RETURN l_numbers;
      END;
    SQL

    # Array of strings
    plsql.connection.exec <<-SQL
      CREATE OR REPLACE TYPE t_strings AS TABLE OF VARCHAR2(4000)
    SQL
    plsql.connection.exec <<-SQL
      CREATE OR REPLACE FUNCTION test_copy_strings(p_strings IN t_strings, x_strings OUT t_strings)
        RETURN t_strings
      IS
      BEGIN
        x_strings := t_strings();
        FOR i IN p_strings.FIRST..p_strings.LAST LOOP
          IF p_strings.EXISTS(i) THEN
            x_strings.EXTEND;
            x_strings(i) := p_strings(i);
          END IF;
        END LOOP;
        RETURN x_strings;
      END;
    SQL

    # Wrong type definition inside package
    plsql.connection.exec <<-SQL
      CREATE OR REPLACE PACKAGE test_collections IS
        TYPE t_numbers IS TABLE OF NUMBER(15);
        FUNCTION test_sum (p_numbers IN t_numbers)
          RETURN NUMBER;
      END;
    SQL
    plsql.connection.exec <<-SQL
      CREATE OR REPLACE PACKAGE BODY test_collections IS
        FUNCTION test_sum (p_numbers IN t_numbers)
        RETURN NUMBER
        IS
          l_sum   NUMBER(15) := 0;
        BEGIN
          IF p_numbers.COUNT > 0 THEN
            FOR i IN p_numbers.FIRST..p_numbers.LAST LOOP
              IF p_numbers.EXISTS(i) THEN
                l_sum := l_sum + p_numbers(i);
              END IF;
            END LOOP;
            RETURN l_sum;
          ELSE
            RETURN NULL;
          END IF;
        END;
      END;
    SQL
  end

  after(:all) do
    plsql.connection.exec "DROP FUNCTION test_sum"
    plsql.connection.exec "DROP FUNCTION test_increment"
    plsql.connection.exec "DROP FUNCTION test_copy_strings"
    plsql.connection.exec "DROP PACKAGE test_collections"
    plsql.connection.exec "DROP TYPE t_numbers"
    plsql.connection.exec "DROP TYPE t_strings"
    plsql.logoff
  end

  it "should find existing function" do
    PLSQL::Procedure.find(plsql, :test_sum).should_not be_nil
  end

  it "should execute function with number array parameter" do
    plsql.test_sum([1,2,3,4]).should == 10
  end

  it "should return number array return value" do
    plsql.test_increment([1,2,3,4], 1).should == [2,3,4,5]
  end

  it "should execute function with string array and return string array output parameter" do
    pending "ruby-oci8 gives segmentation fault" if !defined?(RUBY_ENGINE) || RUBY_ENGINE == 'ruby'
    strings = ['1','2','3','4']
    plsql.test_copy_strings(strings).should == [strings, {:x_strings => strings}]
  end

  it "should raise error if parameter type is defined inside package" do
    lambda do
      plsql.test_collections.test_sum([1,2,3,4])
    end.should raise_error(ArgumentError)
  end

end

describe "Synonym to function" do
  
  before(:all) do
    plsql.connection = get_connection
    plsql.connection.exec <<-EOS
      CREATE OR REPLACE FUNCTION hr.test_uppercase
        ( p_string VARCHAR2 )
        RETURN VARCHAR2
      IS
      BEGIN
        RETURN UPPER(p_string);
      END test_uppercase;
    EOS
    plsql.connection.exec "CREATE SYNONYM test_synonym FOR hr.test_uppercase"
  end
  
  after(:all) do
    plsql.connection.exec "DROP SYNONYM test_synonym" rescue nil
    plsql.logoff
  end
  
  it "should find synonym to function" do
    PLSQL::Procedure.find(plsql, :test_synonym).should_not be_nil
  end

  it "should execute function using synonym and return correct value" do
    plsql.test_synonym('xxx').should == 'XXX'
  end

end

describe "Public synonym to function" do
  
  before(:all) do
    plsql.connection = get_connection
    plsql.connection.exec <<-EOS
      CREATE OR REPLACE FUNCTION hr.test_ora_login_user
        RETURN VARCHAR2
      IS
      BEGIN
        RETURN 'XXX';
      END test_ora_login_user;
    EOS
  end
  
  after(:all) do
    plsql.logoff
  end
  
  it "should find public synonym to function" do
    PLSQL::Procedure.find(plsql, :ora_login_user).should_not be_nil
  end

  it "should execute function using public synonym and return correct value" do
    plsql.ora_login_user.should == 'HR'
  end

  it "should find private synonym before public synonym" do
    # should reconnect to force clearing of procedure cache
    plsql.connection = get_connection
    plsql.connection.exec "CREATE SYNONYM ora_login_user FOR hr.test_ora_login_user"
    plsql.ora_login_user.should == 'XXX'
    plsql.connection.exec "DROP SYNONYM ora_login_user"
    plsql.connection = get_connection
    plsql.ora_login_user.should == 'HR'
  end

end
