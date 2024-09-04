# frozen_string_literal: true

# == Schema Information
#
# Table name: examples
#
#  id             :integer          not null, primary key
#  description_id :integer
#  content        :string
#  content_zh     :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class Example < ApplicationRecord
  belongs_to :description

  validates :content, presence: true
end
