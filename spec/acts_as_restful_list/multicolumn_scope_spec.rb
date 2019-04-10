require_relative "../spec_helper"

RSpec.describe 'declaring acts_as_restful_list and setting the scope to multiple columns' do
  after(:each) do
    ActiveRecord::Base.connection.execute("DELETE FROM dummies")
    ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence where name='dummies'")
  end

  before(:all) do
    ActiveRecord::Schema.define(:version => 1) do
      create_table :dummies do |t|
        t.column :position, :integer
        t.column :user_id, :integer
        t.column :parent_id, :integer
        t.column :created_at, :datetime
        t.column :updated_at, :datetime
      end
    end

    class Dummy < ActiveRecord::Base
      acts_as_restful_list :scope => [:parent, :user]
    end

    ActiveRecord::Base.connection.schema_cache.clear!
    Dummy.reset_column_information
  end

  after(:all) do
    Object.send(:remove_const, :Dummy)

    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table)
    end
  end

  it 'should define scope_condition as an instance method' do
    Dummy.new.should respond_to(:scope_condition)
  end

  it 'should return a scope condition that limits based on the parent_id' do
    Dummy.new(:user_id => 4, :parent_id => 3).scope_condition.should == "parent_id = 3 AND user_id = 4"
  end

  describe 'reordering on update' do
    before(:each) do
      (1..4).each{ Dummy.create!(:parent_id => 1, :user_id => 5) }
      (1..4).each{ Dummy.create!(:parent_id => 2, :user_id => 5) }
      (1..4).each{ Dummy.create!(:parent_id => 1, :user_id => 7) }
      (1..4).each{ Dummy.create!(:parent_id => 2, :user_id => 7) }
    end

    it 'should automatically reorder the list if a record is updated with a lower position' do
      user5_parent1_fourth_mixin = Dummy.find_by(:position => 4, :parent_id => 1, :user_id => 5)
      user5_parent1_fourth_mixin.position = 2
      user5_parent1_fourth_mixin.save!
      user5_parent1_fourth_mixin.reload.position.should == 2
      Dummy.where(:parent_id => 1, :user_id => 5).order('position ASC').collect(&:position).should == [1,2,3,4]
      Dummy.where(:parent_id => 1, :user_id => 5).order('position ASC').collect(&:id).should == [1,4,2,3]
      Dummy.where(:parent_id => 2, :user_id => 5).order('position ASC').collect(&:position).should == [1,2,3,4]
      Dummy.where(:parent_id => 2, :user_id => 5).order('position ASC').collect(&:id).should == [5,6,7,8]
      Dummy.where(:parent_id => 1, :user_id => 7).order('position ASC').collect(&:position).should == [1,2,3,4]
      Dummy.where(:parent_id => 1, :user_id => 7).order('position ASC').collect(&:id).should == [9,10,11,12]
      Dummy.where(:parent_id => 2, :user_id => 7).order('position ASC').collect(&:position).should == [1,2,3,4]
      Dummy.where(:parent_id => 2, :user_id => 7).order('position ASC').collect(&:id).should == [13,14,15,16]
    end

    it 'should automatically reorder the list if a record is updated with a higher position' do
      second_mixin = Dummy.find_by(:position => 2, :parent_id => 1, :user_id => 5)
      second_mixin.position = 4
      second_mixin.save!
      second_mixin.reload.position.should == 4
      Dummy.where(:parent_id => 1, :user_id => 5).order('position ASC').collect(&:position).should == [1,2,3,4]
      Dummy.where(:parent_id => 1, :user_id => 5).order('position ASC').collect(&:id).should == [1,3,4,2]
      Dummy.where(:parent_id => 2, :user_id => 5).order('position ASC').collect(&:position).should == [1,2,3,4]
      Dummy.where(:parent_id => 2, :user_id => 5).order('position ASC').collect(&:id).should == [5,6,7,8]
      Dummy.where(:parent_id => 1, :user_id => 7).order('position ASC').collect(&:position).should == [1,2,3,4]
      Dummy.where(:parent_id => 1, :user_id => 7).order('position ASC').collect(&:id).should == [9,10,11,12]
      Dummy.where(:parent_id => 2, :user_id => 7).order('position ASC').collect(&:position).should == [1,2,3,4]
      Dummy.where(:parent_id => 2, :user_id => 7).order('position ASC').collect(&:id).should == [13,14,15,16]
    end
  end

  it 'should automatically reorder if the record is deleted' do
    (1..4).each{ Dummy.create!(:parent_id => 1, :user_id => 5) }
    (1..4).each{ Dummy.create!(:parent_id => 2, :user_id => 5) }
    (1..4).each{ Dummy.create!(:parent_id => 1, :user_id => 7) }
    (1..4).each{ Dummy.create!(:parent_id => 2, :user_id => 7) }
    second_mixin = Dummy.find_by(:position => 2, :parent_id => 1, :user_id => 5)
    second_mixin.destroy
    Dummy.where(:parent_id => 1, :user_id => 5).order('position ASC').collect(&:position).should == [1,2,3]
    Dummy.where(:parent_id => 1, :user_id => 5).order('position ASC').collect(&:id).should == [1,3,4]
    Dummy.where(:parent_id => 2, :user_id => 5).order('position ASC').collect(&:position).should == [1,2,3,4]
    Dummy.where(:parent_id => 2, :user_id => 5).order('position ASC').collect(&:id).should == [5,6,7,8]
    Dummy.where(:parent_id => 1, :user_id => 7).order('position ASC').collect(&:position).should == [1,2,3,4]
    Dummy.where(:parent_id => 1, :user_id => 7).order('position ASC').collect(&:id).should == [9,10,11,12]
    Dummy.where(:parent_id => 2, :user_id => 7).order('position ASC').collect(&:position).should == [1,2,3,4]
    Dummy.where(:parent_id => 2, :user_id => 7).order('position ASC').collect(&:id).should == [13,14,15,16]
  end
end