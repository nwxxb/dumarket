require_relative "production"

Rails.application.configure do
  # You can put any override here
  config.active_record.verbose_query_logs = true

  config.logger = ActiveSupport::Logger.new("log/experiment.log")
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "debug")
  config.force_ssl = false
end
