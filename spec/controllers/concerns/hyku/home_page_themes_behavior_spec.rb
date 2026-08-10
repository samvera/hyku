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

    context 'with a theme registered with a parent (thin variant)' do
      let(:controller) { Hyrax::HomepageController.new }

      before do
        controller.set_request!(ActionDispatch::TestRequest.create)
        allow(controller).to receive(:home_page_theme).and_return('practice_research_scholarly')
      end

      it 'prepends the variant path in front of the parent path so both resolve, variant first' do
        paths_during = nil
        controller.send(:inject_theme_views) { paths_during = controller.view_paths.map(&:to_s) }

        variant = paths_during.index { |p| p.end_with?('themes/practice_research_scholarly') }
        parent  = paths_during.index { |p| p.end_with?('themes/practice_research') }
        expect(variant).not_to be_nil
        expect(parent).not_to be_nil
        expect(variant).to be < parent
      end
    end
  end
end
