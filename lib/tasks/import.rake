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

        term = dictionary.terms.find_or_create_by(name: clean(text: json_object["t"]))
        if json_object["tag"].present?
          puts filename if json_object["tag"].match(/[疊 ](\d)/).blank?
          repetition = json_object["tag"].match(/[疊 ](\d)/)[1]
          term.update(repetition: repetition)
        end
        if json_object["stem"].present?
          stem = Stem.find_or_create_by(name: json_object["stem"])
          term.update(stem_id: stem.id)
        end

        json_object["descriptions"] = []
        json_object["h"].each { |h| json_object["descriptions"] += h["d"] }
        json_object["descriptions"].each_with_index do |description_hash, i|
          description = term.descriptions[i].presence || term.descriptions.create
          description.update(content: clean(text: description_hash["f"]))

          if description_hash["e"].present?
            description_hash["e"].select! do |example_content|
              clean(text: example_content).present?
            end
            description_hash["e"].each_with_index do |example_content, j|
              example = description.examples[j].presence || description.examples.create
              example.update(content: clean(text: example_content))
            end
          end

          if description_hash["r"].present?
            description_hash["r"].each_with_index do |reference_content, x|
              reference = description.synonyms.refs[x].presence || description.synonyms.create
              reference.update(content: clean(text: reference_content), term_type: "參見")
            end
          end

          next if description_hash["s"].blank?

          description_hash["s"].each_with_index do |synonym_content, k|
            synonym = description.synonyms.alts[k].presence || description.synonyms.create
            synonym.update(content: clean(text: synonym_content), term_type: "同")
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

      term = dictionary.terms.find_or_create_by(name: clean(text: json["t"]))

      heteronym = json["h"][0]
      heteronym["d"].each_with_index do |description_hash, i|
        description = term.descriptions[i].presence || term.descriptions.create

        description.update(content:          clean(text: description_hash["f"]),
                           description_type: description_hash["type"])

        if description_hash["e"].present?
          description_hash["e"].each_with_index do |example_content, j|
            example = description.examples[j].presence || description.examples.create
            example.update(content: clean(text: example_content))
          end
        end

        next if description_hash["s"].blank?

        description_hash["s"].each_with_index do |synonym_content, k|
          synonym = description.synonyms[k].presence || description.synonyms.create
          synonym.update(content: clean(text: synonym_content), term_type: "同")
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

      term = dictionary.terms.find_or_create_by(name: clean(text: json["t"]))
      if json["stem"].present?
        stem = Stem.find_or_create_by(name: json["stem"])
        term.update(stem_id: stem.id)
      end

      heteronym = json["h"][0]
      heteronym["d"].each_with_index do |description_hash, i|
        description = term.descriptions[i].presence || term.descriptions.create

        description.update(content: clean(text: description_hash["f"]))

        if description_hash["e"].present?
          description_hash["e"].each_with_index do |example_content, j|
            example = description.examples[j].presence || description.examples.create
            example.update(content: clean(text: example_content))
          end
        end

        next if description_hash["s"].blank?

        description_hash["s"].each_with_index do |synonym_content, k|
          synonym = description.synonyms[k].presence || description.synonyms.create
          synonym.update(content: clean(text: synonym_content), term_type: "同")
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
        next if clean(text: id) == "類別"

        serial              = clean(text: serial)
        description_content = clean(text: description_content)
        term_names          = clean(text: term_names)
        note_content        = clean(text: note_content) if note_content.present?
        level               = clean(text: level)

        term_names.split("/").each do |term_name|
          term_name.strip!
          term = dictionary.terms.find_or_create_by(name: term_name)

          description = term.descriptions.find_or_create_by(glossary_serial: serial)
          content = if note_content.present?
                      [ description_content, note_content ].join("\n")
                    else
                      description_content
                    end
          description.update(content: content, glossary_level: level)
        end
      end
    end
  end

  desc "從 ilrdf.txt 匯入"
  task ilrdf: :environment do
    file = File.read("tmp/dict/ilrdf.txt").split("\n")
    file.each do |f|
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
      puts "找不到檔案: #{file_path}"
      exit
    end

    puts "開始匯入博利亞潘世光阿漢字典..."

    # 方言代碼對照表
    dialect_codes = {
      "Ch" => "國語",
      "S" => "南方話",
      "F" => "鳳林話",
      "T" => "富田語",
      "J" => "日語",
      "Tw" => "閩南語",
      "N" => "北方話",
      "Z" => "撒奇萊雅語"
    }

    current_term = nil
    current_term_record = nil
    current_description = nil
    line_count = 0
    term_count = 0

    File.foreach(file_path) do |line|
      line_count += 1
      line = clean(text: line)
      next if line.blank?

      if line.match?(/^[\p{L}''ʼ^ ]+[:：]/) # 如果行以字母開頭並包含冒號（包括全形冒號），視為新詞條
        # 提取詞條名稱
        term_name = line.split(/[:：]/).first.strip

        # 如果先前的詞條資料還沒處理完，先處理掉
        if current_term && current_description
          current_description.save if current_description.changed?
        end

        # 建立新詞條
        current_term = term_name
        current_term_record = dictionary.terms.find_or_create_by(name: current_term)
        term_count += 1

        # 提取描述部分
        description_content = line.split(/[:：]/, 2)[1].to_s.strip
        current_description = current_term_record.descriptions.create(content: description_content)

        # 識別方言標記並處理
        dialect_codes.each do |code, dialect_name|
          if description_content.include?("{#{code}}") || description_content.include?("(#{code})")
            current_description.description_type = dialect_name
            break
          end
        end

        puts "處理詞條 #{term_count}: #{current_term}" if (term_count % 100).zero?
      elsif line.include?("=") || line.include?("＝") # 如果行包含等號，視為同義詞
        # 處理同義詞
        parts = line.split(/=|＝/)
        if parts.size >= 2
          synonym_content = parts[1].strip
          # 清理可能的其他標記、註釋
          synonym_content = synonym_content.split(/[;；-]/).first.strip
          synonym_content = synonym_content.gsub(/[\(\{\[（【].*?[\)\}\]）】]/, "").strip

          if synonym_content.present? && current_description
            current_description.synonyms.create(content: synonym_content, term_type: "同")
          end
        end
      elsif (line.include?("-") || line.include?("；")) && current_description # 如果行包含分隔符號，視為例句或額外資訊
        parts = line.split(/[-；]/)
        if parts.size >= 2
          example_content = parts[1].strip
          if example_content.present?
            current_description.examples.create(content: example_content)
          end
        end
      elsif current_description # 其他行視為描述的延續
        # 檢查是否包含方言標記
        has_dialect = false
        dialect_codes.each do |code, dialect_name|
          if line.include?("{#{code}}")||line.include?("(#{code})")
            has_dialect = true
            # 如果找到方言標記且不是延續當前描述，建立新描述
            if current_description.description_type != dialect_name
              current_description = current_term_record.descriptions.create(
                content: line,
                description_type: dialect_name
              )
            else
              # 延續當前描述
              current_description.content += "\n#{line}"
            end
            break
          end
        end

        # 如果沒有方言標記，則簡單地延續當前描述
        unless has_dialect
          current_description.content += "\n#{line}"
        end
      end
    end

    # 處理最後一個詞條
    if current_term && current_description
      current_description.save if current_description.changed?
    end

    puts "匯入完成。總共處理 #{line_count} 行，匯入 #{term_count} 個詞條。"
  end
end

def clean(text:)
  text.gsub(/\xEF\xBB\xBF/, "").strip
end

def ilref_hash(data)
  dictionary = Dictionary.find_by(name: "原住民族語言線上辭典")

  data["Name"] = data["Name"].sub(/1|2/, "")
  term = dictionary.terms.find_or_create_by(name: clean(text: data["Name"]))
  term.variant   = clean(text: data["Variant"])   if data["Variant"].present?

  if data["Frequency"].present?
    if term.frequency.to_i < clean(text: data["Frequency"]).to_i
      term.frequency = clean(text: data["Frequency"])
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
    if term.note.present?
      term.note += "\n#{clean(text: data["Note"])}" unless term.note.include?(clean(text: data["Note"]))
    else
      term.note = clean(text: data["Note"])
    end
  end

  if data["Note"].is_a?(Hash) && data["Note"]["#text"].present?
    if data["Note"]["#text"].is_a? String
      if term.note.present?
        term.note += "\n#{clean(text: data["Note"]["#text"])}" unless term.note.include?(clean(text: data["Note"]["#text"]))
      else
        term.note = clean(text: data["Note"]["#text"])
      end
    end

    if data["Note"]["#text"].is_a? Array
      if term.note.present?
        term.note += "\n#{data["Note"]["#text"].map { |text| clean(text: text) }.join("\n")}" unless term.note.include?(clean(text: data["Note"]["#text"][0]))
      else
        term.note = data["Note"]["#text"].map { |text| clean(text: text) }.join("\n")
      end
    end
  end

  if term.changed?
    # binding.irb
    term.save
  end

  # 字典的詞幹（來源）衝突時，以字數少的為主
  if data["Source"].is_a? String
    # binding.irb unless Stem.exists?(name: clean(text: data["Source"]))
    stem = Stem.find_or_create_by(name: clean(text: data["Source"]))
    if term.stem.blank?
      term.update(stem_id: stem.id)
    else
      if (term.stem_id != stem.id) && (stem.name.size < term.stem.name.size)
        term.update(stem_id: stem.id)
      end
    end
  end

  if data["Source"].is_a? Hash
    # binding.irb unless Stem.exists?(name: clean(text: data["Source"]["#text"]))
    stem = Stem.find_or_create_by(name: clean(text: data["Source"]["#text"]))
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
    # binding.irb unless term.descriptions.exists?(content: clean(text: explanation["Chinese"]))
    description = term.descriptions.find_or_create_by(content: clean(text: explanation["Chinese"]))

    if explanation["Focus"].present? && description.focus.blank?
      description.focus = clean(text: explanation["Focus"])
    end

    if explanation["TC"].present? && description.category.blank?
      description.category = clean(text: explanation["TC"])
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
      # binding.irb unless term.descriptions.exists?(content: clean(text: explanation["Chinese"]))
      description = term.descriptions.find_or_create_by(content: clean(text: explanation["Chinese"]))

      if explanation["Focus"].present? && description.focus.blank?
        description.focus = clean(text: explanation["Focus"])
      end

      if explanation["TC"].present? && description.category.blank?
        description.category = clean(text: explanation["TC"])
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
      description.image1_alt = clean(text: data["Name"]) if data["Name"].present?
      description.image1_provider = clean(text: data["Provider"]) if data["Provider"].present?
      description.image1 = data["Src"].sub("https://e-dictionary.ilrdf.org.tw/MultiMedia/Images", "/ilrdf/images")
    elsif description.image2.blank?
      description.image2_alt = clean(text: data["Name"]) if data["Name"].present?
      description.image2_provider = clean(text: data["Provider"]) if data["Provider"].present?
      description.image2 = data["Src"].sub("https://e-dictionary.ilrdf.org.tw/MultiMedia/Images", "/ilrdf/images")
    elsif description.image3.blank?
      description.image3_alt = clean(text: data["Name"]) if data["Name"].present?
      description.image3_provider = clean(text: data["Provider"]) if data["Provider"].present?
      description.image3 = data["Src"].sub("https://e-dictionary.ilrdf.org.tw/MultiMedia/Images", "/ilrdf/images")
    else
      # binding.irb
    end
  when 1
    if data["Name"].present? && (description.image1_alt != clean(text: data["Name"]))
      # binding.irb
      description.image1_alt = clean(text: data["Name"])
    end

    if data["Provider"].present? && (description.image1_provider != clean(text: data["Provider"]))
      # binding.irb
      description.image1_provider = clean(text: data["Provider"])
    end
  when 2
    if data["Name"].present? && (description.image2_alt != clean(text: data["Name"]))
      # binding.irb
      description.image2_alt = clean(text: data["Name"])
    end

    if data["Provider"].present? && (description.image2_provider != clean(text: data["Provider"]))
      # binding.irb
      description.image2_provider = clean(text: data["Provider"])
    end
  when 3
    if data["Name"].present? && (description.image3_alt != clean(text: data["Name"]))
      # binding.irb
      description.image3_alt = clean(text: data["Name"])
    end

    if data["Provider"].present? && (description.image3_provider != clean(text: data["Provider"]))
      # binding.irb
      description.image3_provider = clean(text: data["Provider"])
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

        if clean(text: data["Chinese"]) == "你們要用扁擔平衡扛起豬隻來。"
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
  example = description.examples.find_or_create_by(content_amis: clean(text: data["Original"]))
  example.content_zh = clean(text: data["Chinese"]) if data["Chinese"].present? && (example.content_zh != clean(text: data["Chinese"]))
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
