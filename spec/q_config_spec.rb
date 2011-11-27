require File.expand_path(File.dirname(__FILE__) + "/spec_helper")

describe "QConfig" do
  it "should parse a basic config" do
    c = QConfig.new { v1 "abc" }
    c.v1.should == "abc"
  end
  
  it "should parse a namespaced config" do
    c = QConfig.new do
      namespace :thing do
        a 1
        b "2"
        c 3.0
      end
    end
    
    c.thing.a.should == 1
    c.thing.b.should == "2"
    c.thing.c.should == 3.0
    
    c.thing.to_hash.should == {
      "a" => 1,
      "b" => "2",
      "c" => 3.0
    }
    
    c.thing.to_hash.should be_instance_of(ActiveSupport::HashWithIndifferentAccess)
  end
  
  it "should be able to access sibling settings" do
    c = QConfig.new do
      v1 1
      v2 v1 + 2
    end
    
    c.v1.should == 1
    c.v2.should == 3
  end
  
  it "should update a namespace with a subsequent parse" do
    c = QConfig.new do
      namespace :thing do
        a 1
      end
    end
    
    c.thing.a.should == 1
    
    c.instance_eval do
      namespace :thing do
        b 3
      end
    end
    
    c.thing.a.should == 1
    c.thing.b.should == 3
  end
  
  it "should allow new instance methods to access settings" do
    c = QConfig.new do
      number 44
      
      def modulus(x)
        number % x
      end
    end
    
    c.modulus(5).should == 4
  end
  
  it "should parse a big config file" do
    c = QConfig.new do
      source "spec/fixtures/big_config.rb"
    end
    
    c.one.should == "1"
    
    c.ns1.username.should == "neil"
    c.ns1.password.should == "armstrong"
    c.ns1.to_hash.should == { "username" => "neil", "password" => "armstrong" }
    
    Time.stub!(:now => Time.now)
    c.sale_ends_at.should == Time.now + 10.seconds
    
    c.ftp_account.login.email.should == "email@email.com"
    c.ftp_account.login.password.should == "pa55w0rd"
    c.ftp_account.port.should == 21
    c.ftp_account.ssl.should == false
  end
  
  it "should cache using the :expires_in option" do
    c = QConfig.new do
      source "spec/fixtures/big_config.rb"
    end
    
    now = Time.now
    original_object = c.sale_ends_at
    
    # Cached
    c.sale_ends_at.object_id.should == original_object.object_id
    c.sale_ends_at.object_id.should == original_object.object_id
    
    # Still cached
    Time.stub!(:current => now + 2.seconds)
    c.sale_ends_at.object_id.should == original_object.object_id
    
    # Expired
    Time.stub!(:current => now + 4.seconds)
    c.sale_ends_at.should == Time.current + 10.seconds
    c.sale_ends_at.object_id.should_not == original_object.object_id
  end
  
  it "should dup values that can be dup'ed" do
    c = QConfig.new { v1 "abc" }
    
    c.v1.should == "abc"
    c.v1 << "def"
    c.v1.should == "abc"
    
    c.v1.object_id.should_not == c.v1.object_id
  end
  
  it "should return #to_hash on #inspect" do
    c = QConfig.new { v1 "abc" }
    c.inspect.should == c.to_hash.inspect
  end
  
  it "should return #value on Setting#inspect" do
    c = QConfig.new { v1 "abc" }
    c.v1.inspect.should == "abc".inspect
  end
  
  it "should work with a key that used to be a private method (#test)" do
    c = QConfig.new { test false }
    c.test.should == false
  end
  
  it "should reload the sources when #reset is called" do
    c = QConfig.new { source "spec/fixtures/big_config.rb" }
    time1 = c.time
    
    c.reset
    time2 = c.time
    
    time2.should > time1
  end
  
  it "should have #include?" do
    c = QConfig.new do
      v3 99
      
      namespace :ns2 do
        v9 1
      end
    end
    
    c.include?(:v3).should == true
    c.include?("v3").should == true
    
    c.include?(:ns2).should == true
    c.include?("ns2").should == true
    
    c.ns2.include?(:v9).should == true
  end
  
  it "should not treat a value hash as options" do
    c = QConfig.new { v1 Hash.new }
    c.v1.should == {}
  end
  
  it "should raise an error when a key does not exist" do
    c = QConfig.new { v1 3 }
    lambda { 
      c.v2
    }.should raise_error(ArgumentError)
  end
end
