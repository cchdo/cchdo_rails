class ContactCruise < ActiveRecord::Base
  set_table_name "contacts_cruises"
  belongs_to :contact
  belongs_to :cruise
end

