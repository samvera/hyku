# frozen_string_literal: true

# Preview all emails at /rails/mailers/hyku_mailer/summary_email
class HykuMailerPreview < ActionMailer::Preview
  def summary_email
    message = Struct.new(:subject, :body, :created_at)
    messages = [
      message.new(
        'Deposit needs review	',
'"dummy work (<a href="/concern/generic_works/ab387de7-5cc3-4bee-980b-c08c24a29dfd\">ab387de7-5cc3-4bee-980b-c08c24a29dfd</a>) was deposited by admin@example.com and is awaiting approval "', 1.day.ago
      ),
      message.new('Passing batch create	', 'The batch create for admin@example.com passed.', 2.days.ago)
    ]

    user = Struct.new(:email, :name).new('admin@example.com', 'Admin')

    site = Struct.new(:application_name)
    sites = site.new('Hyku Test')

    account = Struct.new(:cname, :contact_email, :sites).new('local', 'user@example.com', sites)

    HykuMailer.new.summary_email(user, messages, account)
  end
end
