class AddGlossaryInDescription < ActiveRecord::Migration[7.2]
  def change
    change_table :descriptions, bulk: true do |t|
      t.string :glossary_serial, limit: 10
      t.string :glossary_level,  limit: 10

      t.index :glossary_serial
      t.index :glossary_level
    end
  end
end
