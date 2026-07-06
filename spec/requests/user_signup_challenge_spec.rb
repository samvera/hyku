# frozen_string_literal: true

RSpec.describe 'User self-registration spam challenge', type: :request, singletenant: true do
  let(:account) do
    Account.new do |a|
      a.build_solr_endpoint
      a.build_fcrepo_endpoint unless Hyrax.config.disable_wings
      a.build_redis_endpoint
      a.build_data_cite_endpoint
    end
  end
  let(:verifier) { Rails.application.message_verifier('hyku_signup_challenge') }
  let(:elapsed_timestamp) { verifier.generate(10.seconds.ago.to_i) }
  let(:user_params) do
    {
      user: {
        display_name: 'Challenge Tester',
        email: 'challenge-tester@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      }
    }
  end

  before do
    allow(Account).to receive(:from_request).and_return(account)
  end

  context 'when the signup challenge setting is on' do
    before { account.signup_spam_protection = true }

    it 'rejects a submission with the honeypot field filled' do
      payload = user_params.merge(registration_website: 'http://spam.example.com',
                                  registration_timestamp: elapsed_timestamp)
      expect { post '/users', params: payload }.not_to change(User, :count)
    end

    it 'redirects back to the signup form with an alert when rejecting' do
      payload = user_params.merge(registration_website: 'http://spam.example.com',
                                  registration_timestamp: elapsed_timestamp)
      post '/users', params: payload
      expect(response).to redirect_to('/users/sign_up')
      expect(flash[:alert]).to eq I18n.t('hyku.account.signup_challenge_failed')
    end

    it 'rejects a submission that arrives faster than the minimum time' do
      too_fast = verifier.generate(Time.current.to_i)
      expect { post '/users', params: user_params.merge(registration_timestamp: too_fast) }
        .not_to change(User, :count)
    end

    it 'rejects a submission with a missing or tampered timestamp' do
      expect { post '/users', params: user_params.merge(registration_timestamp: 'tampered') }
        .not_to change(User, :count)
    end

    it 'accepts a legitimate submission' do
      expect { post '/users', params: user_params.merge(registration_timestamp: elapsed_timestamp) }
        .to change(User, :count).by(1)
    end

    it 'renders the challenge fields on the signup form' do
      get '/users/sign_up'
      expect(response.body).to include('registration_website')
    end
  end

  context 'when the signup challenge setting is off' do
    it 'registers the user even when the honeypot field is filled' do
      expect { post '/users', params: user_params.merge(registration_website: 'http://spam.example.com') }
        .to change(User, :count).by(1)
    end

    it 'does not render the challenge fields on the signup form' do
      get '/users/sign_up'
      expect(response.body).not_to include('registration_website')
    end
  end

  context 'when the account is a public demo tenant' do
    before { account.public_demo_tenant = true }

    it 'enforces the challenge even though the setting is off' do
      expect { post '/users', params: user_params.merge(registration_website: 'http://spam.example.com') }
        .not_to change(User, :count)
    end

    it 'accepts a legitimate submission' do
      expect { post '/users', params: user_params.merge(registration_timestamp: elapsed_timestamp) }
        .to change(User, :count).by(1)
    end
  end
end
