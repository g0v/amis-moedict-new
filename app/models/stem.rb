# frozen_string_literal: true

# == Schema Information
#
# Table name: stems
#
#  id         :integer          not null, primary key
#  name       :string(40)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Stem < ApplicationRecord
  has_many :terms

  validates :name, uniqueness: { case_sensitive: false }

  before_save :downcase_name

  private

    def downcase_name
      self.name = name.downcase
    end
end
