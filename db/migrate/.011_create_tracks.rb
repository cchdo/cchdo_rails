class CreateTracks < ActiveRecord::Migration
  def self.up
    create_table :tracks do |t|
       t.column "ExpoCode", :string
       t.column "FileName", :string
       t.column "Basin", :string
       t.column "Track", :text
    end
  end

  def self.down
    drop_table :tracks
  end
end
