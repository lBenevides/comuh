class CreateReactions < ActiveRecord::Migration[8.1]
  def change
    create_table :reactions do |t|
      t.references :message, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :reaction_type

      t.timestamps
    end

    add_index :reactions, [:message_id, :user_id, :reaction_type], unique: true, name: "index_reactions_on_message_user_and_type"
  end
end
