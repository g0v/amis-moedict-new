# frozen_string_literal: true

# == Schema Information
#
# Table name: synonyms
#
#  id             :integer          not null, primary key
#  description_id :integer
#  term_type      :string(5)
#  content        :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  term_source    :string(50)
#  content_raw    :string
#

class Synonym < ApplicationRecord
  belongs_to :description

  scope :alts, -> { where(term_type: "同") }
  scope :refs, -> { where(term_type: "參見") }

  validates :content, presence: true

  before_save :clean_content

  def self.ransackable_associations(auth_object = nil)
    %w[description]
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[content created_at description_id id id_value term_type updated_at]
  end

  private

    def clean_content
      self.content = content.strip
    end
end
