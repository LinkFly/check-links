(function ($){
    $.checkLinks = {};
      $.checkLinks.start = function(params){
	// Options for configurations (dependence of server side)
	this.ops = {resultClass: "check-links_result-data",
		   linkClass: "check-links_link",
		   linkUrl: "link_url",
		   linkValid: "link_valid-p",
	           postParamName: "urls",
	           goodLinkClass: "goodlink",
	           badLinkClass: "badlink"};
	/////////////////////////////////

	// Configure this.ops for work - add point to begin.
	this.ops.resultClass   = "." + this.ops.resultClass;
	this.ops.linkClass     = "." + this.ops.linkClass;
	this.ops.linkUrl       = "." + this.ops.linkUrl;
	this.ops.linkValid     = "." + this.ops.linkValid;

	// Parameters checking
	if(params.serviceUrl == undefined) {
	    alert("check-links: bad call parameters");
	    debugger;
	}
	/////////////

	//Create buffer for check links result
	this.buffName = "check-links-buff";
	$("<div id='" + this.buffName + "' style='display: none'/>").appendTo("body");
	this.buffName = "#" + this.buffName;

	///////// Main work /////////////////		
	this.universalEscape = function(url){
	    return escape(unescape(url.trim(" ")))
	    .replace(/[ ]/g, "%20")
	    .replace(/[+]/g, "%20")
	    .replace(/[/]/g, "%2F")
	    	             .replace(/[%]/g, "%25");
	};

	//Get all link urls
	var unEsc = this.universalEscape;
	this.allLinksHash = {};//new Array();		
	var allLnkHash = this.allLinksHash;
	$("a").each(function(index, el){
		var escLink = unEsc($(el).attr("href"));
		if(allLnkHash[escLink] == undefined) 
		    allLnkHash[escLink] = $("");
		allLnkHash[escLink] = 
		    allLnkHash[escLink].add($(el));  
	    });
	
	ops = this.ops;
	bufferName = this.buffName;
	this.markingAllLinks = function(){
            $(bufferName + " " + ops.resultClass + " " + ops.linkClass)
              .each(function(index, el){
		      var escLink = unEsc($(ops.linkUrl, el).text());					   
		      if(allLnkHash[escLink] != undefined){
			  allLnkHash[escLink].each(function(index, link){		  			     
			    $(link).removeClass(ops.goodLinkClass + " " + ops.badLinkClass)
				 .addClass($(".link_valid-p", el).html() == "true" ? "goodlink" : "badlink");
			  });
		      };
              }); //.each
	}; //function this.markingAllLinks

	var maxLenLinksPart = 1500;
	var arLinksParts = new Array();
	var curLink;
	var curLenLinksPart = 0;
	var curLinksPart = "";
	
	var checkLinkLength = function(link) {
	    if(link.length >= maxLenLinksPart) {
		alert("checkLinks: Error: very long link url");
		debugger;
	    }
	}
	
	$.each(this.allLinksHash, function(curLink){
	    checkLinkLength(curLink);
	    var newLenLinksPart = curLenLinksPart + 3 + curLink.length;
	    if(newLenLinksPart > maxLenLinksPart) {
		arLinksParts.push(curLinksPart);
		curLinksPart = curLink;
		curLenLinksPart = curLink.length;
	    } else {
		if(curLenLinksPart == 0){
		    curLinksPart = curLink;
		    curLenLinksPart = curLink.length;
		} else {
		    curLinksPart += "%0A" + curLink;
		    curLenLinksPart = newLenLinksPart;
		}
	    }
	}); //$.each
	arLinksParts.push(curLinksPart);
	var i = 0;
	var bIsMarking = -arLinksParts.length;
	document.results = {};
	var markAllLnk = this.markingAllLinks;
	this.asyncLoadBuff = function(servUrl, buffName, paramName, urls, varNameForResult){	    
	    $.getScript(servUrl + "?"
				   + paramName + "=" + urls				 
				   + "&varName=" + "document.results." + varNameForResult, 
			function(data, textStatus, xhttp){
		    $(buffName).append($(document.results[varNameForResult]));
		    document.results[varNameForResult] = undefined;
		    bIsMarking++;
		    if(bIsMarking == 0) markAllLnk();
		    }); //$.getScript  
	}; //function this.asyncLoadBuff

	curLinksPart = "";	
	countStartLoadBuff = 0;
	results = {};
	while(null != (curLinksPart = arLinksParts.pop())){
	    this.asyncLoadBuff(params.serviceUrl, 
			  this.buffName,
			  this.ops.postParamName,
			  curLinksPart,
			  "result_" + i++);
	}
    };
     
})(jQuery);