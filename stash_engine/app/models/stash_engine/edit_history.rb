module StashEngine
  class EditHistory < ActiveRecord::Base
    belongs_to :resource, class_name: 'StashEngine::Resource', foreign_key: 'resource_id'
  end
end