# frozen_string_literal: true

json.extract! user,
              :id,
              :facebook_handle,
              :twitter_handle,
              :googleplus_handle,
              :display_name,
              :address,
              :department,
              :title,
              :office,
              :chat_id,
              :website,
              :affiliation,
              :telephone,
              :avatar,
              :group_list,
              :linkedin_handle,
              :orcid,
              :arkivo_token,
              :arkivo_subscription,
              :zotero_token,
              :zotero_userid,
              :preferred_locale,
              :created_at,
              :updated_at

json.url user_url(user, format: :json)
