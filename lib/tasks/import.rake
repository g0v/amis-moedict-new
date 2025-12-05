# frozen_string_literal: true

namespace :import do
  desc "字典列表"
  task dictionaries: :environment do
    [
      [ "蔡中涵大辭典", "" ],
      [ "博利亞潘世光阿法字典", "" ],
      [ "方敏英字典", "" ],
      [ "學習詞表－秀姑巒阿美語", "秀姑巒阿美語" ],
      [ "學習詞表－海岸阿美語", "海岸阿美語" ],
      [ "學習詞表－馬蘭阿美語", "馬蘭阿美語" ],
      [ "學習詞表－恆春阿美語", "恆春阿美語" ],
      [ "學習詞表－南勢阿美語", "南勢阿美語" ],
      [ "原住民族語言線上辭典", "" ]
    ].each do |name, dialect|
      Dictionary.find_or_create_by(name: name, dialect: dialect)
    end
  end

  desc "從 g0v/amis-moedict 下的 docs/s 檔案匯入蔡中涵大辭典"
  task safolu: :environment do
    debug = false

    if debug
      latest_term_id = Term.last.id
      latest_stem_id = Stem.last.id
      latest_description_id = Description.last.id
      latest_example_id = Example.last.id
      latest_synonym_id = Synonym.last.id
    end

    dictionary = Dictionary.find_by(name: "蔡中涵大辭典")

    total = Dir.glob("tmp/dict/s/*.json").size
    Dir.glob("tmp/dict/s/*.json").each_with_index do |filename, num|
      puts "#{num}/#{total}" if (num % 500).zero?
      # puts filename
      file = File.read(filename)
      next if file.blank?

      json = JSON.parse(file)
      next if !json.is_a?(Hash) || json["t"].blank?

      json["h"].each { |el| el.delete("name") if el["name"].blank? }

      json["t"] = json["t"].strip
      term_upper_name = json["h"].pluck("name").uniq.join
      if term_upper_name.present?
        json_with_upper_name = {}
        json_with_upper_name["t"] = term_upper_name
        json_with_upper_name["stem"] = json["stem"] if json["stem"].present?
        json_with_upper_name["h"] = json["h"].select { |el| el.key?("name") }

        json["h"].delete_if { |el| el.key?("name") }
        json_with_upper_name["h"].each { |el| el.delete("name") }
      end

      [ json, json_with_upper_name ].compact.each do |json_object|
        next if json_object["h"].empty?

        term = dictionary.terms.find_or_create_by(name: json_object["t"])
        binding.irb if debug && term.id > latest_term_id

        if json_object["tag"].present?
          repetition = json_object["tag"].match(/[疊 ](\d)/)[1]
          term.update(repetition: repetition)
          binding.irb if debug && term.saved_changes.present?
        end

        if json_object["stem"].present?
          stem = Stem.find_or_create_by(name: json_object["stem"])
          binding.irb if debug && stem.id > latest_stem_id

          term.update(stem_id: stem.id)
          binding.irb if debug && term.saved_changes.present?
        end

        json_object["descriptions"] = []
        json_object["h"].each { |h| json_object["descriptions"] += h["d"] }
        json_object["descriptions"].each_with_index do |description_hash, i|
          description = term.descriptions[i].presence || term.descriptions.create

          # 確認 description_hash["f"] 不含 U+FFF8,9,A,B,F
          description.update(content_zh: description_hash["f"])
          puts description.errors.inspect if description.errors.present?
          binding.irb if debug && description.id > latest_description_id
          binding.irb if debug && description.saved_changes.present?

          if description_hash["e"].present?
            description_hash["e"].select! do |example_content|
              example_content.present?
            end
            description_hash["e"].each_with_index do |example_content, j|
              example = description.examples[j].presence || description.examples.create

              # 確認 example_content 含有 U+FFF9,A,B
              parsed_example = parse_multilingual(example_content)
              if parsed_example[:amis].present?
                parsed_example[:amis] = parsed_example[:amis].gsub(/`|~/, "").strip
                if example.content_amis.present?
                  example.update(
                    content_amis_raw: parsed_example[:amis],
                    content_zh: parsed_example[:chinese]
                  )
                else
                  example.update(
                    content_amis: parsed_example[:amis],
                    content_amis_raw: parsed_example[:amis],
                    content_zh: parsed_example[:chinese]
                  )
                end
                puts example.errors.inspect if example.errors.present?
                binding.irb if debug && example.id > latest_example_id
                binding.irb if debug && example.saved_changes.present?
              end
            end
          end

          if description_hash["r"].present?
            description_hash["r"].each_with_index do |reference_content, x|
              reference = description.synonyms.refs[x].presence || description.synonyms.create

              # 確認 reference_content 不含 U+FFF8,9,A,B,F
              reference_content = reference_content.gsub(/`|~/, "").strip
              if reference_content.present?
                if reference.content.present?
                  reference.update(content_raw: reference_content,
                                   term_type: "參見")
                else
                  reference.update(content_raw: reference_content,
                                   content: reference_content,
                                   term_type: "參見")
                end
                puts reference.errors.inspect if reference.errors.present?
                binding.irb if debug && reference.id > latest_synonym_id
                binding.irb if debug && reference.saved_changes.present?
              end
            end
          end

          next if description_hash["s"].blank?

          description_hash["s"].each_with_index do |synonym_content, k|
            synonym = description.synonyms.alts[k].presence || description.synonyms.create

            # 確認 synonym_content 不含 U+FFF8,9,A,B,F
            synonym_content = synonym_content.gsub(/`|~/, "").strip
            if synonym_content.present?
              if synonym.content.present?
                synonym.update(content_raw: synonym_content,
                               term_type: "同")
              else
                synonym.update(content_raw: synonym_content,
                               content: synonym_content,
                               term_type: "同")
              end
              puts synonym.errors.inspect if synonym.errors.present?
              binding.irb if debug && synonym.id > latest_synonym_id
              binding.irb if debug && synonym.saved_changes.present?
            end
          end
        end
      end
    end
  end

  desc "從 g0v/amis-moedict 下的 docs/m 檔案匯入博利亞潘世光阿法字典"
  task poinsot: :environment do
    dictionary = Dictionary.find_by(name: "博利亞潘世光阿法字典")

    Dir.glob("tmp/dict/m/*.json").each do |filename|
      # puts filename
      file = File.read(filename)
      next if file.blank?

      json = JSON.parse(file)
      next if !json.is_a?(Hash) || json["t"].blank?

      term = dictionary.terms.find_or_create_by(name: json["t"])

      heteronym = json["h"][0]
      heteronym["d"].each_with_index do |description_hash, i|
        description = term.descriptions[i].presence || term.descriptions.create

        # 確認 description_hash["f"] 不含 U+FFF8,9,A,B,F
        description.update(content_fr:       description_hash["f"],
                           description_type: description_hash["type"])

        if description_hash["e"].present?
          description_hash["e"].each_with_index do |example_content, j|
            example = description.examples[j].presence || description.examples.create

            # 確認 example_content 含有 U+FFF9,B
            parsed_example = parse_multilingual(example_content)
            example.update(
              content_amis: parsed_example[:amis],
              content_fr:   parsed_example[:chinese]
            )
          end
        end

        next if description_hash["s"].blank?

        description_hash["s"].each_with_index do |synonym_content, k|
          synonym = description.synonyms[k].presence || description.synonyms.create

          # 確認 synonym_content 不含 U+FFF8,9,A,B,F
          synonym.update(content: synonym_content, term_type: "同")
        end
      end
    end
  end

  desc "從 g0v/amis-moedict 下的 docs/p 檔案匯入方敏英字典"
  task fey: :environment do
    dictionary = Dictionary.find_by(name: "方敏英字典")

    Dir.glob("tmp/dict/p/*.json").each do |filename|
      # puts filename
      file = File.read(filename)
      next if file.blank?

      json = JSON.parse(file)
      next if !json.is_a?(Hash) || json["t"].blank?

      term = dictionary.terms.find_or_create_by(name: json["t"])
      if json["stem"].present?
        stem = Stem.find_or_create_by(name: json["stem"])
        term.update(stem_id: stem.id)
      end

      heteronym = json["h"][0]
      heteronym["d"].each_with_index do |description_hash, i|
        description = term.descriptions[i].presence || term.descriptions.create

        # 確認 description_hash["f"] 含有 U+FFF9,A,B
        parsed_description = parse_multilingual(description_hash["f"])
        description.update(
          content_en: parsed_description[:english],
          content_zh: parsed_description[:chinese]
        )

        if description_hash["e"].present?
          description_hash["e"].each_with_index do |example_content, j|
            example = description.examples[j].presence || description.examples.create

            # 確認 example_content 含有 U+FFF9,A,B
            parsed_example = parse_multilingual(example_content)
            example.update(
              content_amis: parsed_example[:amis],
              content_en:   parsed_example[:english],
              content_zh:   parsed_example[:chinese]
            )
          end
        end

        next if description_hash["s"].blank?

        description_hash["s"].each_with_index do |synonym_content, k|
          synonym = description.synonyms[k].presence || description.synonyms.create

          # 確認 synonym_content 不含 U+FFF8,9,A,B,F
          synonym.update(content: synonym_content, term_type: "同")
        end
      end
    end
  end

  desc "從 https://glossary.ilrdf.org.tw/resources 學習詞表匯入"
  task glossary: :environment do
    %w[
      南勢阿美語
      秀姑巒阿美語
      海岸阿美語
      馬蘭阿美語
      恆春阿美語
    ].each_with_index do |dict_name, i|
      puts dict_name
      dictionary = Dictionary.find_by(name: "學習詞表－#{dict_name}")

      CSV.foreach("tmp/dict/2022學習詞表-0#{i+1}#{dict_name}.csv") do |row|
        id, serial, description_content, term_names, note_content, level = row
        next if id == "類別"

        term_names.split("/").each do |term_name|
          term_name.strip!
          next if term_name == "無此詞彙"

          term_name.gsub!("’", "'")
          term = dictionary.terms.find_or_create_by(name: term_name)

          description = term.descriptions.find_or_create_by(glossary_serial: serial)
          content = if note_content.present?
                      [ description_content, note_content ].join("\n")
                    else
                      description_content
                    end
          description.update(content_zh: content, glossary_level: level)
        end
      end
    end
  end

  desc "從 ilrdf.txt 匯入"
  task ilrdf: :environment do
    file = File.read("tmp/dict/ilrdf.txt").split("\n")
    file.each do |f|
      # 確認 f 不含 U+FFF8,9,A,B,F
      hash = eval(f)
      data = hash["GenericData"]["DATA"]

      if data.is_a? Array
        data.each do |datum|
          ilref_hash(datum)
        end
      end

      if data.is_a? Hash
        ilref_hash(data)
      end
    end
  end

  desc "從 tmp/dict/pourrias-poinsot.txt 檔案匯入博利亞潘世光阿漢字典"
  task pourrias_poinsot: :environment do
    dictionary = Dictionary.find_or_create_by(name: "博利亞潘世光阿漢字典")

    file_path = "tmp/dict/pourrias-poinsot.txt"
    unless File.exist?(file_path)
      puts "找不到博利亞潘世光阿漢字典檔案: #{file_path}"
      exit
    end

    parser = PoinsotDictionaryParser.new
    total = File.read(file_path).count($/)

    File.foreach(file_path).each_with_index do |line, num|
      puts "#{num}/#{total}" if (num % 500).zero?

      # 確認 line 不含 U+FFF8,9,A,B,F
      next if line.blank?

      if line.exclude?("<")
        # 一個冒號和多個冒號的處理差很多
        if line.count("：") == 1
          results = parser.parse_line(line)

          results.each do |entry|
            # 先用特殊情況處理，針對開頭是(的 term，把 ()- 都刪除
            entry[:term].gsub!(/\(|\)|-/, "") if entry[:term][0] == "("

            term = dictionary.terms.find_or_create_by(name: entry[:term])
            if entry[:dialects].present?
              term.update(dialects: entry[:dialects].join("、"))
            end

            if entry[:stem].present?
              stem = Stem.find_or_create_by(name: entry[:stem])
              term.update(stem_id: stem.id)
            end

            if entry[:description].present? ||
               entry[:examples].present? ||
               entry[:synonyms].present?
              description_content = entry[:description].join("；")
              description = term.descriptions.find_or_create_by(content_zh: description_content)

              if entry[:examples].present?
                entry[:examples].each_with_index do |example_hash, i|
                  example = description.examples[i].presence || description.examples.create
                  example.update(
                    content_amis: example_hash[:amis],
                    content_zh:   example_hash[:zh]
                  )
                end
              end

              if entry[:synonyms].present?
                entry[:synonyms].each_with_index do |synonym_content, j|
                  synonym = description.synonyms.alts[j].presence || description.synonyms.create
                  synonym.update(content: synonym_content, term_type: "同")
                end
              end
            end
          end
        end
      end
    end
  end

  desc "從 tmp/dict/namoh-json 檔案匯入吳明義阿美族語辭典"
  task namoh: :environment do
    dictionary = Dictionary.find_or_create_by(name: "吳明義阿美族語辭典")

    total = Dir.glob("tmp/dict/namoh-json/*.json").size
    Dir.glob("tmp/dict/namoh-json/*.json").each_with_index do |filename, num|
      puts "#{num}/#{total}" if (num % 5000).zero?

      file = File.read(filename)
      json_object = JSON.parse(file)
      json_object["term_source"] = json_object["term_source"].split(".").map(&:strip).compact.join("|") if json_object["term_source"].present?

      term = get_namoh_term(json_object)

      json_object["h"].each do |heteronym|
        heteronym["d"].each do |description_hash|
          description = term.descriptions.find_or_create_by(content_zh: description_hash["f"])

          if description_hash["e"].present?
            description_hash["e"].select! do |example_content|
              example_content.present?
            end
            description_hash["e"].each do |example_content|
              example = description.examples.find_or_create_by(content_amis: example_content["amis"], content_zh: example_content["zh"])
            end
          end

          next if description_hash["s"].blank?

          description_hash["s"].each do |synonym_hash|
            synonym_hash["term_source"] = synonym_hash["term_source"].split(".").map(&:strip).compact.join("|") if synonym_hash["term_source"].present?
            synonym = description.synonyms.find_or_create_by(content: synonym_hash["name"], term_source: synonym_hash["term_source"], term_type: "同")

            synonym_hash["t"] = synonym_hash["name"]
            synonym_term = get_namoh_term(synonym_hash)
            synonym_description = synonym_term.descriptions.find_or_create_by(content_zh: description_hash["f"])
            synonym_synonym = synonym_description.synonyms.find_or_create_by(content: term.name, term_source: term.term_source, term_type: "同")
          end
        end
      end
    end
  end
end

# https://github.com/miaoski/amis-safolu/blob/master/generate-moedict-json.rb#L37-L41
# 根據萌典說明U+FFF9,A,B，拆分不同語言
def parse_multilingual(text)
  return { amis: nil, english: nil, chinese: nil } if text.blank?

  amis_marker = "\ufff9"
  english_marker = "\ufffa"
  chinese_marker = "\ufffb"

  result = { amis: nil, english: nil, chinese: nil }

  # Split by any language marker to get segments
  segments = text.split(/[\ufff9\ufffa\ufffb]/)

  amis_pos = text.index(amis_marker)
  english_pos = text.index(english_marker)
  chinese_pos = text.index(chinese_marker)

  if amis_pos
    next_pos = [ english_pos, chinese_pos ].compact.select { |p| p > amis_pos }.min || text.length
    result[:amis] = text[(amis_pos + 1)...next_pos].strip
  end

  if english_pos
    next_pos = [ amis_pos, chinese_pos ].compact.select { |p| p > english_pos }.min || text.length
    result[:english] = text[(english_pos + 1)...next_pos].strip
  end

  if chinese_pos
    next_pos = [ amis_pos, english_pos ].compact.select { |p| p > chinese_pos }.min || text.length
    result[:chinese] = text[(chinese_pos + 1)...next_pos].strip
  end

  # 都找不到時，以 amis 返回原文
  if !amis_pos && !english_pos && !chinese_pos
    puts "找不到 U+FFF9,A,B"
    result[:amis] = text
  end

  # Clean up any remaining markers from the extracted content
  result.each do |key, value|
    if value
      puts "U+FFF8: #{value}" if value.include?("\ufff8")
      puts "U+FFF9: #{value}" if value.include?("\ufff9")
      puts "U+FFFA: #{value}" if value.include?("\ufffa")
      puts "U+FFFB: #{value}" if value.include?("\ufffb")
      result[key] = value.gsub(/[\ufff9\ufffa\ufffb]/, "").strip
      result[key] = nil if result[key].blank?
    end
  end

  result
end

def ilref_hash(data)
  dictionary = Dictionary.find_by(name: "原住民族語言線上辭典")

  data["Name"] = data["Name"].sub(/1|2/, "").strip
  term = dictionary.terms.find_or_create_by(name: data["Name"])
  term.variant = data["Variant"].strip if data["Variant"].present?

  if data["Frequency"].present?
    if term.frequency.to_i < data["Frequency"].to_i
      term.frequency = data["Frequency"]
    end
  end

  if data["File"].present? && data["File"]["Path"].present?
    if data["File"]["Path"] == "https://e-dictionary.ilrdf.org.tw/MultiMedia/Audio/ami/matayalay_{1}.mp3"
      data["File"]["Path"] = "https://e-dictionary.ilrdf.org.tw/MultiMedia/Audio/ami/Matayalay_{1}.mp3"
    end
    if data["File"]["Path"] == "https://e-dictionary.ilrdf.org.tw/MultiMedia/Audio/ami/anini_{1}.mp3"
      data["File"]["Path"] = "https://e-dictionary.ilrdf.org.tw/MultiMedia/Audio/ami/Anini_{1}.mp3"
    end
    if data["File"]["Path"] == "https://e-dictionary.ilrdf.org.tw/MultiMedia/Audio/ami/fanaw_{1}.mp3"
      data["File"]["Path"] = "https://e-dictionary.ilrdf.org.tw/MultiMedia/Audio/ami/Fanaw_{1}.mp3"
    end
    if data["File"]["Path"] == "https://e-dictionary.ilrdf.org.tw/MultiMedia/Audio/ami/kolas_{1}.mp3"
      data["File"]["Path"] = "https://e-dictionary.ilrdf.org.tw/MultiMedia/Audio/ami/Kolas_{1}.mp3"
    end
    if data["File"]["Path"] == "https://e-dictionary.ilrdf.org.tw/MultiMedia/Audio/ami/macidal_{1}.mp3"
      data["File"]["Path"] = "https://e-dictionary.ilrdf.org.tw/MultiMedia/Audio/ami/Macidal_{1}.mp3"
    end
    if data["File"]["Path"] == "https://e-dictionary.ilrdf.org.tw/MultiMedia/Audio/ami/malalok_{1}.mp3"
      data["File"]["Path"] = "https://e-dictionary.ilrdf.org.tw/MultiMedia/Audio/ami/Malalok_{1}.mp3"
    end
    if data["File"]["Path"] == "https://e-dictionary.ilrdf.org.tw/MultiMedia/Audio/ami/mamaan_{1}.mp3"
      data["File"]["Path"] = "https://e-dictionary.ilrdf.org.tw/MultiMedia/Audio/ami/Mamaan_{1}.mp3"
    end

    path = data["File"]["Path"].sub("https://e-dictionary.ilrdf.org.tw/MultiMedia/Audio/ami", "")
    if term.audio.blank? || (term.audio.exclude?(path) && %w[cidek cifar feded macahiw cahid].exclude?(data["Name"]))
      term.audio = "/ilrdf/mp3#{path}"
    end
  end

  if data["Note"].is_a? String
    data["Note"].strip!
    if term.note.present?
      term.note += "\n#{data["Note"]}" unless term.note.include?(data["Note"])
    else
      term.note = data["Note"]
    end
  end

  if data["Note"].is_a?(Hash) && data["Note"]["#text"].present?
    if data["Note"]["#text"].is_a? String
      data["Note"]["#text"].strip!
      if term.note.present?
        term.note += "\n#{data["Note"]["#text"]}" unless term.note.include?(data["Note"]["#text"])
      else
        term.note = data["Note"]["#text"]
      end
    end

    if data["Note"]["#text"].is_a? Array
      data["Note"]["#text"].map(&:strip!)
      if term.note.present?
        term.note += "\n#{data["Note"]["#text"].join("\n")}" unless term.note.include?(data["Note"]["#text"][0])
      else
        term.note = data["Note"]["#text"].join("\n")
      end
    end
  end

  if term.changed?
    # binding.irb
    term.save
  end

  # 字典的詞幹（來源）衝突時，以字數少的為主
  if data["Source"].is_a? String
    data["Source"].strip!
    # binding.irb unless Stem.exists?(name: data["Source"])
    stem = Stem.find_or_create_by(name: data["Source"])
    if term.stem.blank?
      term.update(stem_id: stem.id)
    else
      if (term.stem_id != stem.id) && (stem.name.size < term.stem.name.size)
        term.update(stem_id: stem.id)
      end
    end
  end

  if data["Source"].is_a? Hash
    data["Source"]["#text"].strip!
    # binding.irb unless Stem.exists?(name: data["Source"]["#text"])
    stem = Stem.find_or_create_by(name: data["Source"]["#text"])
    if term.stem.blank?
      term.update(stem_id: stem.id)
    else
      if (term.stem_id != stem.id) && (stem.name.size < term.stem.name.size)
        term.update(stem_id: stem.id)
      end
    end
  end

  if data["Explanation"].is_a? Hash
    explanation = data["Explanation"]
    # binding.irb unless term.descriptions.exists?(content_zh: explanation["Chinese"])
    description = term.descriptions.find_or_create_by(content_zh: explanation["Chinese"])

    if explanation["Focus"].present? && description.focus.blank?
      description.focus = explanation["Focus"]
    end

    if explanation["TC"].present? && description.category.blank?
      description.category = explanation["TC"]
    end

    if explanation["Img"].is_a? Hash
      ilrdf_image(description: description, data: explanation["Img"])
    end

    if explanation["Img"].is_a? Array
      explanation["Img"].each_with_index do |img, i|
        ilrdf_image(description: description, data: img)
      end
    end

    if explanation["Sentence"].is_a? Hash
      ilrdf_sentence(description: description, data: explanation["Sentence"])
    end

    if explanation["Sentence"].is_a? Array
      explanation["Sentence"].each do |sentence|
        ilrdf_sentence(description: description, data: sentence)
      end
    end
  end

  if description.present? && description.changed?
    # binding.irb
    description.save
  end

  if data["Explanation"].is_a? Array
    data["Explanation"].each_with_index do |explanation, i|
      # binding.irb unless term.descriptions.exists?(content: explanation["Chinese"])
      description = term.descriptions.find_or_create_by(content: explanation["Chinese"])

      if explanation["Focus"].present? && description.focus.blank?
        description.focus = explanation["Focus"]
      end

      if explanation["TC"].present? && description.category.blank?
        description.category = explanation["TC"]
      end

      if description.changed?
        # binding.irb
        description.save
      end

      if explanation["Img"].is_a? Hash
        ilrdf_image(description: description, data: explanation["Img"])
      end

      if explanation["Img"].is_a? Array
        explanation["Img"].each do |img|
          ilrdf_image(description: description, data: img)
        end
      end

      if explanation["Sentence"].is_a? Hash
        ilrdf_sentence(description: description, data: explanation["Sentence"])
      end

      if explanation["Sentence"].is_a? Array
        explanation["Sentence"].each do |sentence|
          ilrdf_sentence(description: description, data: sentence)
        end
      end
    end
  end
end

def ilrdf_image(description:, data:)
  return if data["Src"] == "https://e-dictionary.ilrdf.org.tw/MultiMedia/"

  count = 3 if description.image3.present? && data["Src"].include?(description.image3.sub("/ilrdf/images", ""))
  count = 2 if count.nil? && description.image2.present? && data["Src"].include?(description.image2.sub("/ilrdf/images", ""))
  count = (description.image1.present? && data["Src"].include?(description.image1.sub("/ilrdf/images", ""))) ? 1 : 0 if count.nil?

  case count
  when 0
    if description.image1.blank?
      description.image1_alt = data["Name"] if data["Name"].present?
      description.image1_provider = data["Provider"] if data["Provider"].present?
      description.image1 = data["Src"].sub("https://e-dictionary.ilrdf.org.tw/MultiMedia/Images", "/ilrdf/images")
    elsif description.image2.blank?
      description.image2_alt = data["Name"] if data["Name"].present?
      description.image2_provider = data["Provider"] if data["Provider"].present?
      description.image2 = data["Src"].sub("https://e-dictionary.ilrdf.org.tw/MultiMedia/Images", "/ilrdf/images")
    elsif description.image3.blank?
      description.image3_alt = data["Name"] if data["Name"].present?
      description.image3_provider = data["Provider"] if data["Provider"].present?
      description.image3 = data["Src"].sub("https://e-dictionary.ilrdf.org.tw/MultiMedia/Images", "/ilrdf/images")
    else
      # binding.irb
    end
  when 1
    if data["Name"].present? && (description.image1_alt != data["Name"])
      # binding.irb
      description.image1_alt = data["Name"]
    end

    if data["Provider"].present? && (description.image1_provider != data["Provider"])
      # binding.irb
      description.image1_provider = data["Provider"]
    end
  when 2
    if data["Name"].present? && (description.image2_alt != data["Name"])
      # binding.irb
      description.image2_alt = data["Name"]
    end

    if data["Provider"].present? && (description.image2_provider != data["Provider"])
      # binding.irb
      description.image2_provider = data["Provider"]
    end
  when 3
    if data["Name"].present? && (description.image3_alt != data["Name"])
      # binding.irb
      description.image3_alt = data["Name"]
    end

    if data["Provider"].present? && (description.image3_provider != data["Provider"])
      # binding.irb
      description.image3_provider = data["Provider"]
    end
  end

  if description.changed?
    # binding.irb
    description.save
  end
end

def ilrdf_sentence(description:, data:)
  if data["Original"].blank?
    if data["File"].present?
      mp3 = data["File"]["Path"].split("/").last

      case mp3
      when "Fanaw_{1}_@_1.1.mp3"
        data["Original"] = "Maolah ko howak a misalama i fanaw."
      when "Fata'an_{1}_@_1.1.mp3"
        data["Original"] = "Mapaloma ko Fata'an i taliyok no loma' niyam."
      when "Rengos_{1}_@_1.1.mp3"
        data["Original"] = "O rengos a maemin ko malengaway i padatengan ni ina."
      end
    else
      if data["Chinese"].blank?
        puts description.id
        puts description.content
        puts "================"
      else

        if data["Chinese"] == "你們要用扁擔平衡扛起豬隻來。"
          data["File"] = { "Path" => "https://e-dictionary.ilrdf.org.tw/MultiMedia/audio/ami/35/midadoy_{1}_@_1.1.mp3" }
          data["Original"] = "Pa'onocen a malalilid to fafoy a midadoy."
        end

      end
    end
  end

  if data["Original"].blank?
    puts description.id
    puts description.content
    puts "================"
    return
  end

  data["Original"] = data["Original"].strip
  example = description.examples.find_or_create_by(content_amis: data["Original"])
  if data["Chinese"].present?
    data["Chinese"].strip!
    example.content_zh = data["Chinese"] if example.content_zh != data["Chinese"]
  end
  example.content = "#{example.content_amis}#{example.content_zh}"
  if data["File"].present? && data["File"]["Path"].present?
    if data["File"]["Path"] == "https://e-dictionary.ilrdf.org.tw/MultiMedia/Audio/ami/anini_{1}_@_1.1.mp3"
      data["File"]["Path"] = "https://e-dictionary.ilrdf.org.tw/MultiMedia/Audio/ami/Anini_{1}_@_1.1.mp3"
    end
    if data["File"]["Path"] == "https://e-dictionary.ilrdf.org.tw/MultiMedia/Audio/ami/fanaw_{1}_@_1.1.mp3"
      data["File"]["Path"] = "https://e-dictionary.ilrdf.org.tw/MultiMedia/Audio/ami/Fanaw_{1}_@_1.1.mp3"
    end
    if data["File"]["Path"] == "https://e-dictionary.ilrdf.org.tw/MultiMedia/Audio/ami/kolas_{1}_@_1.1.mp3"
      data["File"]["Path"] = "https://e-dictionary.ilrdf.org.tw/MultiMedia/Audio/ami/Kolas_{1}_@_1.1.mp3"
    end
    if data["File"]["Path"] == "https://e-dictionary.ilrdf.org.tw/MultiMedia/Audio/ami/macidal_{1}_@_1.1.mp3"
      data["File"]["Path"] = "https://e-dictionary.ilrdf.org.tw/MultiMedia/Audio/ami/Macidal_{1}_@_1.1.mp3"
    end
    if data["File"]["Path"] == "https://e-dictionary.ilrdf.org.tw/MultiMedia/Audio/ami/malalok_{1}_@_1.1.mp3"
      data["File"]["Path"] = "https://e-dictionary.ilrdf.org.tw/MultiMedia/Audio/ami/Malalok_{1}_@_1.1.mp3"
    end
    if data["File"]["Path"] == "https://e-dictionary.ilrdf.org.tw/MultiMedia/Audio/ami/mamaan_{1}_@_1.1.mp3"
      data["File"]["Path"] = "https://e-dictionary.ilrdf.org.tw/MultiMedia/Audio/ami/Mamaan_{1}_@_1.1.mp3"
    end

    path = data["File"]["Path"].split("/").last
    if example.audio.blank? || example.audio.exclude?(path)
      example.audio = "/ilrdf/mp3/#{path}"
    end
  end

  if example.changed?
    # binding.irb
    example.save
  end
end

def get_namoh_term(json_object)
  dictionary = Dictionary.find_by(name: "吳明義阿美族語辭典")

  stem = Stem.find_or_create_by(name: json_object["t"]) if json_object["is_stem"]
  stem = Stem.find_or_create_by(name: json_object["stem"]) if json_object["stem"].present?
  stem = Stem.find_by(name: json_object["t"]) if stem.blank?

  if dictionary.terms.exists?(name: json_object["t"])
    if stem.present? && json_object["term_source"].present?
      term = dictionary.terms.where(name: json_object["t"], stem_id: stem.id).select { |t| t.term_source == json_object["term_source"] }.first
      if term.blank?
        term = dictionary.terms.create(name: json_object["t"], stem_id: stem.id, is_stem: json_object["is_stem"], term_source: json_object["term_source"])
      end
    elsif stem.blank? && json_object["term_source"].blank?
      term = dictionary.terms.where(name: json_object["t"], stem_id: nil).select { |t| t.term_source.blank? }.first
      if term.blank?
        term = dictionary.terms.create(name: json_object["t"], is_stem: json_object["is_stem"])
      end
    else
      if stem.present?
        term = dictionary.terms.where(name: json_object["t"], stem_id: stem.id).select { |t| t.term_source.blank? }.first
        if term.blank?
          term = dictionary.terms.create(name: json_object["t"], stem_id: stem.id, is_stem: json_object["is_stem"])
        end
      end

      if json_object["term_source"].present?
        term = dictionary.terms.where(name: json_object["t"], stem_id: nil).select { |t| t.term_source == json_object["term_source"] }.first
        if term.blank?
          term = dictionary.terms.create(name: json_object["t"], is_stem: json_object["is_stem"], term_source: json_object["term_source"])
        end
      end
    end
  else
    term = dictionary.terms.create(name: json_object["t"], is_stem: json_object["is_stem"])

    if stem.present?
      term.update(stem_id: stem.id)
    end

    if json_object["term_source"].present?
      term.update(term_source: json_object["term_source"])
    end
  end

  term
end
