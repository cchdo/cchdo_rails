class CreateParameterGroups < ActiveRecord::Migration
  def self.up
    create_table :parameter_groups do |t|
       t.column :group, :text
       t.column :parameters, :text
    end
  end

  def self.down
    drop_table :parameter_groups
  end
end
