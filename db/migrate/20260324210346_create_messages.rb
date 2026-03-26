class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :user, null: false, foreign_key: true
      t.references :community, null: false, foreign_key: true
      t.references :parent_message, null: true, foreign_key: { to_table: :messages }
      t.text :content, null: false
      t.string :user_ip, null: false
      t.float :ai_sentiment_score

      t.timestamps
    end
  end
end
