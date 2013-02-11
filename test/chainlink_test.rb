require 'test_helper'

class ChainLinkTest < ActiveSupport::TestCase
  include ChainLinkTestHelper

  setup do
    @target = Artist.create!(name: 'Burial')
    @source = Artist.create!(name: 'Burial', imported: true)
  end

  test "should merge record instances" do
    @source.records.create!(title: 'Distant Lights')

    assert @target.mergeable?
    assert @target.mergeable?(:target)
    assert @source.mergeable?
    assert @source.mergeable?(:target)

    assert_no_difference '@target.records.count' do
      assert_equal @target, @target.merge!(@source)
    end
    assert_equal @target.id, @source.merge_target_id

    assert @source.merged?
    assert !@target.mergeable?
    assert @target.mergeable?(:target)
    assert !@source.mergeable?
    assert !@source.mergeable?(:target)
  end

  test "should not merge instances with existing sources or targets" do
    @target.merge!(@source)
    @duplicate = Artist.create!(name: 'burial')

    assert_raise ChainLink::DirectionError do
      @duplicate.merge!(@source)
    end
    assert_raise ChainLink::DirectionError do
      @duplicate.merge!(@target)
    end
    assert_raise ChainLink::DirectionError do
      @source.merge!(@duplicate)
    end

    assert @target.merge!(@duplicate)
  end

  test "should find merge targets" do
    @target.merge!(@source)
    assert_equal @target, Artist.find_merge_target(@source)
  end

  test "should list merge sources and targets" do
    @target.merge!(@source)
    assert_equal [@target], Artist.merge_targets
    assert_equal [@source], Artist.merge_sources
  end

  test "should resolve merge targets" do
    @duplicate = Artist.create!(name: 'burial')
    @target.merge!(@source)
    @target.merge!(@duplicate)
    assert_equal [@target, @target], Artist.as_merge_targets.where(id: [@source, @duplicate]).all
    assert_equal @target, @source.merge_target
  end

  test "should yield during merge" do
    # useful for temporary scripts and subclassing
    @target.merge!(@source) do
      @target.imported = @source.imported
    end

    assert @target.imported?
  end

  test "should merge collection associations" do
    @target.records.create!(title: 'Ghost Hardware')
    @source.records.create!(title: 'South London Borougs')
    @source.records.create!(title: 'Distant Lights')

    assert_difference '@target.records.count', 2 do
      # this should not be a side effect of subclassing either
      assert_no_difference 'Record.count' do
        @target.merge_target_associations = [:records]
        @target.merge_associations!(@source, :records)
      end
    end

    assert_blank Artist.merge_target_associations

    assert_equal Record.all, @target.records
  end

  test "should not merge singular associations" do
    @associated_target = @target.records.create!(title: 'Ghost Hardware')
    @associated_source = @source.records.create!(title: 'Kindred')

    # reflects on merge_sources
    assert @associated_source.mergeable?

    # check fragile state of implementation
    reflection = mock('reflection', macro: :belongs_to)
    reflection.expects(:foreign_key).never
    Record.expects(:reflect_on_association).with(:artist).returns(reflection)

    @associated_target.merge_target_associations = [:artist]
    @associated_target.merge_associations!(@associated_source, :artist)
  end

  test "should find merge targets recursively on instances" do
    @target.merge!(@source)
    @duplicate = Artist.create!(name: 'Burial', merge_target_id: @source.id)
    assert_equal @target, @duplicate.merge_target
  end
end
