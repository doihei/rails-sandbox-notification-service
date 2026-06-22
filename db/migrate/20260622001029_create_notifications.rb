class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.bigint :article_id, null: false
      t.text :message, null: false
      t.boolean :read, default: false, null: false
      t.bigint :user_id, null: false

      t.timestamps
    end
    add_index :notifications, :article_id
    add_index :notifications, :user_id
  end
end
