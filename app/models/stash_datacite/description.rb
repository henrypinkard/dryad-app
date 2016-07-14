module StashDatacite
  class Description < ActiveRecord::Base
    self.table_name = 'dcs_descriptions'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s

    #%w(Abstract Methods SeriesInformation TableOfContents Other)

    # usage_notes is our special sauce for 'other' which is the real value it would take in datacite.xml

    enum description_type: { abstract: 'abstract', methods: 'methods', usage_notes: 'usage_notes' }

    # scopes for description_type
    scope :type_abstract, -> { where(description_type: 'abstract') }
    scope :type_methods, -> { where(description_type: 'methods') }
    scope :type_usage_notes, -> { where(description_type: 'usage_notes') }
  end
end
