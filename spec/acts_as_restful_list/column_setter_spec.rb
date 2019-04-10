require_relative "../spec_helper"

RSpec.describe 'declaring acts_as_restful_list and setting the column' do
  after(:each) do
    ActiveRecord::Base.connection.execute("DELETE FROM mixins")
    ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence where name='mixins'")
  end

  before(:all) do
    ActiveRecord::Schema.define(:version => 1) do
      create_table :mixins do |t|
        t.column :pos, :integer
        t.column :parent_id, :integer
        t.column :created_at, :datetime
        t.column :updated_at, :datetime
      end
    end

    class Mixin < ActiveRecord::Base
      acts_as_restful_list column: :pos
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

  it "should return pos as it's position column" do
    Mixin.new.position_column.should == 'pos'
  end

  it 'should set the position before creating the record' do
    mixin = Mixin.new
    mixin.should_receive(:set_position).and_return(true)
    mixin.save!
  end

  it 'should save the first record with position 1' do
    Mixin.create!.pos.should == 1
  end

  it 'should put each new record at the end of the list' do
    (1..4).each do |n|
      Mixin.create!.pos.should == n
    end
  end

  describe 'reordering on update' do
    before(:each) do
      (1..4).each{ Mixin.create! }
    end

    it 'should reset order after updating a record' do
      mixin = Mixin.create
      mixin.should_receive(:reset_order_after_update).and_return(true)
      mixin.save!
    end

    it 'should automatically reorder the list if a record is updated with a lower position' do
      fourth_mixin = Mixin.find_by(:pos => 4)
      fourth_mixin.pos = 2
      fourth_mixin.save!
      fourth_mixin.reload.pos.should == 2
      Mixin.order('pos ASC').collect(&:pos).should == [1,2,3,4]
    end

    it 'should automatically reorder the list if a record is updated with a higher position' do
      second_mixin = Mixin.find_by(:pos => 2)
      second_mixin.pos = 4
      second_mixin.save!
      second_mixin.reload.pos.should == 4
      Mixin.order('pos ASC').collect(&:pos).should == [1,2,3,4]
    end
  end

  describe 'reordering on deletion' do
    it 'should reset the order after deleting a record' do
      mixin = Mixin.create
      mixin.should_receive(:reset_order_after_destroy).and_return(true)
      mixin.destroy
    end

    it 'should automatically reorder the list if the record is deleted' do
      (1..4).each{ Mixin.create! }
      second_mixin = Mixin.find_by(:pos => 2)
      second_mixin.destroy
      Mixin.order('pos ASC').collect(&:pos).should == [1,2,3]
    end
  end
end
