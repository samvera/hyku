# frozen_string_literal: true

# OVERRIDE ability to download files when the site disallows downloads.
module AbilityDecorator
  def test_download(*args)
    account = Site.account

    # In cases where we don't have an account.
    return super unless account

    if account.settings[:allow_downloads].nil? || account.settings[:allow_downloads].to_i.nonzero?
      super
    else
      false
    end
  end
end

Ability.prepend(AbilityDecorator)
