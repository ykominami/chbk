(function ($) {
    class RemoteModel extends Slick.Data.RemoteModelBase {
	//	Slick.Data.RemoteModelBase.call(this)
	constructor(items_count_url , items_url , add_item_url){
	    super(items_count_url , items_url , add_item_url);
	    this.data_count = [];
	    this.data_addbookmark = [];
	    this.onAddBookmarkDataLoading = new Slick.Event();
	    this.onAddBookmarkDataLoaded = new Slick.Event();
	}
	
	addData( id , name , desc , url , add_date ) {
	    console.log("addData");

	    if (this.category_id == null && this.path == null) {
		return;
	    }
	    
	    if (this.req) {
		this.req.abort();
		this.data_addbookmark = undefined;
	    }

	    var send_data = {
		id: id,
		name: name,
		desc: desc,
		url: encodeURIComponent( url ),
		add_date: add_date
	    }

	    if ( this.category_id == null) {
		$.extend( send_data , { path: this.path } );
	    }
	    else{
		$.extend( send_data , { category_id: this.category_id } );
	    }

	    if (this.h_request != null) {
		clearTimeout(this.h_request);
	    }
	    var self = this;
	    this.h_request = setTimeout(function () {
		//	    this.data = {length: 0};
		if( ( "data" in self ) === false ){
		    self.data_addbookmark = [];
		}
		else if( self.data === undefined ) {
		    self.data_addbookmark = [];
		}
		self.data_addbookmark[0] = null; // null indicates a 'requested but not available yet'

		self.req = $.ajax({
		    data: send_data,
		    //		type: "POST",
		    type: "GET",
		    url: self.add_item_url,
		    cache: true,
		    success: function (data) {
			// this;
			self.onAddBookmarkSuccess( data );
		    },
		    error: function (XMLHttpRequest, textStatus, errorThrown) {
			self.onAddBookmarkError( data );
		    }
		});
	    }, 50);
	}

	onAddBookmarkSuccess (json) {
	    console.log("onAddBookmarkSuccess");
	    console.log("json.length=" + json.length );
	    if (json.length > 0) {
		//	if (json.count > 0) {
		var results = json
		this.data_addbookmark.length = results.length;
		for (var i = 0; i < results.length; i++) {
		    console.log("i=" + i);
		    var item = results[i];
		    
		    this.data[i] = { index: i };
		    this.data[i].original_id = item.original_id
		    this.data[i].id = item.id
		    this.data[i].name = item.name;
		    this.data[i].desc = item.desc;
		    this.data[i].url = item.url;
		}
	    }
	    this.req = null;

	    this.onAddBookmarkDataLoaded.notify( this.data[0] );
	}

	onAddBookmarkError(json) {
	    alert("Chbk:error onAddBookmarkError");
	}

	onSuccess(json, recStart) {
	    console.log("onSuccess");
	    console.log("json.length=" + json.length );
	    console.log("recStart=" + recStart );
	    var recEnd = recStart;
	    if (json.length > 0) {
		//	if (json.count > 0) {
		var results = json
		recEnd = recStart + results.length;
		this.data.length = Math.min(recEnd,1000);
		for (var i = 0; i < results.length; i++) {
		    console.log("i=" + i);
		    var item = results[i];

		    this.data[recStart + i] = { index: recStart + i };
		    this.data[recStart + i].id = item.id
		    this.data[recStart + i].name = item.name;
		    this.data[recStart + i].url = item.url;
		}
	    }
	    this.req = null;

	    this.onDataLoaded.notify({from: recStart, to: recEnd});
	}

	onError(fromPage, toPage) {
	    alert("Chbk:error loading pages " + fromPage + " to " + toPage);
	}
	/*
	  RemoteModel.prototype.initialize = function initialize( id , name , desc , url , add_date ) {
	  var super_inst = this.super_.initialize( id , name , desc , url , add_date );
	  super_inst.data_count = [];

	  return super_inst;
	  }
	*/    
    }
    $.extend(
	true, window, { Slick: { Data: { RemoteModel: RemoteModel }}	 }
    );
})(jQuery);
    
