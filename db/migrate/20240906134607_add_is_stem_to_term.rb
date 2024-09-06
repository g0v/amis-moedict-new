class AddIsStemToTerm < ActiveRecord::Migration[7.2]
  def change
    add_column :terms, :is_stem, :boolean, default: false
  end
end
