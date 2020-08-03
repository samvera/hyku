class SplashController < ProprietorController
  def index
    @accounts = Account.where('is_public = ?', true).sorted_by_cname
    @images = @accounts.map do |account|
      Apartment::Tenant.switch(account.tenant) do
        Site.instance&.directory_image&.url(:medium) || "https://via.placeholder.com/400?text=#{account.cname}"
      end
    end
  end
end
