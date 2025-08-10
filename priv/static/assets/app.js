(()=>{var c=(n=>typeof require!="undefined"?require:typeof Proxy!="undefined"?new Proxy(n,{get:(a,r)=>(typeof require!="undefined"?require:a)[r]}):n)(function(n){if(typeof require!="undefined")return require.apply(this,arguments);throw Error('Dynamic require of "'+n+'" is not supported')});var l=c("phoenix_live_view"),m=c("phoenix"),h=document.querySelector("meta[name='csrf-token']").getAttribute("content"),d=new l.LiveSocket("/live",m.Socket,{params:{_csrf_token:h}});d.connect();window.liveSocket=d;document.addEventListener("DOMContentLoaded",function(){document.querySelectorAll(".animate-pulse, .animate-ping, .animate-bounce").forEach((t,o)=>{t.style.animationDelay=`${o*.5}s`}),document.querySelectorAll(".group").forEach(t=>{t.addEventListener("mouseenter",function(){this.style.transform="translateY(-5px)"}),t.addEventListener("mouseleave",function(){this.style.transform="translateY(0)"})}),document.querySelectorAll("button").forEach(t=>{t.addEventListener("click",function(o){let e=document.createElement("span"),s=this.getBoundingClientRect(),i=Math.max(s.width,s.height),u=o.clientX-s.left-i/2,f=o.clientY-s.top-i/2;e.style.width=e.style.height=i+"px",e.style.left=u+"px",e.style.top=f+"px",e.classList.add("ripple"),this.appendChild(e),setTimeout(()=>{e.remove()},600)})})});var p=document.createElement("style");p.textContent=`
  .ripple {
    position: absolute;
    border-radius: 50%;
    background: rgba(255, 255, 255, 0.3);
    transform: scale(0);
    animation: ripple-animation 0.6s linear;
    pointer-events: none;
  }
  
  @keyframes ripple-animation {
    to {
      transform: scale(4);
      opacity: 0;
    }
  }
`;document.head.appendChild(p);})();
