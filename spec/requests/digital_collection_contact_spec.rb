# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'the digital collection contact page', type: :request, singletenant: true do
  let(:doc) { Nokogiri::HTML(response.body) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:home_page_theme).and_return('digital_collection')
  end

  describe 'the form' do
    before { get hyrax.contact_path }

    it 'shows a page title, the directions and a stacked form' do
      expect(doc.at_css('h1.dc-contact-title').text).to eq('Contact Form')
      expect(doc.at_css('p.dc-contact-intro')).to be_present
      expect(doc.css('form.dc-contact-form .dc-field').size).to eq(5)
    end

    it 'marks every field as required' do
      expect(doc.css('.dc-field label .dc-field-required').map(&:text).uniq).to eq(['(required)'])
      expect(doc.css('.dc-field .form-control').map { |field| field['required'] }.uniq).to eq(['required'])
    end

    it 'keeps the send button and the current nav link' do
      expect(doc.at_css('input.dc-contact-send[type=submit]')['value']).to eq('Send')
      expect(doc.at_css(".dc-masthead-nav a[aria-current='page']").text).to eq('Contact')
    end
  end

  describe 'after a failed send' do
    before { post hyrax.contact_form_index_path, params: { contact_form: { category: '' } } }

    it 'shows the error and keeps the current nav link' do
      expect(doc.at_css('.alert').text).to include('not sent successfully')
      expect(doc.at_css(".dc-masthead-nav a[aria-current='page']").text).to eq('Contact')
    end
  end
end
