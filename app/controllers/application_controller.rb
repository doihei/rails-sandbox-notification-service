class ApplicationController < ActionController::API
  private

  def authenticate_service!
    token = request.headers["Authorization"]&.delete_prefix("Bearer ")
    unless token == ENV.fetch("INTER_SERVICE_SECRET", "dev-secret")
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end
