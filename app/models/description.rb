# frozen_string_literal: true

# == Schema Information
#
# Table name: descriptions
#
#  id               :integer          not null, primary key
#  term_id          :integer
#  content          :string(500)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  description_type :string(3)
#

class Description < ApplicationRecord
  belongs_to :term
  has_many   :examples, dependent: :destroy
  has_many   :synonyms, dependent: :destroy

  before_save :clean_content

  private

  def clean_content
    self.content = content.gsub(/\xEF\xBF\xB9|\xEF\xBB\xBF|\xEF\xBF\xBA|\xEF\xBF\xBB/, '').strip if content.present?
  end
end
