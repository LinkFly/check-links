(function ($){
    $.checkLinks = function(params){
	// Options for configurations (dependence of server side)
	var ops = {resultClass: "check-links_result-data",
		   linkClass: "check-links_link",
		   linkUrl: "link_url",
		   linkValid: "link_valid-p",
	           postParamName: "urls",
	           goodLinkClass: "goodlink",
	           badLinkClass: "badlink"};
	/////////////////////////////////

	// Configure ops for work - add point to begin.
	$.each(ops, function(key, val){
		ops[key] = "." + val; 
	    });	
	// Exclude for:
	ops.goodLinkClass = ops.goodLinkClass.substr(1);
	ops.badLinkClass = ops.badLinkClass.substr(1);
	ops.postParamName = ops.postParamName.substr(1);

	// Parameters checking
	if(params.serviceUrl == undefined) {
	    alert("check-links: bad call parameters");
	    return;
	}
	/////////////

	//Create buffer for check links result
	var buffName = "check-links-buff";
	$("<div id='" + buffName + "' style='display: none'/>").appendTo("body");
	buffName = "#" + buffName;

	///////// Main work /////////////////	
	/*
	var universalEscape = function(url){
	    return 
	      escape(unescape(url.trim(" ")))
	        .replace(/[?]/g, "%3F")
	        .replace(/[/]/g, "%2F");
	}
	*/

	

	var nonHex = function(ch){
	    var hexSyms = ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","F"];
	    for(idx in hexSyms)
		if (ch.toUpperCase() == hexSyms[idx]) return false;
	    return true;
	}; //function nonHex
	
	/*
	var universalEscape = function(url){
	    var prepStr = escape(url.trim(" ")).replace("%25", "%");	                            
	    var prepStrLen = prepStr.length;
	    var res = "";
	    $.each(prepStr,		   
	           function(index, ch){
		       switch(ch){
		       case "?": res += "%3F"; break;
		       case "/": res += "%2F"; break;
		       case "%": 
			   if((index < prepStrLen - 2) 
			      && nonHex(prepStr[index+1])
			      && nonHex(prepStr[index+2]))
			       {res += "%25"}; break; 
		       default: res += ch;
		       }; //switch		       
		   }); //$.each
	    return res;
	}; //universalEscapeExp
	*/	    
	
	
	var universalEscape = function(url){
	    return escape(unescape(url.trim(" ")))
	             .replace(/[/]/g, "%2F");
	};

	/*
	var universalEscape = function(url){
	    return escape(url.trim(" "))
	    .replace("%25","%")
	    .replace(/[?]/g, "%3F")
	    .replace(/[/]/g, "%2F");
	};
	*/

	//Get all link urls
	var allLinksHash = {};//new Array();
	$("a").each(function(index, el){
		allLinksHash[
		   universalEscape($(el).attr("href"))] = $(el);
		  
	    });

	var markingAllLinks = function(){
            $(buffName + " " + ops.resultClass + " " + ops.linkClass)
              .each(function(index, el){
		      // $("a[href=" + $(ops.linkUrl, el).html() + "]")
		      var escLink = universalEscape(
					   $(ops.linkUrl, el).text());
		      if(allLinksHash[escLink] != undefined)
			allLinksHash[escLink]
			    .removeClass(ops.goodLinkClass + " " + ops.badLinkClass)
			    .addClass($(".link_valid-p", el).html() == "true" ? "goodlink" : "badlink");
              }); //.each
	}; //function markingAllLinks

	var maxLenLinksPart = 300;
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

	$.each(allLinksHash, function(curLink){
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
	document.results = {testkey: "data"};
	var asyncLoadBuff = function(servUrl, buffName, paramName, urls, varNameForResult){	    
	    servUrl = "http://localhost:81/check-links/json.js";
	    $.getScript(servUrl + "?"
				   + paramName + "=" + urls				 
				   + "&varName=" + "document.results." + varNameForResult, 
			function(data, textStatus, xhttp){
			    //alert(document.results[varNameForResult]);
		    //   console.log("data is: " + xmlreq.responseText);
		    //console.log("xhttp is: " + xhttp.responseText);
		    $(buffName).append($(document.results[varNameForResult]));
		    document.results[varNameForResult] = undefined;
		    bIsMarking++;
		    if(bIsMarking == 0) markingAllLinks();
		    }); //$.getScript  
	}; //function asyncLoadBuff

	curLinksPart = "";	
	countStartLoadBuff = 0;
	results = {};
	while(null != (curLinksPart = arLinksParts.pop())){
	    asyncLoadBuff(params.serviceUrl, 
			  buffName,
			  ops.postParamName,
			  curLinksPart,
			  "result_" + i++);
	}
    };
})(jQuery);