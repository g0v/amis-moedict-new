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
  store :customized_text, accessors: %i[repetition audio]

  belongs_to :dictionary
  belongs_to :stem, optional: true
  has_many   :descriptions, dependent: :destroy

  validates :name, presence: true

  before_save :clean_name_and_set_lower_name, :set_is_stem

  def self.ransackable_attributes(auth_object = nil)
    %w[lower_name]
  end

  def short_description
    descriptions.first&.content&.[](0..20)
  end

  def audio_id
    audio.match(%r{/(\d+)/(\d+_\d+)\.wav$})[1..2].join("-")
  end

  private

    def clean_name_and_set_lower_name
      name.gsub!(/\xEF\xBF\xB9|\xEF\xBB\xBF|\xEF\xBF\xBA|\xEF\xBF\xBB/, "")
      name.strip!

      self.name = name
      self.lower_name = name.downcase
    end

  def set_is_stem
    self.is_stem = Stem.exists?(name: name)
  end
end
