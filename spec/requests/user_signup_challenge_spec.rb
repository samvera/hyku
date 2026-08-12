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
  let(:captcha) do
    NegativeCaptcha.new(
      secret: ENV.fetch('NEGATIVE_CAPTCHA_SECRET', 'default-value-change-me'),
      spinner: '127.0.0.1',
      fields: Hyku::RegistrationsController::SIGNUP_CAPTCHA_FIELDS
    )
  end
  let(:challenge_params) do
    {
      timestamp: captcha.timestamp,
      spinner: captcha.spinner,
      'test-display_name' => 'Challenge Tester',
      'test-email' => 'challenge-tester@example.com',
      'test-password' => 'password123',
      'test-password_confirmation' => 'password123'
    }
  end
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

    it 'accepts a legitimate captcha submission' do
      expect { post '/users', params: challenge_params }.to change(User, :count).by(1)
      expect(User.last.email).to eq 'challenge-tester@example.com'
    end

    it 'rejects a submission with a decoy field filled' do
      expect { post '/users', params: challenge_params.merge(email: 'bot@example.com') }
        .not_to change(User, :count)
    end

    it 'rejects a submission with a wrong spinner' do
      expect { post '/users', params: challenge_params.merge(spinner: 'forged') }
        .not_to change(User, :count)
    end

    it 'rejects a plain submission that bypasses the captcha fields' do
      expect { post '/users', params: user_params }.not_to change(User, :count)
    end

    it 'redirects back to the signup form with an alert when rejecting' do
      post '/users', params: user_params
      expect(response).to have_http_status(:redirect)
      expect(response.location).to include('/users/sign_up')
      expect(flash[:alert]).to eq I18n.t('hyku.account.signup_challenge_failed')
    end

    it 'renders the captcha fields on the signup form' do
      get '/users/sign_up'
      expect(response.body).to include('test-email')
      expect(response.body).not_to include('user[email]')
    end
  end

  context 'when the signup challenge setting is off' do
    it 'registers the user through the plain form' do
      expect { post '/users', params: user_params }.to change(User, :count).by(1)
    end

    it 'does not render the captcha fields on the signup form' do
      get '/users/sign_up'
      expect(response.body).to include('user[email]')
      expect(response.body).not_to include('test-email')
    end
  end

  context 'when the account is a public demo tenant' do
    before { account.public_demo_tenant = true }

    it 'enforces the challenge even though the setting is off' do
      expect { post '/users', params: user_params }.not_to change(User, :count)
    end

    it 'accepts a legitimate captcha submission' do
      expect { post '/users', params: challenge_params }.to change(User, :count).by(1)
    end
  end
end
