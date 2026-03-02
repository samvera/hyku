# frozen_string_literal: true

RSpec.describe 'Admin Dashboard', type: :request, singletenant: true, clean: true do
  context 'as a non logged-in user' do
    describe 'I cannot access the dashboard' do
      it 'redirects the user to the log-in page' do # You need to sign in or sign up before continuing
        get '/dashboard'
        expect(response.status).to eq(302)
      end
    end
  end

  context 'as an admin user' do
    let(:admin) { FactoryBot.create(:admin) }

    before do
      login_as(admin, scope: :user)
    end

    describe 'I can hit every url corresponding to each link in the admin dashboard' do
      # Activity
      it 'gets the url for activity summary' do # Activity Summary
        get '/dashboard'
        expect(response.status).to eq(200)
      end

      it 'gets the url for system status' do # System Status
        get '/status'
        expect(response.status).to eq(200)
      end

      it 'gets the url for profile' do # Profile
        get "/dashboard/profiles/#{admin.email.gsub('.', '-dot-')}"
        expect(response.status).to eq(200)
      end

      it 'gets the url for notifications' do # Notifications
        get '/notifications'
        expect(response.status).to eq(200)
      end

      it 'gets the url for transfers' do # Transfers
        get '/dashboard/transfers'
        expect(response.status).to eq(200)
      end

      it 'gets the url for manage proxies' do # Manage Proxies
        get '/proxies'
        expect(response.status).to eq(200)
      end

      it 'gets the url for reports' do # Reports
        get '/admin/stats'
        expect(response.status).to eq(200)
      end

      it 'gets the url for Sidekiq dashboard' do # Sidekiq Dashboard (or GoodJob at /jobs when so configured)
        get '/jobs'
        # 200 when jobs UI is mounted; 302 when the mounted app redirects; 404 when /jobs is not mounted (e.g. queue is inline)
        expect([200, 302, 404]).to include(response.status)
      end

      # Repository Contents
      it 'gets the url for collections' do # Collections
        get '/dashboard/collections'
        expect(response.status).to eq(200)
      end

      it 'gets the url for works' do # Workds
        get '/dashboard/works'
        expect(response.status).to eq(200)
      end

      it 'gets the url for importers' do # Importers (Bulkrax)
        skip 'Bulkrax routes not mounted' unless Hyku.bulkrax_enabled?
        get '/importers'
        # Bulkrax may redirect to root in request specs; accept 200 (success) or 302 (redirect)
        expect([200, 302]).to include(response.status)
      end

      it 'gets the url for exporters' do # Exporters (Bulkrax)
        skip 'Bulkrax routes not mounted' unless Hyku.bulkrax_enabled?
        get '/exporters'
        # Bulkrax may redirect to root in request specs; accept 200 (success) or 302 (redirect)
        expect([200, 302]).to include(response.status)
      end

      # Tasks
      it 'gets the url for review submissions' do # Review Submissions
        get '/admin/workflows'
        expect(response.status).to eq(200)
      end

      it 'gets the url for manage users' do   # Manage Users
        get '/admin/users'
        expect(response.status).to eq(200)
      end

      it 'gets the url for manage groups' do  # Manage Groups
        get '/admin/groups'
        expect(response.status).to eq(200)
      end

      it 'gets the url for manage embargoes' do # Manage Embargoes
        get '/embargoes'
        expect(response.status).to eq(200)
      end

      it 'gets the url for manage leases' do # Manage Leases
        get '/leases'
        expect(response.status).to eq(200)
      end

      # Configuration
      it 'gets the url for labels' do # Labels
        get '/site/labels/edit'
        expect(response.status).to eq(200)
      end

      it 'gets the url for appearance' do # Appearance
        get '/admin/appearance'
        expect(response.status).to eq(200)
      end

      it 'gets the url for collection types' do # Collection Types
        get '/admin/collection_types'
        expect(response.status).to eq(200)
      end

      it 'gets the url for pages' do # Pages
        get '/pages/edit'
        expect(response.status).to eq(200)
      end

      it 'gets the url for content blocks' do # Content Blocks
        get '/content_blocks/edit'
        expect(response.status).to eq(200)
      end

      it 'gets the url for features' do # Features
        get '/admin/features'
        expect(response.status).to eq(200)
      end

      it 'gets the url for available work types' do # Available Work Types
        get '/admin/work_types/edit'
        expect(response.status).to eq(200)
      end

      it 'gets the url for workflow roles' do # Workflow Roles
        get '/admin/workflow_roles'
        expect(response.status).to eq(200)
      end
    end
  end

  context 'as a logged-in user who is not an admin' do
    let(:user) { create(:user, email: 'test@example.com') }

    before do
      login_as user, scope: :user
    end

    describe 'I can hit some urls corresponding to each link in the admin dashboard' do
      # Activity
      it 'gets the url for activity summary' do # Activity Summary
        get '/dashboard'
        expect(response.status).to eq(200)
      end

      it 'renders a status of you are not authorized to access the System Status page' do # System Status
        get '/status'
        expect(response.status).to eq(302)
      end

      it 'gets the url for profile' do # Profile
        get "/dashboard/profiles/#{user.email.gsub('.', '-dot-')}"
        expect(response.status).to eq(200)
      end

      it 'gets the url for notifications' do # Notifications
        get '/notifications'
        expect(response.status).to eq(200)
      end

      it 'gets the url for transfers' do # Transfers
        get '/dashboard/transfers'
        expect(response.status).to eq(200)
      end

      it 'gets the url for manage proxies' do # Manage Proxies
        get '/proxies'
        expect(response.status).to eq(200)
      end

      it 'renders a status of you are not authorized to access the Reports page' do # Reports
        get '/admin/stats'
        expect(response.status).to eq(302)
      end

      it 'renders a status of you are not authorized to access the Sidekiq dashboard' do # Sidekiq Dashboard
        get '/jobs'
        # 302 when route is mounted and user is unauthorized; 404 when /jobs is not mounted (e.g. queue adapter is inline)
        expect([302, 404]).to include(response.status)
      end

      # Repository Contents
      it 'gets the url for collections' do # Collections
        get '/dashboard/collections'
        expect(response.status).to eq(200)
      end

      it 'gets the url for works' do # Works
        get '/dashboard/works'
        expect(response.status).to eq(200)
      end

      it 'renders a status of you are not authorized to access the Importers page' do # Importers (Bulkrax)
        skip 'Bulkrax routes not mounted' unless Hyku.bulkrax_enabled?
        get '/importers'
        expect(response.status).to eq(302)
      end

      it 'renders a status of you are not authorized to access the Exporters page' do # Exporters (Bulkrax)
        skip 'Bulkrax routes not mounted' unless Hyku.bulkrax_enabled?
        get '/exporters'
        expect(response.status).to eq(302)
      end

      # Tasks
      it 'renders a status of you are not authorized to access the Review Submissions page' do # Review Submissions
        get '/admin/workflows'
        expect(response.status).to eq(302)
      end

      it 'renders a status of you are not authorized to access the Manage Users page' do # Manage Users
        get '/admin/users'
        expect(response.status).to eq(302)
      end

      it 'renders a status of you are not authorized to access the Manage Groups page' do # Manage Groups
        get '/admin/groups'
        expect(response.status).to eq(302)
      end

      it 'renders a status of you are not authorized to access the Manage Embargoes page' do # Manage Embargoes
        get '/embargoes'
        expect(response.status).to eq(302)
      end

      it 'renders a status of you are not authorized to access the Manage Leases page' do # Manage Leases
        get '/leases'
        expect(response.status).to eq(302)
      end

      # Configuration
      it 'renders a status of the Labels page is private' do # Labels
        get '/site/labels/edit'
        expect(response.status).to eq(401)
      end

      it 'renders a status of the Appearance page is private' do # Appearance
        get '/admin/appearance'
        expect(response.status).to eq(401)
      end

      it 'renders a status of you are not authorized to access the Collection Types page' do # Collection Types
        get '/admin/collection_types'
        expect(response.status).to eq(302)
      end

      it 'renders a status that the Pages page is private' do # Pages
        get '/pages/edit'
        expect(response.status).to eq(401)
      end

      it 'renders a status of the Content Blocks page is private' do # Content Blocks
        get '/content_blocks/edit'
        expect(response.status).to eq(401)
      end

      it 'renders a status of you are not authorized to access the Features page' do # Features
        get '/admin/features'
        expect(response.status).to eq(302)
      end

      it 'renders a status of you are not authorized to access the Available Work Types page' do # Available Work Types
        get '/admin/work_types/edit'
        expect(response.status).to eq(302)
      end

      it 'renders a status of you are not authorized to access the Workflow Roles page' do # Workflow Roles
        get '/admin/workflow_roles'
        expect(response.status).to eq(302)
      end
    end
  end
end
