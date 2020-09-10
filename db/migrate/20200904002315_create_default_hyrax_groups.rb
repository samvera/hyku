class CreateDefaultHyraxGroups < ActiveRecord::Migration[5.1]
  def up
    Hyrax::GroupsService.create_default_hyrax_groups
  end

  def down
    Hyrax::GroupsService.destroy_default_hyrax_groups
  end
end
