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

  def make_collection(title)
    {
      'has_model_ssim' => 'Collection',
      id: SecureRandom.uuid,
      'title_tesim' => [title],
      'suppressed_bsi' => false,
      'read_access_group_ssim' => ['public'],
      'edit_access_group_ssim' => ['admin'],
      'visibility_ssi' => 'open',
      'collection_type_gid_ssim' => ['gid://hyku/Hyrax::CollectionType/1']
    }
  end

  def count_queries(&block)
    count = 0
    counter = ->(*, **) { count += 1 }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
    count
  end

  let(:solr) { Blacklight.default_index.connection }
  let(:admin) { create(:admin) }
  let(:works_5) { 5.times.map { |i| make_work("Memoization Test Work #{i}") } }
  let(:collections_3) { 3.times.map { |i| make_collection("Memoization Test Collection #{i}") } }

  before { login_as admin }

  after do
    solr.delete_by_query('title_tesim:Memoization*')
    solr.commit
  end

  it 'does not issue proportionally more queries for more results' do
    # baseline: 1 work
    solr.add([works_5.first])
    solr.commit
    queries_for_1 = count_queries { visit '/catalog?q=Memoization+Test' }
    expect(page).to have_content('Memoization Test Work 0')

    # realistic: 5 works + 3 collections (mixed result page, admin user)
    solr.add(works_5 + collections_3)
    solr.commit
    queries_for_mixed = count_queries { visit '/catalog?q=Memoization+Test' }
    expect(page).to have_content('Memoization Test Work 0')
    expect(page).to have_content('Memoization Test Collection 0')

    puts "Queries for 1 work (admin): #{queries_for_1}"
    puts "Queries for 5 works + 3 collections (admin): #{queries_for_mixed}"
    puts "Delta: #{queries_for_mixed - queries_for_1}"

    expect(queries_for_mixed).to be < 400
  end
end
