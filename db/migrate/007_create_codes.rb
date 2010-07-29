class CreateCodes < ActiveRecord::Migration
  def self.up
    create_table :codes do |t|
       t.column :Code,   :integer
       t.column :Status, :text
    end
  end

  def self.down
    drop_table :codes
  end
end
