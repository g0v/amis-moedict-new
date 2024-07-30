# frozen_string_literal: true

namespace :import do
  desc "字典列表"
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
      dictionary = Dictionary.find_or_create_by(name: name, dialect: dialect)
    end
  end

  desc "從 g0v/amis-moedict 下的 docs/s 檔案匯入蔡中涵大辭典"
  task safolu: :environment do
    dictionary = 'safolu'

    Dir.glob('tmp/dict/s/*.json').each do |filename|
      # puts filename
      file = File.read(filename)
      next if file.blank?

      json = JSON.parse(file)
      next if !json.is_a?(Hash) || json['t'].blank?
    end
  end

  desc "從 g0v/amis-moedict 下的 docs/m 檔案匯入博利亞潘世光阿法字典"
  task poinsot: :environment do
    dictionary = 'poinsot'

    Dir.glob('tmp/dict/m/*.json').each do |filename|
      # puts filename
      file = File.read(filename)
      next if file.blank?

      json = JSON.parse(file)
      next if !json.is_a?(Hash) || json['t'].blank?
    end
  end

  desc "從 g0v/amis-moedict 下的 docs/p 檔案匯入方敏英字典"
  task fay: :environment do
    dictionary = 'fay'

    Dir.glob('tmp/dict/p/*.json').each do |filename|
      # puts filename
      file = File.read(filename)
      next if file.blank?

      json = JSON.parse(file)
      next if !json.is_a?(Hash) || json['t'].blank?
    end
  end
end
