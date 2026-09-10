module QueryCounter
  IGNORED_NAMES = [ "SCHEMA", "TRANSACTION" ].freeze

  # Counts the real SQL queries fired while the block runs, ignoring schema
  # introspection and transaction bookkeeping.
  def count_queries
    count = 0

    counter = lambda do |_name, _started, _finished, _id, payload|
      next if IGNORED_NAMES.include?(payload[:name])
      next if payload[:sql].start_with?("PRAGMA")

      count += 1
    end

    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { yield }

    count
  end
end

RSpec.configure do |config|
  config.include QueryCounter
end
