# frozen_string_literal: true

class PagesController < ApplicationController
  def statistics
    @dictionaries = Dictionary.includes(:terms).order(:terms_count)

    @examples_by_dict = Example.joins(description: { term: :dictionary })
                               .group('dictionaries.id')
                               .count

    @synonyms_by_dict = Synonym.joins(description: { term: :dictionary })
                               .group('dictionaries.id')
                               .count

    @total_terms = Term.count
    @total_examples = Example.count
    @total_synonyms = Synonym.count
    @total_descriptions = Description.count
  end
end
