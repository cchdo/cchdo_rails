class Contact < ActiveRecord::Base
  has_many :contact_cruises
  has_many :cruises, :through => :contact_cruises
end
