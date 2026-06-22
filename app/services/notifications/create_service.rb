module Notifications
  class CreateService
    Result = Data.define(:success, :value, :error)

    def self.call(article_id:, message:, user_id:)
      new(article_id: article_id, message: message, user_id: user_id).call
    end

    def initialize(article_id:, message:, user_id:)
      @article_id = article_id
      @message = message
      @user_id = user_id
    end

    def call
      notification = Notification.new(
        article_id: @article_id,
        message: @message,
        user_id: @user_id
      )

      if notification.save
        Result.new(success: true, value: notification, error: nil)
      else
        Result.new(success: false, value: nil, error: notification.errors.full_messages.first)
      end
    end
  end
end
