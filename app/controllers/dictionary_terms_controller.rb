class DictionaryTermsController < ApplicationController
  def show
    @dictionary = Dictionary.find_by(id: params[:dictionary_id])
    redirect_back(fallback_location: "/") if @dictionary.blank?

    @terms = @dictionary.terms.includes(:dictionary, :stem, descriptions: %i[examples synonyms]).where(name: params[:id])
    redirect_back(fallback_location: "/") if @terms.empty?

    session[:last_page] = request.url

    render :"terms/show"
  end
end
