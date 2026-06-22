module Api
  module V1
    class NotificationsController < ApplicationController
      before_action :authenticate_service!

      # POST /api/v1/notifications
      def create
        result = Notifications::CreateService.call(
          article_id: params[:article_id],
          message: params[:message],
          user_id: params[:user_id]
        )

        if result.success
          render json: { notification: result.value.as_json }, status: :created
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/notifications
      def index
        notifications = Notification.for_user(params[:user_id]).unread
        render json: { notifications: notifications.as_json }
      end
    end
  end
end
