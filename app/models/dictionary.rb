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
  has_many :dictionary_terms, dependent: :destroy
  has_many :terms, through: :dictionary_terms
end
