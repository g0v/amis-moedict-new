// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "jquery"
import "jquery-ui"

const DICTIONARY = {
  "1": "蔡中涵大辭典",
  "2": "博利亞潘世光阿法字典",
  "3": "方敏英字典",
  "4": "學習詞表－秀姑巒阿美語",
  "5": "學習詞表－海岸阿美語",
  "6": "學習詞表－馬蘭阿美語",
  "7": "學習詞表－恆春阿美語",
  "8": "學習詞表－南勢阿美語",
  "9": "原住民族語言線上辭典"
}

// 辭典設定初始化 START
function saveSettings(newSettings = {}) {
  var defaultSettings = {
        mainDictionary: "1", // 預設主辭典為蔡中涵大辭典
        displayList:   ["1", "2", "3", "4", "5", "6", "7", "8", "9"], // 預設顯示所有字典
        displayOrder:  ["1", "3", "9", "2", "4", "5", "6", "7", "8"] // 預設字典顯示排序
      };

  var settings = {
        mainDictionary: newSettings.mainDictionary || localStorage.getItem('mainDictionary')           || defaultSettings.mainDictionary,
        displayList:    newSettings.displayList    || JSON.parse(localStorage.getItem('displayList'))  || defaultSettings.displayList,
        displayOrder:   newSettings.displayOrder   || JSON.parse(localStorage.getItem('displayOrder')) || defaultSettings.displayOrder
      };

  localStorage.setItem('mainDictionary', settings.mainDictionary);
  localStorage.setItem('displayList',    JSON.stringify(settings.displayList));
  localStorage.setItem('displayOrder',   JSON.stringify(settings.displayOrder));

  return settings;
}

window.settings = saveSettings();
// 辭典設定初始化 END

// GA 初始化 START
var hostnameForGA = 'new-amis.moedict.tw';
// hostnameForGA = 'new-amis.moedict.test'; // 開發端測試時拿掉這行註解

window.dataLayer = window.dataLayer || [];
function gtag(){dataLayer.push(arguments);}
gtag('js', new Date());

if (window.location.hostname == hostnameForGA) {
  // 關閉自動 send_page_view，拉到 turbo:load 裡面
  gtag('config', 'G-VMCGN0EBM0', {
    send_page_view: false
  });
}
// GA 初始化 END

document.addEventListener( "turbo:load", function() {
  var currentPath = window.location.pathname,
      currentLocation = window.location.href;

  if (window.location.hostname == hostnameForGA) {
    // GA 的 send_page_view，放 turbo:load 事件內，切換字詞時才會送
    gtag('event', 'page_view', {
      page_title: document.title,
      page_location: currentLocation
    });

    // 送 GA 事件，紀錄單本字典的瀏覽狀況 START
    if ( currentPath.indexOf( "/dictionaries") === 0 ) {
      var dictionaryId = $( ".dictionaries ")[0].id.split('-')[1],
          termName = currentPath.split('/').pop();

      gtag('event', 'dictionary_term', {
        page_title: document.title,
        page_location: currentLocation,
        dictionary: dictionaryId,
        term: termName
      });

      console.log(`GA custom event "dictionary_term" >>>> { dictionary: ${dictionaryId}, term: "${termName}"}`)
    }
    // 送 GA 事件，紀錄單本字典的瀏覽狀況 END
  }

  // 在 /about 頁面時，點字典名稱會跳回首頁，然後自動轉向最後查找的頁面
  if ( currentPath.indexOf( "/about") !== -1 ) {
    $( "#select-dictionary-modal" ).on( "click", function() {
      window.location.href = "/";
    });
  }

  // 根據 settings 設定辭典畫面 START
  // 如果是 /terms/:name，依據辭典白名單，把不顯示的 hide
  // 如果是 /dictionaries/:id/terms/:name，一律顯示內容
  if (
      ( currentPath.indexOf( "/terms")         !== -1 ) &&
      ( currentPath.indexOf( "/dictionaries" ) === -1 )
     ) {

    $( "#dictionary-name" ).html( DICTIONARY[settings.mainDictionary] );
    Object.keys(DICTIONARY).forEach(function(el){
      if (!settings.displayList.includes(el)) {
        $( `#dictionary-${el}` ).hide();
      }
    });
    $( "#main-dictionary" ).val( settings.mainDictionary );
    $( "#display-dictionary input" ).removeAttr( "disabled" );
    $( "#display-dictionary input" ).each(function() {
      $(this).prop( { checked: settings.displayList.includes($(this).val()) } );
    })
    $( `#display-dictionary input[value="${settings.mainDictionary}"]` ).prop( { checked: "checked", disabled: "disabled"} );
  }
  // 根據 settings 設定辭典畫面 END

  if (
      ( currentPath.indexOf( "/terms") !== -1 ) ||
      ( currentPath.indexOf( "/bookmarks") !== -1 )
     ) {

    // 搜尋功能 START
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
      },
      classes: {
        "ui-autocomplete": "border border-gray-200 bg-gray-200 sm:border-0 mr-8 sm:bg-inherit sm:w-1/4 sm:pr-8"
      }
    }).data( "ui-autocomplete" )._renderItem = function( ul, item ) {
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
    // 搜尋功能 END

    // 游標 hover 顯示詞義 START
    $( ".hoverable-term" ).tooltip({
      show: { delay: 400, duration: 0 },
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
    // 游標 hover 顯示詞義 END

    // 字典設定 modal START
    $( "#select-dictionary-modal" ).on( "click", function() {
      $( "#overlay" ).removeClass( "hidden" );
      $( "#select-dictionary" ).removeClass( "hidden" );
    });

    $(" .close-modal ").on( "click", function() {
      $( "#select-dictionary" ).addClass( "hidden" );
      $( "#overlay" ).addClass( "hidden" );
    });

    $( "#main-dictionary" ).on( "change", function() {
      $( "#display-dictionary input" ).removeAttr( "disabled" );
      $( `#display-dictionary input[value="${$(this).val()}"]` ).prop( { checked: "checked", disabled: "disabled"} );
    });

    $(" #modal-submit ").on( "click", function() {
      var mainDictionary = $( "#main-dictionary" ).val(),
          displayList    = $( "#display-dictionary input:checked" ).map(function (_, el){ return el.value}).get();

      displayList.sort();
      saveSettings({ mainDictionary: mainDictionary, displayList: displayList });

      window.location.reload();
      $( "#select-dictionary" ).addClass( "hidden" );
      $( "#overlay" ).addClass( "hidden" );
    });
    // 字典設定 modal END

    // PWA 手機版複製網址功能 START
    $( "#copy-url" ).tooltip({
      disabled: true,
      items: "button",
      classes: {
        "ui-tooltip": "shadow-xl rounded bg-gray-200 text-sm w-fit p-1"
      },
      content: "網址已複製"
    });

    $( "#copy-url" ).on( "click", function(){
      navigator.clipboard.writeText(`${window.location.origin}${window.location.pathname}`);
      $(this).tooltip( "option", { disabled: false }).tooltip( "open" );
      setTimeout( function(){
        $( "#copy-url" ).tooltip( "option", { disabled: true }).tooltip( "close" );
      }, "500");
    });
    // PWA 手機版複製網址功能 START

    // 字詞記錄簿 START
    var bookmarks = new Set(JSON.parse(localStorage.getItem( "bookmarks" )) || []);

    if ( bookmarks.has( $( "#bookmark" ).data( "term" ) ) ) {
      $( "#bookmark i" ).addClass( "fa-solid fa-bookmark" );
      $( "#bookmark" ).prop( "title", "已從字詞記錄簿移除" );
    } else {
      $( "#bookmark i" ).addClass( "fa-regular fa-bookmark" );
      $( "#bookmark" ).prop( "title", "已加入字詞記錄簿" );
    }

    $( "#bookmark" ).tooltip({
      disabled: true,
      items: "button",
      classes: {
        "ui-tooltip": "shadow-xl rounded bg-gray-200 text-sm w-fit p-1"
      }
    });

    $( "#bookmark" ).on( "click", function(){
      var bookmarks = new Set(JSON.parse(localStorage.getItem( "bookmarks" )) || []),
          term = $(this).data( "term" );
      if ( bookmarks.has( term ) ) {
        bookmarks.delete( term );
        $( "#bookmark i" ).removeClass( "fa-regular fa-solid fa-bookmark" ).addClass( "fa-regular fa-bookmark" );
        $( this ).tooltip( "option", { content: "已從字詞記錄簿移除" } );
      } else {
        bookmarks.add( term );
        $( "#bookmark i" ).removeClass( "fa-regular fa-solid fa-bookmark" ).addClass( "fa-solid fa-bookmark" );
        $( this ).tooltip( "option", { content: "已加入字詞記錄簿" } );
      }

      localStorage.setItem('bookmarks', JSON.stringify([...bookmarks]));

      $(this).tooltip( "option", { disabled: false }).tooltip( "open" );
      setTimeout( function(){
        $( "#bookmark" ).tooltip( "option", { disabled: true }).tooltip( "close" );
      }, "500");

      return false;
    });
    // 字詞記錄簿 END

  }
});

document.addEventListener( "turbo:render", function() {
  var uiTooltips = document.querySelectorAll('.ui-tooltip');
  uiTooltips.forEach( function(el){
    el.remove();
  });
});
