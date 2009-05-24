require File.join(File.dirname(__FILE__), 'spec_helper')
if HAS_SQLITE3 || HAS_MYSQL || HAS_POSTGRES # has database type

class User
  include DataMapper::Resource
  property :id, Serial
  property :name, String
  property :admin, Boolean, :default => false

  has n, :memberships
  has n, :groups, :through => :memberships
end

class Group
  include DataMapper::Resource
  property :id, Serial
  property :name, String
end

class Membership
  include DataMapper::Resource
  property :id, Serial
  property :user_id, Integer
  belongs_to :user
  property :group_id, Integer
  belongs_to :group
end

class Document
  include DataMapper::Resource
  property :id, Serial
  property :name, String

  property :user_id, Integer
  belongs_to :user

  property :group_id, Integer
  belongs_to :group
end

class Permission
  include DataMapper::Resource
  property :id, Serial
  property :user_id, Integer
  belongs_to :user
  property :document_id, Integer
  belongs_to :document
end

describe "filters" do

  before(:all) do
    User.auto_migrate!
    Group.auto_migrate!
    Membership.auto_migrate!
    Document.auto_migrate!
    Permission.auto_migrate!

    @admin = User.create(:name => 'admin', :admin => true)
    @dhh = User.create(:name => 'dhh')
    @zed = User.create(:name => 'zed')
    @foy = User.create(:name => 'foy')

    @ruby = Group.create(:name => 'ruby')
    @pyth = Group.create(:name => 'pyth')
    @poly = Group.create(:name => 'poly')

    Membership.create(:user => @zed, :group => @pyth) 
    Membership.create(:user => @dhh, :group => @ruby)
    Membership.create(:user => @foy, :group => @ruby)
    Membership.create(:user => @foy, :group => @poly)

    @rails = Document.create(:name => 'rails', :group => @ruby, :user => @dhh)
    @crack = Document.create(:name => 'crack', :group => @poly, :user => @foy)

    Permission.create(:document => @crack, :user => @zed)
  end

  it "should allow provide a class method has_filter" do
    User.should respond_to(:has_filter)
  end

  it "should be able to halt with return value" do
    class User
      has_filter :role

      def self.role_filter(query, filter)
        throw :halt, {} if filter && filter.admin == false
        query
      end
    end

    User.all(:role => @foy).should == {}
    User.all(:role => @admin).size.should == 4
  end

  it "should be able to shape incoming query based on filter values" do
    class Document
      has_filter :role

      def self.role_filter(query, filter)
        user = filter
        user_id = user.id
        group_ids = user.groups.collect {|g| g.id}
        doc_ids = Permission.all(:user_id => user_id).collect {|p| p.document_id}
        query.merge({ :conditions => ["group_id IN ? OR user_id = ? OR id IN ?", group_ids, user_id, doc_ids] })
      end
    end

    Document.all(:role => @dhh).size.should == 1 # Rails
    Document.all(:role => @zed).size.should == 1 # Crack
    Document.all(:role => @foy).size.should == 2 # Rails and Crack
  end
end


end # has database type
