class CreateCommunities < ActiveRecord::Migration[8.1]
  def change
    create_table :communities do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
    add_index :communities, :name
  end
end
