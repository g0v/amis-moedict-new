# frozen_string_literal: true

# == Schema Information
#
# Table name: terms
#
#  id              :integer          not null, primary key
#  dictionary_id   :integer
#  stem_id         :integer
#  name            :string
#  lower_name      :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  customized_text :string(500)
#  is_stem         :boolean          default(FALSE)
#

class Term < ApplicationRecord
  store :customized_text, accessors: %i[repetition audio frequency variant note dialects term_source]

  belongs_to :dictionary, counter_cache: true
  belongs_to :stem, optional: true
  has_many   :descriptions, dependent: :destroy

  validates :name, presence: true

  before_save :clean_name_and_set_lower_name, :set_is_stem

  TERM_SOURCE_MAP = {
    "BIT" => "建築工程術語（Building Industry Terms）（臺灣的建築業以臺語化和工人溝通）",
    "E" => "東海岸語（East Coast 'Amis Dialect）",
    "En" => "英語借詞（From English）",
    "En-J" => "台語化日語借詞（From Japanized English）",
    "En-T" => "台語化英語借詞（From Taiwanized English），這裡的T代表(T-A)",
    "F" => "馬太鞍語（Fata'an Dialect）",
    "Fn" => "池上語（Fanaw Dialect）（臺東縣池上鄉地區特殊方言）",
    "Fw" => "馬蘭語（Falangaw Dialect）（臺東縣臺東市馬蘭方言）",
    "G" => "一般用語（General 'Amis）（指相對於北部阿美語其他四亞群均通用者）",
    "Ge" => "德語借詞（From German）",
    "J" => "日語借詞（From Japanese）",
    "J-T" => "台語化日語借詞（From Taiwanized Japanese），這裡的T代表(T-A)",
    "K" => "奇美語（Kiwit Dialect）",
    "Kn" => "七腳川語（Cikasoan Dialect）",
    "M" => "華語借詞（From Mandarin）",
    "MI" => "伊班馬來西亞（Iban Malaysia）",
    "Mk" => "真柄語（Makerahay Dialect）（臺東縣長濱鄉真柄部落方言）",
    "Mw" => "成功地區語（Madawdaw Dialect）（臺東縣成功鎮地區方言）",
    "N" => "北部阿美語（Northern 'Amis Dialect）",
    "Pr." => "三仙語（Pisirian Dialect）（臺東縣成功鎮三仙部落方言）",
    "R-E" => "海岸阿美祭詞（Ritual term of the East Coast 'Amis）",
    "R-F" => "馬太鞍祭詞（Ritual term of Fata'an）",
    "R-G" => "一般祭詞（北部阿美以外）（Ritual term in general）",
    "R-N" => "北部阿美祭詞（Ritual term of Northern 'Amis）",
    "R-T" => "太巴塱祭詞（Ritual term of Tafalong）",
    "S" => "南部阿美語（Southern 'Amis Dialect）",
    "Sn" => "秀姑巒阿美語（Siwkulan 'Amis Dialect）",
    "T" => "太巴塱語（Tafalong Dialect）",
    "T-A" => "臺灣閩南語借詞（From Taiwan's Amoy Dialect）",
    "Tr." => "都歷語（Torik Dialect）（臺東縣成功鎮都歷方言）",
    "Z" => "撒奇拉亞借詞（From Sakizaya Dialect）"
  }

  def self.ransackable_associations(auth_object = nil)
    %w[descriptions dictionary stem]
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[lower_name name dictionary_id stem_id created_at updated_at is_stem id customized_text
       repetition audio frequency variant note]
  end

  def short_description
    Rails.cache.fetch("term-#{name}-#{Date.today}", expires_in: 6.hours) do
      term_ids = Term.select(:id).where(name: name).order(:dictionary_id).pluck(:id)

      arel_description = Description.arel_table
      case_statement = Arel::Nodes::Case.new(arel_description[:term_id])
      term_ids.each_with_index do |_term_id, i|
        case_statement.when(_term_id).then(i+1)
      end
      case_statement.else(10000)

      Description.where(term_id: term_ids).order(case_statement).map(&:content).first&.[](0..20)
    end
  end

  def audio_url
    "https://g0v.github.io/amis-moedict-static#{audio}" if audio.present?
  end

  private

    def clean_name_and_set_lower_name
      name.strip!

      self.name = name
      self.lower_name = name.downcase
    end

    def set_is_stem
      stem_record = Stem.find_by(name: name)
      if stem_record.present?
        self.is_stem = true
        self.stem_id = stem_record.id if stem_id.blank?
      end
    end
end
