// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "jquery"
import "jquery-ui"

$( "#search" ).autocomplete({
  source: function( request, response ) {
    $.getJSON( `/api/v2/searches/${request.term}`, {}, response );
  },
  select: function( event, ui ) {
    this.value = ui.item.term;
    return false;
  }
});
