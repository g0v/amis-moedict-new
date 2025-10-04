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
    "蔡中涵大辭典" => "blue",
    "博利亞潘世光阿法字典" => "gray",
    "方敏英字典" => "green",
    "學習詞表－秀姑巒阿美語" => "red",
    "學習詞表－海岸阿美語" => "red",
    "學習詞表－馬蘭阿美語" => "red",
    "學習詞表－恆春阿美語" => "red",
    "學習詞表－南勢阿美語" => "red",
    "原住民族語言線上辭典" => "indigo",
    "博利亞潘世光阿漢字典" => "gray"
  }.freeze

  def self.ransackable_attributes(auth_object = nil)
    %w[created_at dialect id id_value name updated_at]
  end

  def color
    COLOR[name]
  end
end
