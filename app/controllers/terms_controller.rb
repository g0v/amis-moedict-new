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

    session[:last_page] = request.url
  end
end
