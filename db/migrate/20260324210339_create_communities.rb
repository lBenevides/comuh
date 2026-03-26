class CreateCommunities < ActiveRecord::Migration[8.1]
  def change
    create_table :communities do |t|
      t.string :name, null: false
      t.text :description

      t.timestamps
    end

    add_index :communities, :name, unique: true
  end
end
