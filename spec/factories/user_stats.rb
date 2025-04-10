# frozen_string_literal: true
FactoryBot.define do
  factory :user_stat do
    user_id { create(:user).id }
    date { Time.zone.today }
    file_views { rand(1..100) }
    file_downloads { rand(1..100) }
    work_views { rand(1..100) }
  end
end
