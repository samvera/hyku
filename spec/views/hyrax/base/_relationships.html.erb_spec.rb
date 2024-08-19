# frozen_string_literal: true

RSpec.describe 'hyrax/base/relationships', type: :view do
  let(:user) { FactoryBot.create(:user) }
  let(:ability) { Ability.new(user) }
  let(:parent_works) { [] }
  let(:presenter) { Hyku::WorkShowPresenter.new(SolrDocument.new, ability) }
  let(:generic_work) do
    Hyrax::WorkShowPresenter.new(
      SolrDocument.new(
        id: '456',
        has_model_ssim: ['GenericWork'],
        title_tesim: ['Parent work']
      ),
      ability
    )
  end
  let(:page) { Capybara::Node::Simple.new(rendered) }

  before do
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:parent_path).with(generic_work).and_return("/concern/generic_works/#{generic_work.id}")
    allow(presenter).to receive(:parent_works).and_return(parent_works)
  end

  context "when no parents are present" do
    it "does not have links to parents" do
      render 'hyrax/base/relationships', presenter: presenter

      expect(page).not_to have_text 'Parent work'
    end
  end

  context "when parents are present" do
    let(:parent_works) { [generic_work] }

    it "links to work and collection" do
      render 'hyrax/base/relationships', presenter: presenter

      expect(page).to have_link 'Parent work'
    end
  end
end
