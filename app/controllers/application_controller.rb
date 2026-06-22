class ApplicationController < ActionController::API
  private

  def authenticate_service!
    token = request.headers["Authorization"]&.delete_prefix("Bearer ")
    unless ActiveSupport::SecurityUtils.secure_compare(token.to_s, ENV.fetch("INTER_SERVICE_SECRET"))
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end
