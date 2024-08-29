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

  def color
    case name
    when '蔡中涵大辭典' then 'blue'
    when '博利亞潘世光阿法字典' then 'gray'
    when '方敏英字典' then 'green'
    end
  end
end
