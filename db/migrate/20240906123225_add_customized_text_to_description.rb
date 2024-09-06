class AddCustomizedTextToDescription < ActiveRecord::Migration[7.2]
  def change
    add_column :descriptions, :customized_text, :string, limit: 500
  end
end
