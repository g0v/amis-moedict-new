# frozen_string_literal: true

class CreateDictionaries < ActiveRecord::Migration[7.1]
  def change
    create_table :dictionaries do |t|
      t.string :name, limit: 50
      t.string :dialect, limit: 15
      t.timestamps
    end
  end
end
