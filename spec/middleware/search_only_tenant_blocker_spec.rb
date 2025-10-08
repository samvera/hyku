# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchOnlyTenantBlocker do
  let(:app) { double('app') }
  let(:middleware) { described_class.new(app) }
  let(:env) { Rack::MockRequest.env_for(path) }

  describe '#call' do
    context 'when HYRAX_FLEXIBLE is enabled' do
      before do
        stub_const('ENV', ENV.to_hash.merge('HYRAX_FLEXIBLE' => 'true'))
      end

      context 'for search-only tenants' do
        before do
          search_account = instance_double("Account")
          allow(search_account).to receive(:search_only?).and_return(true)
          allow(Site).to receive(:account).and_return(search_account)
        end

        context 'when accessing metadata_profiles path' do
          let(:path) { '/metadata_profiles' }

          it 'redirects to access denied page' do
            response = middleware.call(env)
            
            expect(response[0]).to eq(302)
            expect(response[1]['Location']).to eq('/access_denied?reason=metadata_profiles')
          end
        end

        context 'when accessing metadata_profiles sub-path' do
          let(:path) { '/metadata_profiles/new' }

          it 'redirects to access denied page' do
            response = middleware.call(env)
            
            expect(response[0]).to eq(302)
            expect(response[1]['Location']).to eq('/access_denied?reason=metadata_profiles')
          end
        end

        context 'when accessing metadata_profiles with ID' do
          let(:path) { '/metadata_profiles/123/edit' }

          it 'redirects to access denied page' do
            response = middleware.call(env)
            
            expect(response[0]).to eq(302)
            expect(response[1]['Location']).to eq('/access_denied?reason=metadata_profiles')
          end
        end

        context 'when accessing other paths' do
          let(:path) { '/dashboard' }

          it 'passes through to the application' do
            expect(app).to receive(:call).with(env).and_return([200, {}, ['OK']])
            
            response = middleware.call(env)
            expect(response).to eq([200, {}, ['OK']])
          end
        end

        context 'when accessing access_denied path' do
          let(:path) { '/access_denied' }

          it 'passes through to prevent redirect loops' do
            expect(app).to receive(:call).with(env).and_return([200, {}, ['OK']])
            
            response = middleware.call(env)
            expect(response).to eq([200, {}, ['OK']])
          end
        end
      end

      context 'for regular (non-search) tenants' do
        before do
          regular_account = instance_double("Account")
          allow(regular_account).to receive(:search_only?).and_return(false)
          allow(Site).to receive(:account).and_return(regular_account)
        end

        context 'when accessing metadata_profiles path' do
          let(:path) { '/metadata_profiles' }

          it 'passes through to the application' do
            expect(app).to receive(:call).with(env).and_return([200, {}, ['OK']])
            
            response = middleware.call(env)
            expect(response).to eq([200, {}, ['OK']])
          end
        end
      end

      context 'when Site.account is nil' do
        before do
          allow(Site).to receive(:account).and_return(nil)
        end

        context 'when accessing metadata_profiles path' do
          let(:path) { '/metadata_profiles' }

          it 'passes through to the application' do
            expect(app).to receive(:call).with(env).and_return([200, {}, ['OK']])
            
            response = middleware.call(env)
            expect(response).to eq([200, {}, ['OK']])
          end
        end
      end
    end

    context 'when HYRAX_FLEXIBLE is disabled' do
      before do
        stub_const('ENV', ENV.to_hash.merge('HYRAX_FLEXIBLE' => 'false'))
      end

      context 'for search-only tenants' do
        before do
          search_account = instance_double("Account")
          allow(search_account).to receive(:search_only?).and_return(true)
          allow(Site).to receive(:account).and_return(search_account)
        end

        context 'when accessing metadata_profiles path' do
          let(:path) { '/metadata_profiles' }

          it 'passes through to the application without blocking' do
            expect(app).to receive(:call).with(env).and_return([200, {}, ['OK']])
            
            response = middleware.call(env)
            expect(response).to eq([200, {}, ['OK']])
          end
        end
      end
    end

    context 'when HYRAX_FLEXIBLE is not set' do
      before do
        stub_const('ENV', ENV.to_hash.except('HYRAX_FLEXIBLE'))
      end

      context 'for search-only tenants' do
        before do
          search_account = instance_double("Account")
          allow(search_account).to receive(:search_only?).and_return(true)
          allow(Site).to receive(:account).and_return(search_account)
        end

        context 'when accessing metadata_profiles path' do
          let(:path) { '/metadata_profiles' }

          it 'passes through to the application without blocking' do
            expect(app).to receive(:call).with(env).and_return([200, {}, ['OK']])
            
            response = middleware.call(env)
            expect(response).to eq([200, {}, ['OK']])
          end
        end
      end
    end
  end
end