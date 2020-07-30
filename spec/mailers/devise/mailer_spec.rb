# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Devise::Mailer, type: :mailer do
  let(:user) { build(:user) }
  let(:token) { '123456' }

  describe "reset_password_instructions" do
    let(:mail) { described_class.reset_password_instructions(user, token) }

    it "renders the body" do
      expect(mail.body.encoded).to match(%r{http://.+/users/password/edit})
    end
  end
end
