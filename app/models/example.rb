# frozen_string_literal: true

# == Schema Information
#
# Table name: examples
#
#  id             :integer          not null, primary key
#  description_id :integer
#  content        :string
#  content_zh     :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class Example < ApplicationRecord
  belongs_to :description

  validates :content, presence: true

  before_save :clean_content

  private

  def clean_content
    self.content = content.gsub(/\xEF\xBF\xB9|\xEF\xBB\xBF|\xEF\xBF\xBA|\xEF\xBF\xBB/, '').strip
    self.content_zh = content_zh.gsub(/\xEF\xBF\xB9|\xEF\xBB\xBF|\xEF\xBF\xBA|\xEF\xBF\xBB/, '').strip if content_zh.present?
  end
end
