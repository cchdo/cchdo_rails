class SubmissionStatistics < ActiveRecord::Migration
  def self.up
    add_column :submissions, :ip, :string
    add_column :submissions, :user_agent, :text
  end

  def self.down
    remove_column :submissions, :ip
    remove_column :submissions, :user_agent
  end
end
