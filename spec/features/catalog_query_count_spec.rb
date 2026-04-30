# frozen_string_literal: true

RSpec.describe 'Catalog query performance', type: :feature, clean: true, js: false do
  def make_work(title)
    {
      'has_model_ssim' => 'GenericWork',
      id: SecureRandom.uuid,
      'title_tesim' => [title],
      'admin_set_tesim' => ['Default Admin Set'],
      'suppressed_bsi' => false,
      'read_access_group_ssim' => ['public'],
      'edit_access_group_ssim' => ['admin'],
      'edit_access_person_ssim' => ['fake@example.com'],
      'visibility_ssi' => 'open'
    }
  end

  def count_queries(&block)
    count = 0
    counter = ->(*, **) { count += 1 }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
    count
  end

  let(:solr) { Blacklight.default_index.connection }
  let(:user) { create(:user) }
  let(:works_5) { 5.times.map { |i| make_work("Memoization Test #{i}") } }

  before { login_as user }

  it 'keeps total query count for a page of results under a reasonable threshold' do
    solr.add(works_5)
    solr.commit

    queries = count_queries { visit '/catalog?q=Memoization+Test' }
    expect(page).to have_content('Memoization Test 0')

    solr.delete_by_id(works_5.map { |w| w[:id] })
    solr.commit

    # On main without memoization this was ~440 queries for 5 results.
    # With GroupAwareRoleChecker memoization this should be well under 350.
    expect(queries).to be < 350
  end
end
