module V1
  class SafoluAPI < Base
    resources :s do
      params do
        requires :name, type: String, desc: "蔡中涵大辭典詞彙，對應 Term#name"
      end
      get ":name" do
        dictionary = Dictionary.find_by(name: "蔡中涵大辭典")
        term = dictionary.terms.includes(:stem, descriptions: %i[examples synonyms]).find_by(name: params[:name])

        if term.present?
          result = { t: term.lower_name }
          result[:stem] = term.stem.name if term.stem.present?
          result[:tag] = "[疊 #{term.repetition}]" if term.repetition.present?

          result[:h] = []
          result[:h][0] = { d: [] }
          result[:h][0][:name] = term.name if term.lower_name != term.name
          term.descriptions.each do |description|
            description_hash = { f: description.content }
            description_hash[:e] = description.examples.pluck(:content) if description.examples.present?
            description_hash[:s] = description.synonyms.alts.pluck(:content) if description.synonyms.alts.present?
            description_hash[:r] = description.synonyms.refs.pluck(:content) if description.synonyms.refs.present?
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
