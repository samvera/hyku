# frozen_string_literal: true

RSpec.describe Hyku::InvitationsController, type: :controller do
  describe '#after_invite_path_for' do
    it "returns admin_users_path" do
      expect(subject.after_invite_path_for(nil)).to eq Hyrax::Engine.routes.url_helpers.admin_users_path(locale: 'en')
    end
  end
end
