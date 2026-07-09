# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'layouts/_head_tag_content.html.erb', type: :view do
  describe 'generator meta tag identification' do
    context 'generator identification' do
      it 'renders Hyku generator meta tag, not Hyrax' do
        render

        expect(rendered).to include('<meta name="generator" content="Samvera Hyku')
      end

      it 'includes correct Hyku version in generator tag' do
        render

        hyku_version = ::Hyku::VERSION.to_s
        expect(rendered).to include(%(<meta name="generator" content="Samvera Hyku #{hyku_version}" />))
      end

      it 'does NOT contain Samvera Hyrax generator tag' do
        render

        # Critical: ensure Hyrax identifier is not present
        expect(rendered).not_to match(/Samvera Hyrax.*generator|generator.*Samvera Hyrax/i)
      end

      it 'generator tag format is valid HTML5' do
        render

        # Verify proper HTML5 self-closing meta tag format
        expect(rendered).to match(/<meta name="generator" content="Samvera Hyku \d+\.\d+\.\d+" \/>/)
      end
    end

    context 'other required meta tags' do
      it 'includes CSRF protection meta tag' do
        render

        expect(rendered).to include('csrf-token')
      end

      it 'includes charset meta tag' do
        render

        expect(rendered).to include('<meta charset="utf-8"')
      end

      it 'includes viewport meta tag for responsive design' do
        render

        expect(rendered).to include('<meta name="viewport" content="width=device-width, initial-scale=1.0"')
      end

      it 'includes resourcesync link' do
        render

        expect(rendered).to include('rel="resourcesync"')
      end
    end

    context 'complete head content structure' do
      it 'renders all required elements in correct order' do
        render

        # Verify structure: csrf, charset, viewport, resourcesync, generator
        csrf_pos = rendered.index('csrf-token')
        charset_pos = rendered.index('charset')
        viewport_pos = rendered.index('viewport')
        generator_pos = rendered.index('Samvera Hyku')

        expect(csrf_pos).to be < charset_pos
        expect(charset_pos).to be < viewport_pos
        expect(viewport_pos).to be < generator_pos
      end

      it 'does not break stylesheet or javascript inclusion' do
        render

        expect(rendered).to include('stylesheet_link_tag')
        expect(rendered).to include('javascript_include_tag')
      end
    end
  end
end
