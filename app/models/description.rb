# == Schema Information
#
# Table name: descriptions
#
#  id            :integer          not null, primary key
#  definition_id :integer
#  term_id       :integer
#  content       :string(500)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class Description < ApplicationRecord
  belongs_to :term
  belongs_to :definition
  has_many   :examples, dependent: :destroy
  has_many   :synonyms, dependent: :destroy
end
