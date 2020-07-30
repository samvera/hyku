# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::ContactMailer, type: :mailer do
  let(:contact_form) do
    Hyrax::ContactForm.new(
      email: 'test@example.com',
      category: 'Test',
      subject: 'Test',
      name: 'Test Tester',
      message: 'This is a test'
    )
  end

  describe "reset_password_instructions" do
    let(:mail) { described_class.contact(contact_form) }

    it "renders the body" do
      expect(mail.body.encoded).to match(/Test Tester/)
    end
  end
end
