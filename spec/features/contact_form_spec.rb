# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Contact Form', type: :feature, clean: true do
  it 'submits the contact form for each issue type and validates errors' do
    # Hyrax::ContactForm validates presence of name, email, subject, message, and
    # category, so all of them must be filled for a successful submission.
    %w[Depositing Making Browsing Reporting General].each do |issue|
      visit '/contact'
      select(issue, from: 'Issue Type')
      fill_in 'Your Name', with: 'Contact Tester'
      fill_in 'Your Email', with: 'contact@example.com'
      fill_in 'Subject', with: "Subject for #{issue}"
      fill_in 'Message', with: "Test message for #{issue}"
      click_button 'Send'
      expect(page).to have_content('Thank you')
    end
    # Validation: an empty submission is rejected.
    visit '/contact'
    click_button 'Send'
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


# ## Contact Page
# [Back to TOC](#table-of-contents)

# ![image11](https://github.com/samvera/hyku/assets/19597776/0e453cc4-b44d-4ba4-b324-5fbcdce8bee8)

# ### As a user:

# - [ ] I can see a notice above the form describing the kind of things to submit a Contact Form for
# - [ ] I can select an option from the Issue Type dropdown menu:
#   - [ ] Depositing content
#   - [ ] Making changes to my content
#   - [ ] Browsing and searching
#   - [ ] Reporting a problem
#   - [ ] General inquiry or request
# - [ ] I can click Send to send the Contact Form
#   - [ ] Form won’t send successfully if any of the fields are invalid