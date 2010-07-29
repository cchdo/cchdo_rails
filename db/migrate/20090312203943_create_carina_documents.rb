class CreateCarinaDocuments < ActiveRecord::Migration
  def self.up
    create_table :carina_documents do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :carina_documents
  end
end
