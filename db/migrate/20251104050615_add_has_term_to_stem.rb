class AddHasTermToStem < ActiveRecord::Migration[7.2]
  def change
    add_column :stems, :has_term, :boolean, default: false
    add_index  :stems, :has_term

    Stem.find_each do |stem|
      stem.save
    end
  end
end
