class CreatePolls < ActiveRecord::Migration[7.2]
  def change
    create_table :polls do |t|
      t.integer :project_id, null: false
      t.string :title, null: false
      t.text :description
      t.boolean :is_open, null: false, default: true
      t.integer :created_by_id
      t.timestamps
    end
    add_index :polls, :project_id

    create_table :poll_options do |t|
      t.integer :poll_id, null: false
      t.string :value, null: false
      t.integer :position
    end
    add_index :poll_options, :poll_id

    create_table :poll_votes do |t|
      t.integer :poll_id, null: false
      t.integer :poll_option_id, null: false
      t.integer :user_id, null: false
      t.timestamps
    end
    add_index :poll_votes, [:poll_id, :user_id], unique: true
    add_index :poll_votes, :poll_option_id
  end
end
