# frozen_string_literal: true

namespace :import do
  desc '字典列表'
  task dictionaries: :environment do
    [
      ['蔡中涵大辭典', '海岸阿美語'],
      ['博利亞潘世光阿法字典', '秀姑巒阿美語'],
      ['方敏英字典', '秀姑巒阿美語'],
      ['學習詞表－秀姑巒阿美語', '秀姑巒阿美語'],
      ['學習詞表－海岸阿美語', '海岸阿美語'],
      ['學習詞表－馬蘭阿美語', '馬蘭阿美語'],
      ['學習詞表－恆春阿美語', '恆春阿美語'],
      ['學習詞表－南勢阿美語', '南勢阿美語'],
      ['原住民族語言線上辭典', '秀姑巒阿美語']
    ].each do |name, dialect|
      Dictionary.find_or_create_by(name:, dialect:)
    end
  end

  desc '從 g0v/amis-moedict 下的 docs/s 檔案匯入蔡中涵大辭典'
  task safolu: :environment do
    dictionary = Dictionary.find_by(name: '蔡中涵大辭典')

    total = Dir.glob('tmp/dict/s/*.json').size
    Dir.glob('tmp/dict/s/*.json').each_with_index do |filename, num|
      puts "#{num}/#{total}" if (num % 500).zero?
      # puts filename
      file = File.read(filename)
      next if file.blank?

      json = JSON.parse(file)
      next if !json.is_a?(Hash) || json['t'].blank?

      json['h'].each { |el| el.delete('name') if el['name'].blank? }

      term_upper_name = json['h'].pluck('name').uniq.join
      if term_upper_name.present?
        json_with_upper_name = {}
        json_with_upper_name['t'] = term_upper_name
        json_with_upper_name['stem'] = json['stem'] if json['stem'].present?
        json_with_upper_name['h'] = json['h'].select { |el| el.key?('name') }

        json['h'].delete_if { |el| el.key?('name') }
        json_with_upper_name['h'].each { |el| el.delete('name') }
      end

      [json, json_with_upper_name].compact.each do |json_object|
        next if json_object['h'].empty?

        term = dictionary.terms.find_or_create_by(name: clean(text: json_object['t']))
        if json_object['stem'].present?
          stem = Stem.find_or_create_by(name: json_object['stem'])
          term.update(stem_id: stem.id)
        end

        json_object['descriptions'] = []
        json_object['h'].each { |h| json_object['descriptions'] += h['d'] }
        json_object['descriptions'].each_with_index do |description_hash, i|
          description = term.descriptions[i].presence || term.descriptions.create

          description.update(content: clean(text: description_hash['f']))

          if description_hash['e'].present?
            description_hash['e'].each_with_index do |example_content, j|
              example = description.examples[j].presence || description.examples.create
              example.update(content: clean(text: example_content))
            end
          end

          if description_hash['r'].present?
            description_hash['r'].each_with_index do |reference_content, x|
              reference = description.synonyms[x].presence || description.synonyms.create
              reference.update(content: clean(text: reference_content), term_type: '參見')
            end
          end

          next if description_hash['s'].blank?

          description_hash['s'].each_with_index do |synonym_content, k|
            synonym = description.synonyms[k].presence || description.synonyms.create
            synonym.update(content: clean(text: synonym_content), term_type: '同')
          end
        end
      end
    end
  end

  desc '從 g0v/amis-moedict 下的 docs/m 檔案匯入博利亞潘世光阿法字典'
  task poinsot: :environment do
    dictionary = Dictionary.find_by(name: '博利亞潘世光阿法字典')

    Dir.glob('tmp/dict/m/*.json').each do |filename|
      # puts filename
      file = File.read(filename)
      next if file.blank?

      json = JSON.parse(file)
      next if !json.is_a?(Hash) || json['t'].blank?

      term = dictionary.terms.find_or_create_by(name: clean(text: json['t']))

      heteronym = json['h'][0]
      heteronym['d'].each_with_index do |description_hash, i|
        description = term.descriptions[i].presence || term.descriptions.create

        description.update(content: clean(text: description_hash['f']),
                           description_type: description_hash['type'])

        if description_hash['e'].present?
          description_hash['e'].each_with_index do |example_content, j|
            example = description.examples[j].presence || description.examples.create
            example.update(content: clean(text: example_content))
          end
        end

        next if description_hash['s'].blank?

        description_hash['s'].each_with_index do |synonym_content, k|
          synonym = description.synonyms[k].presence || description.synonyms.create
          synonym.update(content: clean(text: synonym_content), term_type: '同')
        end
      end
    end
  end

  desc '從 g0v/amis-moedict 下的 docs/p 檔案匯入方敏英字典'
  task fay: :environment do
    dictionary = Dictionary.find_by(name: '方敏英字典')

    Dir.glob('tmp/dict/p/*.json').each do |filename|
      # puts filename
      file = File.read(filename)
      next if file.blank?

      json = JSON.parse(file)
      next if !json.is_a?(Hash) || json['t'].blank?

      term = dictionary.terms.find_or_create_by(name: clean(text: json['t']))
      if json['stem'].present?
        stem = Stem.find_or_create_by(name: json['stem'])
        term.update(stem_id: stem.id)
      end

      heteronym = json['h'][0]
      heteronym['d'].each_with_index do |description_hash, i|
        description = term.descriptions[i].presence || term.descriptions.create

        description.update(content: clean(text: description_hash['f']))

        if description_hash['e'].present?
          description_hash['e'].each_with_index do |example_content, j|
            example = description.examples[j].presence || description.examples.create
            example.update(content: clean(text: example_content))
          end
        end

        next if description_hash['s'].blank?

        description_hash['s'].each_with_index do |synonym_content, k|
          synonym = description.synonyms[k].presence || description.synonyms.create
          synonym.update(content: clean(text: synonym_content), term_type: '同')
        end
      end
    end
  end
end

def clean(text:)
  text.gsub(/\xEF\xBF\xB9|\xEF\xBB\xBF|\xEF\xBF\xBA|\xEF\xBF\xBB/, '').strip
end
