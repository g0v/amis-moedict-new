# frozen_string_literal: true

class AddDescriptionTypeToDescription < ActiveRecord::Migration[7.1]
  def change
    add_column :descriptions, :description_type, :string, limit: 3
  end
end
