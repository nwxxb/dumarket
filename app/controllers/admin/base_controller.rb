class Admin::BaseController < ApplicationController
  layout "admin"

  before_action :check_admin
  def check_admin
    if !current_user&.is_admin?
      raise ActionController::RoutingError, "Not Found"
    end
  end
end
