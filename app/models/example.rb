# frozen_string_literal: true

# == Schema Information
#
# Table name: examples
#
#  id               :integer          not null, primary key
#  description_id   :integer
#  content_zh       :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  content_amis     :string
#  content_en       :string
#  content_fr       :string
#  customized_text  :string(500)
#  content_amis_raw :string
#

class Example < ApplicationRecord
  store :customized_text, accessors: %i[audio]

  belongs_to :description

  validates :content_amis, presence: true

  before_save :clean_content

  def self.ransackable_associations(auth_object = nil)
    %w[description]
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[content content_zh content_amis content_en content_fr id description_id created_at updated_at customized_text]
  end

  def audio_url
    "https://g0v.github.io/amis-moedict-static#{audio}" if audio.present?
  end

  def content
    "#{content_amis}#{content_zh}#{content_en}#{content_fr}"
  end

  private

    def clean_content
      self.content_amis     = content_amis.strip
      self.content_amis_raw = content_amis.gsub(/`|~/, "").strip
      self.content_zh       = content_zh.gsub(/`|~/, "").strip if content_zh.present?
      self.content_en       = content_en.gsub(/`|~/, "").strip if content_en.present?
      self.content_fr       = content_fr.gsub(/`|~/, "").strip if content_fr.present?
    end
end
