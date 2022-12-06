IiifPrint.config do |config|
  # 'publication_unique_id' configs used for Chronicling America style linking
  #  e.g. First page of an issue from publication with LCCN sn86069873, from Jan. 15, 1897
  # https://host/newspapers/sn86069873/1897-01-15/ed-1/seq-1
  # the property that represents a unique identifier for a NewspaperTitle
  # defaults to :lccn
  # config.publication_unique_id_property = :lccn

  # the Solr field that represents a unique identifier for a NewspaperTitle
  # defaults to 'lccn_tesim'
  # config.publication_unique_id_field = 'lccn_tesim'
end
