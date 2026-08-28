class AddAdvancedPollFeatures < ActiveRecord::Migration[7.2]
  def change
    add_column :polls, :multiple, :boolean, null: false, default: false
    add_column :polls, :allow_custom, :boolean, null: false, default: false
    add_column :poll_votes, :custom_value, :string

    remove_index :poll_votes, column: [:poll_id, :user_id]
    add_index :poll_votes, [:poll_id, :user_id, :poll_option_id],
              unique: true, name: 'index_poll_votes_on_poll_user_option'
  end
end
