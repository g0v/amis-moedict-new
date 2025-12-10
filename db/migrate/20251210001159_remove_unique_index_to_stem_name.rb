class RemoveUniqueIndexToStemName < ActiveRecord::Migration[7.2]
  def change
    remove_index :stems, :name
    add_index :stems, :name
  end
end
