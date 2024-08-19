# frozen_string_literal: true

def expect_social_fields
  assert_select "input[name=?]", "user[avatar]"
  assert_select "input[name=?]", "user[facebook_handle]"
  assert_select "input[name=?]", "user[twitter_handle]"
  assert_select "input[name=?]", "user[googleplus_handle]"
  assert_select "input[name=?]", "user[chat_id]"
  assert_select "input[name=?]", "user[website]"
end

def expect_contact_fields
  assert_select "input[name=?]", "user[email]"
  assert_select "input[name=?]", "user[display_name]"
  assert_select "input[name=?]", "user[address]"
  assert_select "input[name=?]", "user[department]"
  assert_select "input[name=?]", "user[title]"
  assert_select "input[name=?]", "user[office]"
  assert_select "input[name=?]", "user[affiliation]"
  assert_select "input[name=?]", "user[telephone]"
  assert_select "input[name=?]", "user[orcid]"
end

def expect_additional_fields
  assert_select "textarea[name=?]", "user[group_list]"
  assert_select "input[name=?]", "user[arkivo_subscription]"
  assert_select "input[name=?]", "user[preferred_locale]"
end

# rubocop:disable Metrics/MethodLength
def create_hyrax_countermetric_objects
  Hyrax::CounterMetric.create(
    worktype: 'GenericWork',
    resource_type: 'Book',
    work_id: '12345',
    date: '2021-01-05',
    author: '|Tubman, Harriet|',
    year_of_publication: 2022,
    total_item_investigations: 1,
    total_item_requests: 10
  )
  Hyrax::CounterMetric.create(
    worktype: 'GenericWork',
    resource_type: 'Book',
    work_id: '12345',
    date: '2022-01-05',
    author: '|Tubman, Harriet|',
    year_of_publication: 2022,
    total_item_investigations: 1,
    total_item_requests: 10
  )
  Hyrax::CounterMetric.create(
    worktype: 'GenericWork',
    resource_type: 'Book',
    work_id: '54321',
    date: '2022-01-05',
    author: '|X, Malcolm|',
    year_of_publication: 2022,
    total_item_investigations: 3,
    total_item_requests: 5
  )
  # used to test the case where a hyrax countermetric has a unique date, but same work ID.
  Hyrax::CounterMetric.create(
    worktype: 'GenericWork',
    resource_type: 'Book',
    work_id: '54321',
    date: '2022-01-06',
    author: '|X, Malcolm|',
    year_of_publication: 2022,
    total_item_investigations: 2,
    total_item_requests: 4
  )
  Hyrax::CounterMetric.create(
    worktype: 'GenericWork',
    resource_type: 'Article',
    work_id: '98765',
    date: '2023-08-09',
    author: '|Washington, Booker T.|',
    year_of_publication: 1999,
    total_item_investigations: 2,
    total_item_requests: 8
  )
  Hyrax::CounterMetric.create(
    worktype: 'GenericWork',
    resource_type: 'Article',
    work_id: '99999',
    date: '2023-08-09',
    author: '|Douglas, Frederick|',
    year_of_publication: 1997,
    total_item_investigations: 4,
    total_item_requests: 3
  )
  Hyrax::CounterMetric.create(
    worktype: 'GenericWork',
    resource_type: 'Article',
    work_id: '99999',
    date: '2023-10-09',
    author: '|Douglas, Frederick|',
    year_of_publication: 1997,
    total_item_investigations: 4,
    total_item_requests: 3
  )
end
# rubocop:enable Metrics/MethodLength
