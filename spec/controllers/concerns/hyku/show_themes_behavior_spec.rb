# frozen_string_literal: true

RSpec.describe Hyku::ShowThemesBehavior do
  let(:controller) { Hyrax::CollectionsController.new }

  describe 'the around action' do
    it 'is registered once on the collection show' do
      callbacks = Hyrax::CollectionsController._process_action_callbacks.select { |callback| callback.kind == :around }
      expect(callbacks.count { |callback| callback.filter == :inject_chrome_theme_views }).to eq 1
    end

    it 'is registered once on the file set show' do
      callbacks = Hyrax::FileSetsController._process_action_callbacks.select { |callback| callback.kind == :around }
      expect(callbacks.count { |callback| callback.filter == :inject_chrome_theme_views }).to eq 1
    end

    it 'stays on the work show for every show theme' do
      callbacks = Hyrax::GenericWorksController._process_action_callbacks.select { |callback| callback.kind == :around }
      expect(callbacks.count { |callback| callback.filter == :inject_show_theme_views }).to eq 1
    end
  end

  describe '#inject_show_theme_views' do
    def theme_paths(paths)
      paths.count { |resolver| resolver.to_path.to_s.end_with?('app/views/themes/screening_room_show') }
    end

    it 'prepends the theme path for the action without touching the class paths' do
      allow(controller).to receive(:show_page_theme).and_return('screening_room_show')
      during = nil

      controller.inject_show_theme_views { during = theme_paths(controller.view_paths) }

      expect(during).to be_positive
      expect(theme_paths(Hyrax::CollectionsController._view_paths)).to eq 0
    end

    it 'leaves the paths alone for a theme whose chrome does not cover these pages' do
      allow(controller).to receive(:show_page_theme).and_return('cultural_show')
      during = nil

      controller.inject_chrome_theme_views { during = theme_paths(controller.view_paths) }

      expect(during).to eq 0
      expect(controller.view_paths.map { |resolver| resolver.to_path.to_s })
        .to all(satisfy { |path| !path.end_with?('themes/cultural_show') })
    end

    it 'leaves the paths alone for the default theme' do
      allow(controller).to receive(:show_page_theme).and_return('default_show')
      before = controller.view_paths.size
      during = nil

      controller.inject_show_theme_views { during = controller.view_paths.size }

      expect(during).to eq before
    end
  end
end
