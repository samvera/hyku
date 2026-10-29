# frozen_string_literal: true

RSpec.describe Hyrax::FileSetsController, type: :controller do
  routes { Rails.application.routes }

  let(:file_set) { Hyrax::FileSet.new(id: 'fs1', title: ['harbor-0001.jpg'], new_record: false) }

  before do
    allow(controller).to receive(:curation_concern).and_return(file_set)
    allow(controller).to receive(:redirect_to)
  end

  it 'names the file by its title in the updated notice' do
    controller.send(:after_update_response)

    expect(controller).to have_received(:redirect_to) do |_target, options|
      expect(options[:notice]).to include('harbor-0001.jpg')
      expect(options[:notice]).not_to include('Hyrax::FileSet')
    end
  end
end
