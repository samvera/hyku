Bulkrax::Importer.class_eval do
  # NOTE(bkiahstroud): Method to add memberships. Currently, only used by the OerCsvParser.
  def create_memberships
    parser.create_memberships if parser.respond_to?(:create_memberships)
  end
end
