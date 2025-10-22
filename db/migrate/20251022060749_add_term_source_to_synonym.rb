class AddTermSourceToSynonym < ActiveRecord::Migration[7.2]
  def change
    add_column :synonyms, :term_source, :string, limit: 50
  end
end
