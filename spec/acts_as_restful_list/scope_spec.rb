RSpec.describe 'declaring acts_as_restful_list and setting the scope' do
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
      acts_as_restful_list :scope => :parent_id
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

  it 'should return a scope limiting based parent_id being NULL if parent_id is nil' do
    Mixin.new.scope_condition.should == "parent_id IS NULL"
  end

  it 'should set the position based on the scope list when adding a new item' do
    Mixin.create!.position.should == 1
    Mixin.create!(:parent_id => 1).position.should == 1
    Mixin.create!(:parent_id => 1).position.should == 2
    Mixin.create!(:parent_id => 2).position.should == 1
  end

  describe 'reordering on update' do
    before(:each) do
      (1..4).each{ Mixin.create!(:parent_id => 1) }
      (1..6).each{ Mixin.create!(:parent_id => 2) }
    end

    it 'should automatically reorder the list if a record is updated with a lower position' do
      fourth_mixin = Mixin.find_by(:position => 4, :parent_id => 1)
      fourth_mixin.position = 2
      fourth_mixin.save!
      fourth_mixin.reload.position.should == 2
      Mixin.where(:parent_id => 1).order('position ASC').collect(&:position).should == [1,2,3,4]
      Mixin.where(:parent_id => 2).order('position ASC').collect(&:position).should == [1,2,3,4,5,6]
    end

    it 'should automatically reorder the list if a record is updated with a higher position' do
      second_mixin = Mixin.find_by(:position => 2, :parent_id => 1)
      second_mixin.position = 4
      second_mixin.save!
      second_mixin.reload.position.should == 4
      Mixin.where(:parent_id => 1).order('position ASC').collect(&:position).should == [1,2,3,4]
      Mixin.where(:parent_id => 2).order('position ASC').collect(&:position).should == [1,2,3,4,5,6]
    end

    it 'should report the old and new scope correctly' do
      second_mixin = Mixin.find_by(:position => 2, :parent_id => 1)
      second_mixin.parent_id = 2
      second_mixin.position = 4
      second_mixin.save!
      second_mixin.scope_condition_was.should == 'parent_id = 1'
      second_mixin.scope_condition.should == 'parent_id = 2'
    end

    it 'should automatically reorder both lists if a record is moved between them' do
      second_mixin = Mixin.find_by(:position => 2, :parent_id => 1)
      second_mixin.parent_id = 2
      second_mixin.position = 4
      second_mixin.save!
      second_mixin.reload.parent_id.should == 2
      second_mixin.reload.position.should == 4
      Mixin.where(:parent_id => 1).order('position ASC').collect(&:position).should == [1,2,3]
      Mixin.where(:parent_id => 2).order('position ASC').collect(&:position).should == [1,2,3,4,5,6,7]
    end
  end

  it 'should automatically reorder the list scoped by parent if the record is deleted' do
    (1..4).each{ Mixin.create!(:parent_id => 1) }
    (1..6).each{ Mixin.create!(:parent_id => 2) }
    second_mixin = Mixin.find_by(:position => 2, :parent_id => 1)
    second_mixin.destroy
    Mixin.where(:parent_id => 1).order('position ASC').collect(&:position).should == [1,2,3]
    Mixin.where(:parent_id => 2).order('position ASC').collect(&:position).should == [1,2,3,4,5,6]
  end
end
