# frozen_string_literal: true

class AllModels < ActiveRecord::Migration[7.1]
  def change
    create_table :terms do |t|
      t.integer :stem_id
      t.string  :name
      t.string  :lower_name
      t.integer :repetition
      t.boolean :loanword, default: false, null: false
      t.timestamps

      t.index :stem_id
      t.index :name, unique: true
      t.index :lower_name
      t.index :loanword
    end

    create_table :stems do |t|
      t.string :name, limit: 40
      t.timestamps

      t.index :name, unique: true
    end

    create_table :definitions do |t|
      t.integer :term_id
      t.timestamps

      t.index :term_id
    end

    create_table :descriptions do |t|
      t.integer :definition_id
      t.integer :term_id
      t.string  :content, limit: 500
      t.timestamps

      t.index :term_id
      t.index :definition_id
    end

    create_table :examples do |t|
      t.integer :description_id
      t.string  :content
      t.string  :linked_content, limit: 500
      t.timestamps

      t.index :description_id
    end

    create_table :synonyms do |t|
      t.integer :description_id
      t.string  :term_type, limit: 5
      t.string  :content
      t.string  :linked_content
      t.timestamps

      t.index :description_id
    end
  end
end
