class AddCustomizedTextToExample < ActiveRecord::Migration[7.2]
  def change
    add_column :examples, :customized_text, :string, limit: 500
  end
end
