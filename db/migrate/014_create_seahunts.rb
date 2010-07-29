class CreateSeahunts < ActiveRecord::Migration
  def self.up
    create_table :seahunts do |t|
    end
  end

  def self.down
    drop_table :seahunts
  end
end
