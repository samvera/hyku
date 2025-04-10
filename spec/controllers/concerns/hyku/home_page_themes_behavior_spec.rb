# frozen_string_literal: true

RSpec.describe Hyku::HomePageThemesBehavior do
  describe '#inject_theme_views' do
    context 'Hyrax::ContactFormController' do
      it 'responds to #inject_theme_views' do
        expect(Hyrax::ContactFormController.new).to respond_to :inject_theme_views
      end

      it 'adds the around action' do
        callbacks = Hyrax::ContactFormController._process_action_callbacks.select { |callback| callback.kind == :around }
        expect(callbacks.any? { |callback| callback.filter == :inject_theme_views }).to be true
      end
    end

    context 'Hyrax::HomepageController' do
      it 'responds to #inject_theme_views' do
        expect(Hyrax::HomepageController.new).to respond_to :inject_theme_views
      end

      it 'adds the around action' do
        callbacks = Hyrax::HomepageController._process_action_callbacks.select { |callback| callback.kind == :around }
        expect(callbacks.any? { |callback| callback.filter == :inject_theme_views }).to be true
      end
    end

    context 'Hyrax::PagesController' do
      it 'responds to #inject_theme_views' do
        expect(Hyrax::PagesController.new).to respond_to :inject_theme_views
      end

      it 'adds the around action' do
        callbacks = Hyrax::PagesController._process_action_callbacks.select { |callback| callback.kind == :around }
        expect(callbacks.any? { |callback| callback.filter == :inject_theme_views }).to be true
      end
    end
  end
end
