# Based on https://github.com/samvera/hyrax/issues/4581#issuecomment-843085122

# Monkey-patch to short circuit ActiveModel::Dirty which attempts to load the whole master files ordered list when calling nodes_will_change!
# This leads to a stack level too deep exception when attempting to delete a master file from a media object on the manage files step.
# See https://github.com/samvera/active_fedora/pull/1312/commits/7c8bbbefdacefd655a2ca653f5950c991e1dc999#diff-28356c4daa0d55cbaf97e4269869f510R100-R103
ActiveFedora::Aggregation::ListSource.class_eval do
  def attribute_will_change!(attr)
    return super unless attr == 'nodes'
    attributes_changed_by_setter[:nodes] = true
  end
end
