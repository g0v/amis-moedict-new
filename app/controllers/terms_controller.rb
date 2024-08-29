# frozen_string_literal: true

class TermsController < ApplicationController
  def index; end

  def show
    @terms = Term.includes(:stem, descriptions: [:examples, :synonyms]).where(name: params[:id]).order(:dictionary_id)
    @stems = @terms.map {|t| t.stem&.name}.compact
  end
end
