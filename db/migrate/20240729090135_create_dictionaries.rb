# frozen_string_literal: true

class CreateDictionaries < ActiveRecord::Migration[7.1]
  def change
    create_table :dictionaries do |t|
      t.string :name, limit: 50
      t.string :dialect, limit: 15
      t.timestamps
    end

    add_column :terms, :dictionary_id, :integer
    add_index  :terms, :dictionary_id
  end
end
