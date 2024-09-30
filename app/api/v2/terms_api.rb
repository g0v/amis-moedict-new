module V2
  class TermsAPI < Base
    resources :terms do
      params do
        requires :name, type: String, desc: "所有字典的詞彙，對應 Term#name"
      end
      get ":name" do
        terms = Term.includes(:dictionary, :stem, descriptions: %i[examples synonyms])
                    .where(name: params[:name])
                    .order(:dictionary_id)

        if terms.exists?
          result = []

          terms.each do |term|
            term_hash = {
              dictionary:   term.dictionary.name,
              dialect:      term.dictionary.dialect,
              name:         term.name,
              is_stem:      term.is_stem,
              descriptions: []
            }

            term_hash[:stem] = term.stem.name if term.stem.present?
            term_hash[:lower_name] = term.lower_name if term.name != term.lower_name
            term_hash[:repetition] = term.repetition if term.repetition.present?
            term_hash[:audio] = term.audio_url

            term.descriptions.each do |description|
              description_hash = {
                content: description.content
              }
              description_hash[:type] = description.description_type if description.description_type.present?
              description_hash[:glossary_serial] = description.glossary_serial if description.glossary_serial.present?
              description_hash[:glossary_level] = description.glossary_level if description.glossary_level.present?
              description_hash[:image1] = description.image1_url
              description_hash[:image2] = description.image2_url
              description_hash[:image3] = description.image3_url

              description.examples.each do |example|
                example_hash = { content: example.content }
                example_hash[:content_zh] = example.content_zh if example.content_zh.present?

                description_hash[:examples] ||= []
                description_hash[:examples] << example_hash
              end

              description.synonyms.each do |synonym|
                synonym_hash = {
                  term_type: synonym.term_type,
                  content:   synonym.content
                }

                description_hash[:synonyms] ||= []
                description_hash[:synonyms] << synonym_hash
              end

              term_hash[:descriptions] << description_hash
            end

            result << term_hash
          end

          result
        else
          { term: :not_found }
        end
      end
    end
  end
end
