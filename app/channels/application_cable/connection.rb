module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    protected

      # rubocop:disable Lint/AssignmentInCondition
      def find_verified_user
        if verified_user = User.find_by(id: user_id)
          verified_user
        else
          reject_unauthorized_connection
        end
      end
      # rubocop:enable Lint/AssignmentInCondition

      def session
        cookies.encrypted[Rails.application.config.session_options[:key]]
      end

      # I don't understand why env['warden'].user was not working, but this was:
      def user_id
        session["warden.user.user.key"][0][0]
      end
  end
end
