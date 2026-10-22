# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Contact Form', type: :feature, clean: true, flexible: :either do
  # Hyrax::ContactFormDecorator builds the mail headers from Site.account
  # (email_subject_prefix, contact_email_to, contact_email), and Site's account is an
  # optional association that is nil in a single-tenant test run. Supply an account the
  # same way spec/mailers/hyrax/contact_mailer_spec.rb does.
  #
  # Add an example without this stub when issue #3423 is fixed.
  # KNOWN APPLICATION ISSUE: with no Site.account, submitting the form raises NoMethodError
  # (nil.email_subject_prefix), which the controller does not rescue (it rescues only
  # RuntimeError). Fix goes in: app/models/hyrax/contact_form_decorator.rb (nil-safe headers).
  let(:account) { create(:account) }

  before { allow(Site).to receive(:account).and_return(account) }

  it 'submits the contact form for each issue type and validates errors' do
    # Hyrax::ContactForm validates presence of name, email, subject, message, and
    # category, so all of them must be filled for a successful submission.
    %w[Depositing Making Browsing Reporting General].each do |issue|
      visit '/contact'
      select(issue, from: 'Issue Type')
      fill_in 'Your Name', with: 'Rosa Delgado'
      fill_in 'Your Email', with: 'rosa.delgado@example.edu'
      fill_in 'Subject', with: "Question about #{issue.downcase}"
      fill_in 'Message', with: "Hello, I have a question about #{issue.downcase} in the repository."
      expect { click_button 'Send' }.to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(page).to have_content('Thank you')

      mail = ActionMailer::Base.deliveries.last
      expect(mail.subject).to include("Question about #{issue.downcase}")
      expect(mail.body.encoded).to include("question about #{issue.downcase} in the repository")
    end
    # Validation: an empty submission is rejected.
    visit '/contact'
    expect { click_button 'Send' }.not_to change { ActionMailer::Base.deliveries.count }
    expect(page).to have_content("can't be blank")
  end

  it 'shows a notice above the form describing what to use the Contact Form for' do
    visit '/contact'
    # Rendered from t('hyrax.contact_form.notice') inside the alert-info block
    # (see app/views/hyrax/contact_form/new.html.erb and config/locales/hyrax.en.yml)
    expect(page).to have_css('.alert-info')
    within('.alert-info') do
      expect(page).to have_content('Please use the contact form to submit inquiries about this system')
    end
  end

  it 'offers each Issue Type option in the dropdown menu' do
    visit '/contact'
    expect(page).to have_select(
      'Issue Type',
      with_options: [
        'Depositing content',
        'Making changes to my content',
        'Browsing and searching',
        'Reporting a problem',
        'General inquiry or request'
      ]
    )
  end
end
