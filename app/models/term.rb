# frozen_string_literal: true

# == Schema Information
#
# Table name: terms
#
#  id            :integer          not null, primary key
#  dictionary_id :integer
#  stem_id       :integer
#  name          :string
#  lower_name    :string
#  repetition    :integer
#  loanword      :boolean          default(FALSE), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class Term < ApplicationRecord
  belongs_to :dictionary
  belongs_to :stem, optional: true
  has_many   :descriptions, dependent: :destroy

  validates :name, presence: true

  before_save :set_lower_name

  scope :amis,      -> { where(loanword: false) }
  scope :loanwords, -> { where(loanword: true) }

  def short_description
    descriptions.first&.content&.[](0..20)
  end

  private

  def set_lower_name
    self.lower_name = name.downcase
  end
end
