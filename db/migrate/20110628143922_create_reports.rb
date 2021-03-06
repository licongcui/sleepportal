class CreateReports < ActiveRecord::Migration
  def self.up
    create_table :reports do |t|
      t.string :name
      t.integer :user_id
      t.integer :query_id

      t.timestamps
    end
  end

  def self.down
    drop_table :reports
  end
end
