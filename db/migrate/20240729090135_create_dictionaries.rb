# frozen_string_literal: true

class CreateDictionaries < ActiveRecord::Migration[7.1]
  def change
    create_table :dictionaries do |t|
      t.string :name, limit: 50
      t.string :dialect, limit: 15
      t.timestamps
    end

    create_table :dictionary_terms do |t|
      t.integer :dictionary_id
      t.integer :term_id
      t.timestamps

      t.index %i[dictionary_id term_id], unique: true
    end
  end
end
