window.onload = function() {
	var columnsareaElements = document.getElementsByClassName('column-area');
	var observer = new MutationObserver(function() {
	  'use strict';
	
	  var textWaveElements = document.getElementsByClassName('txtwav');
	
	  function spanWrapHelper(el, text) {
	    for(var i = 0; i < text.length; i++) {
	      var span = document.createElement('span');
	      span.innerHTML = text[i] === ' ' ? '&nbsp;' : text[i];
	      el.appendChild(span);
	    }
	  }
	
	  for (var i = 0, length = textWaveElements.length; i < length; i++) {
	    var el = textWaveElements[i],
	      text = el.textContent.trim();
	
	    el.innerHTML = '';
	    spanWrapHelper(el, text);
	  }
	});
	for (var j = 0, length = columnsareaElements.length; j < length; j++) {
		observer.observe(columnsareaElements[j], {childList: true});
	}
};

