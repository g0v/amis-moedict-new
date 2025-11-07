class DictionaryTermsController < ApplicationController
  def show
    @dictionary = Dictionary.find_by(id: params[:dictionary_id])
    return redirect_back(fallback_location: "/") if @dictionary.blank?

    @terms = @dictionary.terms.includes(:dictionary, :stem, descriptions: %i[examples synonyms]).where(name: params[:id])
    return redirect_back(fallback_location: "/") if @terms.empty?

    @dictionaries = [ @dictionary ]
    session[:last_page] = request.url

    render :"terms/show"
  end
end
