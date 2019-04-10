require_relative "../spec_helper"

RSpec.describe 'declaring acts_as_restful_list and setting the scope without the _id' do
  after(:each) do
    ActiveRecord::Base.connection.execute("DELETE FROM mixins")
    ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence where name='mixins'")
  end

  before(:all) do
    ActiveRecord::Schema.define(:version => 1) do
      create_table :mixins do |t|
        t.column :position, :integer
        t.column :parent_id, :integer
        t.column :created_at, :datetime
        t.column :updated_at, :datetime
      end
    end

    class Mixin < ActiveRecord::Base
      acts_as_restful_list :scope => :parent
    end

    ActiveRecord::Base.connection.schema_cache.clear!
    Mixin.reset_column_information
  end

  after(:all) do
    Object.send(:remove_const, :Mixin)

    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table)
    end
  end

  it 'should define scope_condition as an instance method' do
    Mixin.new.should respond_to(:scope_condition)
  end

  it 'should return a scope condition that limits based on the parent_id' do
    Mixin.new(:parent_id => 3).scope_condition.should == "parent_id = 3"
  end
end