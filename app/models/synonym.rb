# frozen_string_literal: true

# == Schema Information
#
# Table name: synonyms
#
#  id             :integer          not null, primary key
#  description_id :integer
#  term_type      :string(5)
#  content        :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class Synonym < ApplicationRecord
  belongs_to :description

  scope :alts, -> { where(term_type: '同') }
  scope :refs, -> { where(term_type: '參見') }

  validates :content, presence: true

  before_save :clean_content

  private

  def clean_content
    self.content = content.gsub(/\xEF\xBF\xB9|\xEF\xBB\xBF|\xEF\xBF\xBA|\xEF\xBF\xBB/, '').strip
  end
end
