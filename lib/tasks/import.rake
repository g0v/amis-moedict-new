# frozen_string_literal: true

namespace :import do
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

  desc "從 g0v/amis-moedict 下的 docs/p 檔案匯入博利亞潘世光阿法字典"
  task poinsot: :environment do
    dictionary = 'poinsot'

    Dir.glob('tmp/dict/p/*.json').each do |filename|
      # puts filename
      file = File.read(filename)
      next if file.blank?

      json = JSON.parse(file)
      next if !json.is_a?(Hash) || json['t'].blank?
    end
  end

  desc "從 g0v/amis-moedict 下的 docs/m 檔案匯入方敏英字典"
  task fay: :environment do
    dictionary = 'fay'

    Dir.glob('tmp/dict/m/*.json').each do |filename|
      # puts filename
      file = File.read(filename)
      next if file.blank?

      json = JSON.parse(file)
      next if !json.is_a?(Hash) || json['t'].blank?
    end
  end
end
