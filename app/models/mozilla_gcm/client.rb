module MozillaGCM
  class Client < ActiveRecord::Base
    belongs_to :category
    validates :name, :namespace, :category, presence: true
    validates :namespace, uniqueness: true
  end
end
