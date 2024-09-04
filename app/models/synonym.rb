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
end
