# frozen_string_literal: true
FactoryBot.define do
  factory :etd do
    title { ['Full ETD'] }
    advisor { ['Yoda'] }
    committee_member { ['Mace Windu'] }
    contributor { ['Obi Wan Kenobi'] }
    creator { ['The Librarian'] }
    date_created { ['01/23/2021'] }
    degree_discipline { ['Mentor'] }
    degree_grantor { ['The Jedi Council'] }
    degree_level { ['Knight'] }
    degree_name { ['Jedi Knight'] }
    department { ['Jedi'] }
    depositor { 'admin@example.com' }
    description { ['Once a Jedi Knight reached their full potential, they could then become a Jedi Master.'] }
    format { ['Hologram'] }
    identifier { ['Star Wars'] }
    keyword { ['jedi'] }
    language { ['Huttese'] }
    license { ['https://creativecommons.org/licenses/by/4.0/'] }
    publisher { ['Coruscant Weekly'] }
    related_url { ['https://hykucommons.org'] }
    resource_type { ['Dissertation'] }
    rights_statement { ['http://rightsstatements.org/vocab/CNE/1.0/'] }
    source { ['Star Wars Universe'] }
    subject { ['The Force'] }
  end
end
