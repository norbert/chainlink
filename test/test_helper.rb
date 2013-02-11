require 'chainlink'

require 'test/unit'
require 'mocha/setup'
require 'database_cleaner'
require 'logger'

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.logger.level = Logger::UNKNOWN

case ENV['ADAPTER'] || 'sqlite3'
when 'sqlite3'
  ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
when 'mysql2'
  ActiveRecord::Base.establish_connection(adapter: 'mysql2', database: 'forward_path_test')
when 'postgresql'
  ActiveRecord::Base.establish_connection(adapter: 'postgresql', database: 'forward_path_test')
end

ActiveRecord::Schema.define(:version => 1) do
  create_table :artists, force: true do |t|
    t.string :name
    t.boolean :imported
    t.integer :merge_target_id
  end

  create_table :records, force: true do |t|
    t.integer :artist_id
    t.string :title
    t.integer :merge_target_id
  end
end

module ChainLinkTestHelper
  extend ActiveSupport::Concern

  DatabaseCleaner[:active_record].strategy = :transaction

  included do
    setup do
      DatabaseCleaner.start
    end

    teardown do
      DatabaseCleaner.clean
    end
  end
end

class Artist < ActiveRecord::Base
  include ChainLink
  has_many :records
end

class Record < ActiveRecord::Base
  include ChainLink
  belongs_to :artist
end
