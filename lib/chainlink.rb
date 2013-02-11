require 'active_record'

module ChainLink
  extend ActiveSupport::Concern

  class DirectionError < StandardError
  end

  MERGE_TARGET_KEY = :merge_target_id
  JOIN_TABLE_PREFIX = :merge_target_

  included do
    has_many :merge_sources, class_name: self.name, foreign_key: MERGE_TARGET_KEY

    scope :merge_targets, lambda {
      where(MERGE_TARGET_KEY => nil)
    }
    scope :merge_sources, lambda {
      where("#{table_name}.#{MERGE_TARGET_KEY} IS NOT NULL")
    }

    class_attribute :merge_target_associations
    self.merge_target_associations = []
  end

  module ClassMethods
    def find_merge_target(*args)
      as_merge_targets.find(*args)
    end

    def as_merge_targets
      joins(merge_target_join_clause).select(merge_target_select_clause)
    end

    def merge!(target, source)
      target.merge!(source)
    end

    private
    def merge_target_join_clause
      table_name = quoted_table_name
      join_table_name = connection.quote_table_name(merge_target_join_table_name)

      primary_key = quoted_primary_key
      foreign_key = connection.quote_column_name(MERGE_TARGET_KEY.to_s)

      equivalence_clause = merge_target_equivalence_clause(
        "#{table_name}.#{foreign_key}", "#{table_name}.#{primary_key}"
      )

      "INNER JOIN #{table_name} AS #{join_table_name} ON #{join_table_name}.#{primary_key} = #{equivalence_clause}"
    end

    def merge_target_select_clause
      "#{connection.quote_table_name(merge_target_join_table_name)}.*"
    end

    def merge_target_equivalence_clause(foreign_key, primary_key)
      "COALESCE(#{foreign_key}, #{primary_key})"
    end

    def merge_target_join_table_name
      "#{JOIN_TABLE_PREFIX}#{table_name}"
    end
  end

  def merge!(source)
    raise DirectionError, "source is not mergeable" unless source.mergeable?
    raise DirectionError, "target is not mergeable" unless mergeable?(:target)

    self.class.transaction do
      yield if block_given?
      source[MERGE_TARGET_KEY] ||= id
      source.save!
      save!
    end

    self
  end

  def merge_associations!(source, *associations)
    Array(associations).each do |association_name|
      reflection = self.class.reflect_on_association(association_name)
      case reflection.macro
      when :has_many
        foreign_key = reflection.foreign_key
        reflection.klass.where(foreign_key => source.id).update_all(foreign_key => id)
      end
    end
  end

  def merge_target
    if !merged?
      self
    elsif target_record = self.class.find_by_id(merge_target_id)
      target_record.merge_target
    end
  end

  def merged?
    merge_target_id.present?
  end

  def mergeable?(as = :source)
    case as
    when :source
      !merged? && !merge_sources.exists?
    when :target
      !merged?
    else
      raise ArgumentError, "unknown merge role"
    end
  end

  def merge_target_id
    read_attribute(MERGE_TARGET_KEY)
  end
end
