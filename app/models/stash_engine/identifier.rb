module StashEngine
  class Identifier < ActiveRecord::Base
    belongs_to :resource
  end
end
