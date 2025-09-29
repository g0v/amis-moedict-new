class RemoveContentToDescriptionAndExample < ActiveRecord::Migration[7.2]
  def change
    remove_column :descriptions, :content, :string, limit: 500
    remove_column :examples, :content, :string
  end
end
