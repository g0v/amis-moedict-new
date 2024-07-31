# frozen_string_literal: true

# == Schema Information
#
# Table name: dictionary_terms
#
#  id            :integer          not null, primary key
#  dictionary_id :integer
#  term_id       :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class DictionaryTerm < ApplicationRecord
  belongs_to :dictionary
  belongs_to :term
end
