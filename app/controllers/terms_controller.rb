# frozen_string_literal: true

class TermsController < ApplicationController
  def index
    if session[:last_page]
      redirect_to session[:last_page]
    else
      @terms = Term.includes(:dictionary, :stem, descriptions: %i[examples synonyms]).where(name: "co'ong").order(:dictionary_id)
      redirect_to "/terms/co'ong"
    end
  end

  def show
    @terms = Term.includes(:dictionary, :stem, descriptions: %i[examples synonyms]).where(name: params[:id]).order(:dictionary_id)
    return redirect_back(fallback_location: "/") if @terms.empty?

    arel_dictionary = Dictionary.arel_table
    id_case_statement = Arel::Nodes::Case.new(arel_dictionary[:id])
    [1, 11, 2, 3, 4, 5, 6, 7, 8, 9, 10].each_with_index do |id, i|
      id_case_statement.when(id).then(i+1)
    end
    id_case_statement.else(10000)

    @dictionaries = Dictionary.where(id: @terms.map(&:dictionary_id).uniq).order(id_case_statement)
    session[:last_page] = request.url
  end
end
