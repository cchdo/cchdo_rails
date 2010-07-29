class CreateDocuments < ActiveRecord::Migration
  def self.up
    create_table :documents do |t|
      # t.column :name, :string
      t.column :Size, :text 
      t.column :FileType, :text 
      t.column :FileName, :text 
      t.column :ExpoCode, :text 
      t.column :Files, :text 
      t.column :LastModified, :date 
      t.column :Modified, :text
    end
  end

  def self.down
    drop_table :documents
  end
end
