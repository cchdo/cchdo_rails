class CreateArgoFiles < ActiveRecord::Migration
  def self.up
    create_table :argo_files do |t|
      t.references :user
      t.string :ExpoCode
      t.text :description
      t.boolean :display, :default => false

      # Attachment-fu
      t.integer :size
      t.string :filename
      t.string :content_type

      t.timestamps
    end
  end

  def self.down
    drop_table :argo_files
  end
end
