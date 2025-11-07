# frozen_string_literal: true

# == Schema Information
#
# Table name: stems
#
#  id         :integer          not null, primary key
#  name       :string(40)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  has_term   :boolean          default(FALSE)
#

class Stem < ApplicationRecord
  has_many :terms

  validates :name, uniqueness: true

  before_save :assign_has_term

  def self.ransackable_associations(auth_object = nil)
    %w[terms]
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[created_at id id_value name updated_at]
  end

  private

    def assign_has_term
      self.has_term = Term.exists?(name: name)
    end
end
