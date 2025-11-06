class AddTermsCountToDictionary < ActiveRecord::Migration[7.2]
  def change
    add_column :dictionaries, :terms_count, :integer, default: 0
    add_index  :dictionaries, :terms_count

    Dictionary.includes(:terms).find_each do |dictionary|
      dictionary.update(terms_count: dictionary.terms.count)
    end
  end
end
