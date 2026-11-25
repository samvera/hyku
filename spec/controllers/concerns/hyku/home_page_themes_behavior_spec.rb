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

    context 'CatalogController' do
      it 'responds to #inject_theme_views' do
        expect(CatalogController.new).to respond_to :inject_theme_views
      end

      it 'adds the around action once' do
        callbacks = CatalogController._process_action_callbacks.select { |callback| callback.kind == :around }
        expect(callbacks.count { |callback| callback.filter == :inject_theme_views }).to eq 1
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

    it "puts a knapsack's theme views ahead of Hyku's, so a knapsack override wins" do
      controller = Hyrax::HomepageController.new
      allow(controller).to receive(:home_page_theme).and_return('digital_collection')
      allow(Hyku::Application).to receive(:theme_view_path_roots).and_return(['/knapsack', Rails.root.to_s])
      paths = nil

      controller.inject_theme_views { paths = controller.view_paths.map { |resolver| resolver.to_path.to_s } }

      expect(paths.index('/knapsack/app/views/themes/digital_collection'))
        .to be < paths.index(Rails.root.join('app', 'views', 'themes', 'digital_collection').to_s)
    end
  end
end
