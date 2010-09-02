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

	/*
	var isAbsoluteUrl = function(url){
	    var fstChar = url.substr(0,1);
	    var protocol = url.substr(0, url.search("://"));       
	    return (fstChar == "/") || ((protocol == "http") || (protocol == "https"))	  
	}

	var absolutingUrl = function(url){
	    // return url;
	    if(isAbsoluteUrl(url)) return url;
	    
	    var docHref = document.location.toString();
	    var docPath = docHref.substr(0, 1 + docHref.lastIndexOf("/"));	    
	    return docPath + url;   
	}
	*/
	
	///////// Main work ////////

	//Get all link urls
	var sLinks = "";
	$("a").each(function(index, el){
		sLinks += $(el).attr("href")
		               .trim(" ")
		               .replace(/[?]/g, "%3F")
		               .replace(/&/g, escape("&"))
		               .replace(/#/g, escape("#"))
		               + "%0A";    
	    });

	//Create object for request 
	var reqObj = {};
	reqObj[ops.postParamName] = sLinks;
	// reqObj["base-url"] = "http://localhost/_borders/";

	//$.post("http://localhost:81/debug/check-links/for-links", {urls: "http://google.ru http://badlink-this-very-not-work-link.ru"}, function(data){alert(data);});
	//$.post = function(url, data, success, dataType){$.ajax({type: 'POST',url: url,data: data,success: success, dataType: dataType})};
	//$.getScript("http://localhost:81/debug/check-links/for-links-js-proxy.js?urls=http://google.ru+http://badlink-this-very-not-work-link.ru", function(data){alert(checkLinksResult);})

	//Asynchronous HTTP POST request
	//	$.post(params.serviceUrl,
	//  reqObj,
        //  function(data, textStatus, XMLHttpRequest){
	//	   alert(data);
        //    $(buffName).html(data);
	var markingAllLinks = function(){
	    var allLinksHash = {};
	    var universalEscape = function(url){
		return escape(url.trim(" ")).replace("%25","%");};
	    $("a").each(function(index, el){
		    allLinksHash[
				 universalEscape(
					$(el).attr("href") )]
			= $(el);
	    });

            $(buffName + " " + ops.resultClass + " " + ops.linkClass)
              .each(function(index, el){
		      // $("a[href=" + $(ops.linkUrl, el).html() + "]")
		      var escLink = universalEscape(
					   $(ops.linkUrl, el).html());
		      if(allLinksHash[escLink] != undefined)
			allLinksHash[escLink]
			    .removeClass(ops.goodLinkClass + " " + ops.badLinkClass)
			    .addClass($(".link_valid-p", el).html() == "true" ? "goodlink" : "badlink");
              }); //.each
	}; //function markingAllLinks

	var prepareLink = function(link){
	  return link.trim(" ")
	        .replace(/[?]/g, "%3F")
	        .replace(/&/g, escape("&"))
	        .replace(/#/g, escape("#"));	    
	};
	
	var maxLenLinksPart = 1500;
	var arLinksParts = new Array();
	var arAllPreparedLinks = new Array();
	$("a").each(function(index, el){
		arAllPreparedLinks.push(
		  prepareLink($(el).attr("href")));
	    });
	var curLink;
	var curLenLinksPart = 0;
	var curLinksPart = "";
	while(null != (curLink = arAllPreparedLinks.pop())){
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
	} //while
	arLinksParts.push(curLinksPart);

	var asyncLoadBuff = function(servUrl, buffName, paramName, urls, fnMarking){
	    $.getScript(servUrl + "?" + paramName + "=" + urls, function(data, textStatus){
		    $(buffName).append($(data));
		    if(fnMarking != undefined) fnMarking();
		}); //$.getScript  
	}; //function asyncLoadBuff

	curLinksPart = "";	
	while(null != (curLinksPart = arLinksParts.pop())){
	    asyncLoadBuff(params.serviceUrl, 
			  buffName,
			  ops.postParamName,
			  curLinksPart, 
			  arLinksParts.length == 0 ? markingAllLinks : undefined);
	}
	/*	
	$.getScript(params.serviceUrl + "?urls=" + sLinks, function(data, textStatus){
		//		alert("textStatus: " + textStatus + " data: " + data);
		alert(data);
		$(buffName).append($(data));
		if(buffIsFull) markingAllLinks();
//        }); //$.post
	  }); //$.getScript  
	*/
    };
})(jQuery);