class Contact < ActiveRecord::Base
  has_many :contact_cruises
  has_many :cruises, :through => :contact_cruises

  def name
    "#{self.FirstName} #{self.LastName}"
  end
end
