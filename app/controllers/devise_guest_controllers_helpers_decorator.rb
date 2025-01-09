# frozen_string_literal: true

# OVERRIDE devise-invitable 2.0.9 to unscope user look up
module DeviseGuestControllersHelpersDecorator
  def guest_user
    return @guest_user if @guest_user

    if session[:guest_user_id]
      begin
        @guest_user = User.unscoped.find_by(User.authentication_keys.first => session[:guest_user_id])
      rescue
        @guest_user = nil
      end
      @guest_user = nil if @guest_user.respond_to?(:guest) && !@guest_user.guest
    end

    @guest_user ||= begin
                      u = create_guest_user(session[:guest_user_id])
                      session[:guest_user_id] = u.send(User.authentication_keys.first)
                      u
                    end

    @guest_user
  end
end

DeviseGuests::Controllers::Helpers.prepend(DeviseGuestControllersHelpersDecorator)
