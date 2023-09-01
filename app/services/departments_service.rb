
# A service is required to set up Questioning Authority to return all the
# values, which will be used to populate the selection list, and a single value
# given an id, which will be used to show the value instead of the id on the
# show page.
module DepartmentsService
  mattr_accessor :authority
  @authority = Qa::Authorities::Local.subauthority_for('departments')

  def self.select_all_options
    @authority.all.map do |element|
      [element[:label], element[:id]]
    end
  end

  def self.label(id)
    @authority.find(id).fetch('term')
  end
end