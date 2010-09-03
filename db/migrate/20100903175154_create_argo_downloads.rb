class CreateArgoDownloads < ActiveRecord::Migration
  def self.up
    create_table :argo_downloads, :id => false do |t|
      t.references :file, :null => false
      t.timestamp :created_at, :null => false
      t.string :ip, :null => false
    end
  end

  def self.down
    drop_table :argo_downloads
  end
end
