class FixParentMessageReferenceOnMessages < ActiveRecord::Migration[8.1]
  def up
    if foreign_key_exists?(:messages, column: :parent_message_id)
      remove_foreign_key :messages, column: :parent_message_id
    end

    change_column_null :messages, :parent_message_id, true
    add_foreign_key :messages, :messages, column: :parent_message_id
  end

  def down
    remove_foreign_key :messages, column: :parent_message_id if foreign_key_exists?(:messages, :messages, column: :parent_message_id)
    change_column_null :messages, :parent_message_id, false
  end
end
