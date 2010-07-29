class CreateAssignments < ActiveRecord::Migration
  def self.up
    create_table :assignments do |t|
       t.column :ExpoCode, :text
       t.column :project,  :text
       t.column :current_status, :text
       t.column :cchdo_contact, :text
       t.column :data_contact, :text
       t.column :action, :text
       t.column :parameter, :text
       t.column :history, :text
       t.column :changed, :date
       t.column :notes, :text
       t.column :priority, :integer
       t.column :deadline, :date
       t.column :manager, :string
    end
  end

  def self.down
    drop_table :assignments
  end
end
