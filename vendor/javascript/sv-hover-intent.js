var e=typeof globalThis!=="undefined"?globalThis:typeof self!=="undefined"?self:global;e.SV=window.SV||{};SV.HoverIntent=function(){return function(e,t){const n={exitDelay:400,interval:100,sensitivity:7};let i={};let o,s,a,c;let l,f,r;const extend=function(e,t){for(let n in t)e[n]=t[n];return e};const mouseTrack=function(e){o=e.pageX;s=e.pageY};const mouseCompare=function(e){const t=a-o,n=c-s;const u=Math.sqrt(t*t+n*n);if(u<i.sensitivity){clearTimeout(r);for(let e of l)if(e.isActive){i.onExit(e);e.isActive=false}i.onEnter(e);e.isActive=true}else{a=o;c=s;f=setTimeout((function(){mouseCompare(e)}),i.interval)}};const init=function(e,t){if(!t||!t.onEnter||!t.onExit)throw"onEnter and onExit callbacks must be provided";i=extend(n,t);l=e;for(let e of l){e.isActive=false;e.addEventListener("mousemove",mouseTrack);e.addEventListener("mouseenter",(function(t){a=t.pageX;c=t.pageY;e.isActive?clearTimeout(r):f=setTimeout((function(){mouseCompare(e)}),i.interval)}));e.addEventListener("mouseleave",(function(t){clearTimeout(f);e.isActive&&(r=setTimeout((function(){i.onExit(e);e.isActive=false}),i.exitDelay))}))}};init(e,t)}}();var t={};export{t as default};
