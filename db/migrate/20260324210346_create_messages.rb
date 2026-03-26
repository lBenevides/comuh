class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :user, null: false, foreign_key: true
      t.references :community, null: false, foreign_key: true
      t.references :parent_message, foreign_key: { to_table: :messages }, null: true
      t.text :content
      t.string :user_ip
      t.float :ai_sentiment_score

      t.timestamps
    end
  end
end
