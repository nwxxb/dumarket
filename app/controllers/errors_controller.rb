class ErrorsController < ApplicationController
  ADDRESSED_ERROR_CODE = [ "404", "422", "500" ]

  def show
    code = /#{ADDRESSED_ERROR_CODE.join("|")}/.match(request.path)[0]
    layout = /\A\/admin(\/|\z)/.match?(request.original_fullpath) && current_user&.is_admin? ? "admin" : "application"
    @http_code = ADDRESSED_ERROR_CODE.include?(code) ? code.to_i : 500
    render :show, status: @http_code, layout: layout
  end
end
