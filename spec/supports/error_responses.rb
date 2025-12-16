module ErrorResponseHelper
  def rails_responds_without_detailed_exceptions
    env_config = Rails.application.env_config

    original_show_exceptions = env_config["action_dispatch.show_exceptions"]
    original_show_detailed_exceptions = env_config["action_dispatch.show_detailed_exceptions"]

    # don't let exception bubbles up to test framework and let rails handles it
    env_config["action_dispatch.show_exceptions"] = true

    # make sure rails handles exception by showing the actual error page instead of showing
    # the detailed debug page
    env_config["action_dispatch.show_detailed_exceptions"] = false

    yield
  ensure
    env_config["action_dispatch.show_exceptions"] = original_show_exceptions
    env_config["action_dispatch.show_detailed_exceptions"] = original_show_detailed_exceptions
  end
end
