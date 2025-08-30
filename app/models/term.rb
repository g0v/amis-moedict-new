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
  store :customized_text, accessors: %i[repetition audio frequency variant note]

  belongs_to :dictionary
  belongs_to :stem, optional: true
  has_many   :descriptions, dependent: :destroy

  validates :name, presence: true

  before_save :clean_name_and_set_lower_name, :set_is_stem

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
      name.gsub!(/\xEF\xBB\xBF/, "")
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
