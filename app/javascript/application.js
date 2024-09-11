// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "jquery"
import "jquery-ui"

$( "#search" ).autocomplete({
  source: function( request, response ) {
    $.getJSON( `/api/v2/searches/${request.term}`, {}, response );
  },
  focus: function( event, ui ) {
    $( "#search" ).val();
    return false;
  },
  select: function( event, ui ) {
    if (ui.item.term !== "Awaay to. 找不到") {
      this.value = ui.item.term;
    }
    window.location.href = `/terms/${ui.item.term}`;
    return false;
  }
}).autocomplete( "instance" )._renderItem = function( ul, item ) {
  var divHtml;

  if (item.term !== "Awaay to. 找不到") {
    divHtml = `<div class="flex justify-between ui-menu-item-wrapper px-2 py-0.5 text-gray-600 hover:bg-gray-200">
                <div class"text-sm font-medium text-indigo-600">${item.term}</div>
                <div class="text-sm text-gray-500 mt-1 sm:mt-0">${item.description}</div>
               </div>`;
  } else {
    divHtml = item.term;
  }

  return $( `<li class="ui-menu-item">` )
           .append( divHtml )
           .appendTo( ul );
};

$( "#sidebar" ).append( $( "#ui-id-1.ui-autocomplete" ) );
