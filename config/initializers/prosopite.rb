if defined?(Prosopite) && !Rails.env.production?
  require "prosopite/middleware/rack"
  Rails.configuration.middleware.use(Prosopite::Middleware::Rack)

  Prosopite.enabled = true
  Prosopite.custom_logger = ActiveSupport::Logger.new("log/#{Rails.env}_prosopite.log")
end
