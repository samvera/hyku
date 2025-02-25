# frozen_string_literal: true

RSpec.describe Hyrax::NotificationsController, type: :controller do
  routes { Hyrax::Engine.routes }

  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "#index" do
    let!(:conversation1) { create(:mailboxer_conversation) }
    let!(:conversation2) { create(:mailboxer_conversation) }
    let!(:message1) { create(:mailboxer_message, conversation: conversation1, sender: user) }
    let!(:message2) { create(:mailboxer_message, conversation: conversation2, sender: user) }
    let!(:receipt1) { create(:mailboxer_receipt, notification: message1, receiver: user, mailbox_type: 'inbox', is_read: false) }
    let!(:receipt2) { create(:mailboxer_receipt, notification: message2, receiver: user, mailbox_type: 'inbox', is_read: false) }

    it "shows notifications page" do
      get :index
      expect(response).to be_successful
    end

    it "assigns inbox messages" do
      get :index
      expect(assigns(:messages)).to match_array([conversation1, conversation2])
    end

    it "marks unread messages as read" do
      expect do
        get :index
      end.to change {
        Mailboxer::Receipt.where(receiver: user, is_read: false).count
      }.from(2).to(0)
    end

    it "enqueues the StreamNotificationsJob" do
      expect(StreamNotificationsJob).to receive(:perform_later).with(user)
      get :index
    end

    it "sets breadcrumbs" do
      expect(controller).to receive(:add_breadcrumb).exactly(3).times
      get :index
    end
  end
end
