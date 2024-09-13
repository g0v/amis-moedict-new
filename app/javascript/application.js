// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "jquery"
import "jquery-ui"
import "sv-hover-intent"

$( "#search" ).autocomplete({
  source: function( request, response ) {
    $.getJSON( `/api/v2/searches/${request.term}`, {}, response );
  },
  focus: function( event, ui ) {
    $( "#search" ).val();
    return false;
  },
  select: function( event, ui ) {
    if ((ui.item.term !== "Awaay. 找不到。") && (ui.item.term.indexOf("精確搜尋，結果較少") === -1)) {
      this.value = ui.item.term;
      window.location.href = `/terms/${ui.item.term}`;
    }
    return false;
  }
}).autocomplete( "instance" )._renderItem = function( ul, item ) {
  var divHtml;

  if ((item.term !== "Awaay. 找不到。") && (item.term.indexOf("精確搜尋，結果較少") === -1)) {
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

$( ".hoverable-term" ).tooltip({
  disabled: true, // 交給 hoverintent 處理 show/hide
  show: 200,
  items: "a",
  classes: {
    "ui-tooltip": "shadow-xl rounded-lg bg-gray-100 max-w-xs w-fit p-2"
  },
  open: function( event, ui ) {
    var term, $this = $(this);
    term = $(this).data('term');
    $.getJSON( `/api/v2/terms/${term}`, {}, function(data) {
      if (data.length !== undefined) {
        var content = `<h3 class="text-xl">${term}</h3>
                       <hr class="h-px border-0 dark:bg-gray-400">
                       <ol class="list-decimal list-outside space-y-2 mt-2 ml-5">`;

        data.slice(0, 3).forEach(function(termData) {
          termData.descriptions.forEach(function(descriptionData) {
            content += `<li class="text-sm">${descriptionData.content.replace(/[`~]/g, "")}</li>`;
          });
        });
        content += "</ol>";

        $this.tooltip("option", {
          content: content,
        });
      } else {
        $this.tooltip( "close" );
      }
    } );
  },
  content: "讀取中……"
});

new SV.HoverIntent( $( ".hoverable-term" ), {
  onEnter: function(targetItem) {
    $(targetItem).tooltip( "open" );
  },
  onExit: function(targetItem) {
    $(targetItem).tooltip( "close" );
  },

  // default options
  exitDelay: 400,
  interval: 250,
  sensitivity: 7,
});
