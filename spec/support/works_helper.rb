module WorksHelper
  def process_through_actor_stack(curation_concern, depositor, admin_set_id, visibility)
    login_as depositor

    attributes_for_actor = {}
    attributes_for_actor.merge!({ admin_set_id: admin_set_id }) if admin_set_id
    attributes_for_actor.merge!({ visibility: visibility }) if visibility
    actor_env = Hyrax::Actors::Environment.new(curation_concern, depositor.ability, attributes_for_actor)
    Hyrax::CurationConcern.actor.create(actor_env)

    curation_concern.reload
  end
end
