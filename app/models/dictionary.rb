# frozen_string_literal: true

# == Schema Information
#
# Table name: dictionaries
#
#  id         :integer          not null, primary key
#  name       :string(50)
#  dialect    :string(15)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Dictionary < ApplicationRecord
  has_many :terms

  COLOR = {
    '蔡中涵大辭典' => 'blue',
    '博利亞潘世光阿法字典' => 'gray',
    '方敏英字典' => 'green'
  }.freeze

  def color
    COLOR[name]
  end
end
