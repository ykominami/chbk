(function ($) {

    function inherits(ctor, superCtor) {
	if (ctor === undefined || ctor === null)
	    throw new TypeError('The constructor to `inherits` must not be ' +
                        'null or undefined.');

	if (superCtor === undefined || superCtor === null)
	    throw new TypeError('The super constructor to `inherits` must not ' +
                        'be null or undefined.');

	if (superCtor.prototype === undefined)
	    throw new TypeError('The super constructor to `inherits` must ' +
				'have a prototype.');

	ctor.super_ = superCtor;
	Object.setPrototypeOf(ctor.prototype, superCtor.prototype);
    }

    function objectFromProto(){
	if(typeof Object.create === 'function'){
	    var objectFromProto = function(proto){
		return Object.create(proto);
	    }
	}else{
	    var objectFromProto = function(proto){
		var Temp = function(){};
		Temp.prototype = proto;
		return new Temp();
	    }
	}
    }

    function inheritConstructor(Parent, Constructor, prop){
	Parent = Parent || Object;
	Constructor.prototype = $.extend(objectFromProto(Parent.prototype), prop, {
            __super: Parent.prototype,
            constructor: Constructor
	});
	return Constructor;
    }

//    var self = this;
    /***
     * A sample AJAX data store implementation.
     * Right now, it's hooked up to load search results from Octopart, but can
     * easily be extended to support any JSONP-compatible backend that accepts paging parameters.
     */
    function RemoteModelBase( ) {
    }
    
    RemoteModelBase.prototype.init = function init() {
    }
    
    RemoteModelBase.prototype.isDataLoaded = function isDataLoaded(from, to) {
	for (var i = from; i <= to; i++) {
	    if (this.data[i] == undefined || this.data[i] == null) {
		return false;
	    }
	}
	
	return true;
    }

    RemoteModelBase.prototype.clear = function clear() {
	for (var key in this.data) {
	    delete this.data[key];
	}
	this.data.length = 0;
    }
    
    RemoteModelBase.prototype.getDataCount = function getDataCount() {
	if (this.req) {
	    this.req.abort();
	    this.data_row[0] = undefined;
	}

	var url = null;
	var int_val = parseInt( this.searchstr , 10 );
	if ( isNaN( int_val ) ) {
	    url = this.repos_count_url + "?path=" + this.searchstr;
	}
	else{
	    url = this.repos_count_url + "?category_id=" + int_val;
	}
	if (this.h_request != null) {
	    clearTimeout(this.h_request);
	}
	console.log("getDataCount:" );
	var self = this;
	this.h_request = setTimeout(function () {
	    self.data_row[0] = null; // null indicates a 'requested but not available yet'

	    self.req = $.jsonp({
		url: url,
		callbackParameter: "callback",
		cache: true,
		success: function (json, textStatus, xOptions) {
		    self.onSuccessCount(json)
		},
		error: function () {
		    self.onErrorCount()
		}
	    });
	    
	}, 50);
    }
    RemoteModelBase.prototype.ensureData = function ensureData( from , to) {
	if (this.req) {
	    this.req.abort();
	    for (var i = this.req.fromPage; i <= this.req.toPage; i++) {
		this.data[i * this.PAGESIZE] = undefined;
	    }
	}
	
	if (from < 0) {
	    from = 0;
	}
	    
	if (this.data.length > 0) {
	    to = Math.min(to, this.data.length - 1);
	}
	    
	var fromPage = Math.floor(from / this.PAGESIZE);
	var toPage = Math.floor(to / this.PAGESIZE);
	    
	while (this.data[fromPage * this.PAGESIZE] !== undefined && fromPage < toPage)
	    fromPage++;
	    
	while (this.data[toPage * this.PAGESIZE] !== undefined && fromPage < toPage)
	    toPage--;
	    
	if (fromPage > toPage || ((fromPage == toPage) && this.data[fromPage * this.PAGESIZE] !== undefined)) {
		// TODO:  look-ahead
	    this.onDataLoaded.notify({from: from, to: to});
	    return;
	}

	var recStart = (fromPage * this.PAGESIZE);
	var recCount = (((toPage - fromPage) * this.PAGESIZE) + this.PAGESIZE);
	    
	//      this.url = "/ev/repos?path=" + searchstr ;
	//      this.url = "http://localhost:4567/ev/repos?path=" + searchstr ;
	var url = null;
	var int_val = parseInt( this.searchstr , 10 );
	if ( isNaN( int_val ) ) {
	    url = this.repos_url + "?path=" + this.searchstr + "&start=" + recStart + "&limit=" + recCount;
	}
	else{
	    url = this.repos_url + "?category_id=" + int_val + "&start=" + recStart + "&limit=" + recCount;
	}
	
	if (this.h_request != null) {
	    clearTimeout(this.h_request);
	}
	var self = this;
	this.h_request = setTimeout(function () {
	    for (var i = fromPage; i <= toPage; i++)
		self.data[i * self.PAGESIZE] = null; // null indicates a 'requested but not available yet'

		self.onDataLoading.notify({from: from, to: to});

		self.req = $.jsonp({
		    url: url,
		    callbackParameter: "callback",
		    cache: true,
		    success: function (json, textStatus, xOptions) {
			self.onSuccess(json, recStart)
		    },
		    error: function () {
			self.onError(fromPage, toPage)
		    }
		});
		
		self.req.fromPage = fromPage;
		self.req.toPage = toPage;
	    }, 50);
	}
	
    RemoteModelBase.prototype.onError = function onError(fromPage, toPage) {
	alert("Base:error loading pages " + fromPage + " to " + toPage);
    }
    
    RemoteModelBase.prototype.onSuccess = function onSuccess(json, recStart) {
    }

    RemoteModelBase.prototype.onErrorCount = function onErrorCount() {
    }
    
    RemoteModelBase.prototype.onSuccessCount = function onSuccessCount(json) {
	console.log("onSuccessCount: 0");
	if (json.length > 0) {
	    //	if (json.count > 0) {
	    var results = json
	    //data.length = 100;
	    //data.length = Math.min(parseInt(results.length),1000); // limitation of the API
	    this.data_row.length = 1;
	    this.data_row[0] = { count: results[0].count };
	    console.log("onSuccessCount: 1|" + this.data_row[0].count );	      
	}
	this.req = null;

	this.onCountDataLoaded.notify({ count: results[0].count });
    }
	
    /*
      this.request = y.request;
	  this.from = resp.request.start, to = from + resp.results.length;
	  data.length = Math.min(parseInt(resp.hits),1000); // limitation of the API
	  
	  for (this.i = 0; i < resp.results.length; i++) {
          this.item = resp.results[i].item;
	  
          data[from + i] = item;
          data[from + i].index = from + i;
	  }
	  
	  req = null;
	  
	  onDataLoaded.notify({from: from, to: to});
	  }
    */
    
    RemoteModelBase.prototype.reloadData = function reloadData(from, to) {
	for (var i = from; i <= to; i++)
	    delete this.data[i];

	this.ensureData(from, to);
    }

    RemoteModelBase.prototype.setSort = function setSort(column, dir) {
	this.sortcol = column;
	this.sortdir = dir;
	this.clear();
    }
    RemoteModelBase.prototype.setSearch = function setSearch(str) {
	this.searchstr = str;
	this.clear();
    }
    
    RemoteModelBase.prototype.initialize = function initialize( repos_count_url , repos_url ) {
	// private
	var PAGESIZE = 30;
	this.data = {length: 0};
	this.data_row = {length: 0};
	this.searchstr = "";
	this.sortcol = null;
	this.sortdir = 1;
	this.h_request = null;
	this.req = null; // ajax request

	// events
	this.onDataLoading = new Slick.Event();
	this.onDataLoaded = new Slick.Event();
	this.onCountDataLoaded = new Slick.Event();

	// variables
	this.repos_count_url = repos_count_url;
	this.repos_url = repos_url;

	// initialize method
	this.init();

	return {
	    // properties
	    "data": this.data,
	    "data_row": this.data_row,

	    // methods
	    "clear": this.clear,
	    "isDataLoaded": this.isDataLoaded,
	    "ensureData": this.ensureData,
	    "getDataCount": this.getDataCount,
	    "reloadData": this.reloadData,
	    "setSort": this.setSort,
	    "setSearch": this.setSearch,

	    "onSuccess": this.onSuccess,
	    "onError": this.onError,
	    "onSuccessCount": this.onSuccessCount,
	    "onErrorCount": this.onErrorCount,
	    
	    // events
	    "onDataLoading": this.onDataLoading,
	    "onDataLoaded": this.onDataLoaded,
	    "onCountDataLoaded": this.onCountDataLoaded,

	    // variables
	    "repos_count_url": this.repos_count_url,
	    "repos_url": this.repos_url,
	    "PAGESIZE": PAGESIZE 
	    
	};
    }

    // Slick.Data.RemoteModel
    $.extend(true, window, { Slick: { Data: {
	RemoteModelBase: RemoteModelBase,
	inherits: inherits
    }}});
})(jQuery);
