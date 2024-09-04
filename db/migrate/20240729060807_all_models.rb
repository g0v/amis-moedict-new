# frozen_string_literal: true

class AllModels < ActiveRecord::Migration[7.1]
  def change
    create_table :terms do |t|
      t.integer :dictionary_id
      t.integer :stem_id
      t.string  :name
      t.string  :lower_name
      t.integer :repetition
      t.timestamps

      t.index :dictionary_id
      t.index :stem_id
      t.index :name
      t.index :lower_name
    end

    create_table :stems do |t|
      t.string :name, limit: 40
      t.timestamps

      t.index :name, unique: true
    end

    create_table :descriptions do |t|
      t.integer :term_id
      t.string  :content, limit: 500
      t.timestamps

      t.index :term_id
    end

    create_table :examples do |t|
      t.integer :description_id
      t.string  :content
      t.string  :content_zh
      t.timestamps

      t.index :description_id
    end

    create_table :synonyms do |t|
      t.integer :description_id
      t.string  :term_type, limit: 5
      t.string  :content
      t.timestamps

      t.index :description_id
    end
  end
end
