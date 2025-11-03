class AddRawContentToExampleAndSynonym < ActiveRecord::Migration[7.2]
  def change
    add_column :examples, :content_amis_raw, :string
    add_column :synonyms, :content_raw,      :string

    Example.find_each do |example|
      example.update(content_amis_raw: example.content_amis.gsub(/`|~/, "")) if example.content_amis.present?
    end

    Synonym.find_each do |synonym|
      synonym.update(content_raw: synonym.content.gsub(/`|~/, "")) if synonym.content.present?
    end
  end
end
