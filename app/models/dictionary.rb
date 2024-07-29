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
end
