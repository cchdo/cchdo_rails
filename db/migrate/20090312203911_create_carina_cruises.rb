class CreateCarinaCruises < ActiveRecord::Migration
  def self.up
    create_table :carina_cruises do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :carina_cruises
  end
end
