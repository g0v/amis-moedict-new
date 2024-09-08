# frozen_string_literal: true

class TermsController < ApplicationController
  def index; end

  def show
    @terms = Term.includes(:dictionary, :stem, descriptions: %i[examples synonyms]).where(name: params[:id]).order(:dictionary_id)
    redirect_back(fallback_location: "/") if @terms.empty?
  end
end
