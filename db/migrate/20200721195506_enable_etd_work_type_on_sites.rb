class EnableEtdWorkTypeOnSites < ActiveRecord::Migration[5.1]
  def up
    site = Site.first
    return unless site.present? # skip public db
    return unless etd_registered?

    if site.available_works.exclude?('Etd')
      site.available_works << 'Etd'
      site.save!
    end
  end

  def down
    site = Site.first
    return unless site.present? # skip public db
    return unless site.available_works.include?('Etd')

    site.available_works.delete('Etd')
    site.save!
  end

  def etd_registered?
    if Hyrax.config.registered_curation_concern_types.include?('Etd')
      true
    else
      puts "'Etd' is not a work type that exists"
      false
    end
  end
end
