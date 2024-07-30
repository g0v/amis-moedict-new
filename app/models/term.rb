# frozen_string_literal: true

# == Schema Information
#
# Table name: terms
#
#  id            :integer          not null, primary key
#  stem_id       :integer
#  name          :string
#  lower_name    :string
#  repetition    :integer
#  loanword      :boolean          default(FALSE), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  dictionary_id :integer
#

class Term < ApplicationRecord
  belongs_to :dictionary
  belongs_to :stem
  has_many   :definitions, dependent: :destroy
  has_many   :descriptions, dependent: :destroy

  validates :name, uniqueness: true

  before_save :set_lower_name

  scope :amis,      -> { where(loanword: false) }
  scope :loanwords, -> { where(loanword: true) }

  private

  def set_lower_name
    self.lower_name = name.downcase
  end
end
