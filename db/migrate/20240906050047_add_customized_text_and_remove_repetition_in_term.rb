# frozen_string_literal: true

class AddCustomizedTextAndRemoveRepetitionInTerm < ActiveRecord::Migration[7.2]
  def change
    change_table :terms, bulk: true do |t|
      t.string :customized_text, limit: 500
      t.remove :repetition, :integer
    end
  end
end
