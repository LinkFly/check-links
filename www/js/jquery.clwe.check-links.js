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

	//Get all link urls
	var universalEscape = function(url){
	    //	    var changeStr = function
	    var resStr = "";
	    //	    $.each(resStr, function(index, ch){
	    //		    resStr +=
	    return escape(url.trim(" "))
	    .replace("%25","%")
	    .replace(/[?]/g, "%3F")
	    .replace(/[/]/g, "%2F");
	};

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

	var bIsMarking = -arLinksParts.length;
	var asyncLoadBuff = function(servUrl, buffName, paramName, urls){	    
	    $.getScript(servUrl + "?" + paramName + "=" + urls, function(data, textStatus){
		    $(buffName).append($(data));
		    bIsMarking++;
		    if(bIsMarking == 0) markingAllLinks();
		}); //$.getScript  
	}; //function asyncLoadBuff

	curLinksPart = "";	
	while(null != (curLinksPart = arLinksParts.pop())){
	    asyncLoadBuff(params.serviceUrl, 
			  buffName,
			  ops.postParamName,
			  curLinksPart);
	}
    };
})(jQuery);