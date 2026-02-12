require_relative "production"

Rails.application.configure do
  # You can put any override here
  config.force_ssl = false

  config.lograge.enabled = true
  config.lograge.keep_original_rails_log = false
  config.lograge.logger = ActiveSupport::Logger.new "log/experiment_lograge.log"
  config.lograge.formatter = Lograge::Formatters::Json.new

  config.lograge.custom_options = lambda do |event|
    {
      time: Time.current,
      exception: event.payload[:exception] # ["ExceptionClass", "the message"]
    }
  end
end
