# frozen_string_literal: true

# == Schema Information
#
# Table name: examples
#
#  id              :integer          not null, primary key
#  description_id  :integer
#  content         :string
#  content_zh      :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  content_amis    :string
#  content_en      :string
#  content_fr      :string
#  customized_text :string(500)
#

class Example < ApplicationRecord
  store :customized_text, accessors: %i[audio]

  belongs_to :description

  validates :content, presence: true

  before_save :clean_content

  def self.ransackable_attributes(auth_object = nil)
    %w[content content_zh]
  end

  def audio_url
    "https://g0v.github.io/amis-moedict-static#{audio}" if audio.present?
  end

  private

    def clean_content
      self.content = content.gsub(/\xEF\xBF\xB9|\xEF\xBB\xBF|\xEF\xBF\xBA|\xEF\xBF\xBB/, "").strip
      self.content_zh = content_zh.gsub(/\xEF\xBF\xB9|\xEF\xBB\xBF|\xEF\xBF\xBA|\xEF\xBF\xBB/, "").strip if content_zh.present?
    end
end
