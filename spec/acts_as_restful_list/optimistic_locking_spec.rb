require_relative "../spec_helper"

RSpec.describe 'optimistic locking' do
  after(:each) do
    ActiveRecord::Base.connection.execute("DELETE FROM mixins")
    ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence where name='mixins'")
  end

  before(:all) do
    ActiveRecord::Schema.define(:version => 1) do
      create_table :mixins do |t|
        t.column :position, :integer
        t.column :parent_id, :integer
        t.column :lock_version, :integer, :default => 0
        t.column :created_at, :datetime
        t.column :updated_at, :datetime
      end
    end

    class Mixin < ActiveRecord::Base
      acts_as_restful_list
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

  before(:each) do
    (1..4).each{ Mixin.create! }
  end

  describe 'reordering on destroy' do
    it 'should raise an error for stale objects' do
      second_mixin = Mixin.find_by(:position => 2)
      third_mixin  = Mixin.find_by(:position => 3)
      second_mixin.destroy
      lambda {
        third_mixin.destroy
      }.should raise_error(ActiveRecord::StaleObjectError)
    end

    it 'should NOT raise an error if update did not affect existing position' do
      second_mixin = Mixin.find_by(:position => 2)
      third_mixin  = Mixin.find_by(:position => 3)
      third_mixin.destroy
      lambda {
        second_mixin.destroy
      }.should_not raise_error
      Mixin.order('position ASC').collect(&:position).should == [1,2]
    end
  end

  describe 'reordering on update' do
    it 'should raise an error for stale objects' do
      first_mixin  = Mixin.find_by(:position => 1)
      fourth_mixin = Mixin.find_by(:position => 4)
      fourth_mixin.update_attributes(:position => 1)
      lambda {
        first_mixin.update_attributes(:position => 2)
      }.should raise_error(ActiveRecord::StaleObjectError)
    end

    it 'should NOT raise an error if update did not affect existing position' do
      first_mixin  = Mixin.find_by(:position => 1)
      fourth_mixin = Mixin.find_by(:position => 4)
      fourth_mixin.update_attributes(:position => 2)
      lambda {
        first_mixin.update_attributes(:position => 3)
      }.should_not raise_error
      Mixin.order('position ASC').collect(&:position).should == [1,2,3,4]
    end
  end

end
