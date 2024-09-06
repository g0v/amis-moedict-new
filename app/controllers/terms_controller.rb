# frozen_string_literal: true

class TermsController < ApplicationController
  def index; end

  def show
    @terms = Term.includes(:stem, descriptions: %i[examples synonyms]).where(name: params[:id]).order(:dictionary_id)
  end
end
