module V1
  class PoinsotAPI < Base
    resources :m do
      params do
        requires :name, type: String, desc: "博利亞潘世光阿法字典詞彙，對應 Term#name"
      end
      get ":name" do
        dictionary = Dictionary.find_by(name: "博利亞潘世光阿法字典")
        term = dictionary.terms.includes(:stem, descriptions: %i[examples synonyms]).find_by(name: params[:name])

        if term.present?
          result = { t: term.lower_name }
          result[:stem] = term.stem.name if term.stem.present?

          result[:h] = []
          result[:h][0] = { d: [] }
          result[:h][0][:name] = term.name if term.lower_name != term.name
          term.descriptions.each do |description|
            description_hash = { f: description.content }
            description_hash[:e] = description.examples.map(&:content) if description.examples.present?
            description_hash[:s] = description.synonyms.alts.map(&:content) if description.synonyms.alts.present?
            description_hash[:type] = description.description_type if description.description_type.present?
            result[:h][0][:d] << description_hash
          end

          result
        else
          { term: :not_found }
        end
      end
    end
  end
end
