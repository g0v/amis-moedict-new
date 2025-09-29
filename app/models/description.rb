# frozen_string_literal: true

# == Schema Information
#
# Table name: descriptions
#
#  id               :integer          not null, primary key
#  term_id          :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  description_type :string(3)
#  glossary_serial  :string(10)
#  glossary_level   :string(10)
#  customized_text  :string(500)
#  content_zh       :string
#  content_en       :string
#  content_fr       :string
#

class Description < ApplicationRecord
  store :customized_text, accessors: %i[image1 image1_alt image1_provider
                                        image2 image2_alt image2_provider
                                        image3 image3_alt image3_provider
                                        focus category]

  belongs_to :term
  has_many   :examples, dependent: :destroy
  has_many   :synonyms, dependent: :destroy

  before_save :clean_content

  def self.ransackable_associations(auth_object = nil)
    %w[examples synonyms term]
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[id term_id content description_type created_at updated_at glossary_serial glossary_level
       customized_text content_zh content_en content_fr
       image1 image1_alt image1_provider image2 image2_alt image2_provider
       image3 image3_alt image3_provider focus category]
  end

  def image1_url
    "https://g0v.github.io/amis-moedict-static#{image1}" if image1.present?
  end

  def image2_url
    "https://g0v.github.io/amis-moedict-static#{image2}" if image2.present?
  end

  def image3_url
    "https://g0v.github.io/amis-moedict-static#{image3}" if image3.present?
  end

  def image1_text
    image1_alt.present? ? image1_alt : content
  end

  def image2_text
    image2_alt.present? ? image2_alt : content
  end

  def image3_text
    image3_alt.present? ? image3_alt : content
  end

  def content
    "#{content_zh}#{content_en}#{content_fr}"
  end

  private

    def clean_content
      self.content_zh = content_zh.strip if content_zh.present?
      self.content_en = content_en.strip if content_en.present?
      self.content_fr = content_fr.strip if content_fr.present?
    end
end
