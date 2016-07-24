(function ($) {

    function RemoteModel( ) {
	Slick.Data.RemoteModelBase.call(this)
    }
    
//    var RemoteModel = function RemoteModel( list_count_url , list_url ){
//	Slick.Data.RemoteModel.apply( this, [list_count_url , list_url] );
//	return Slick.Data.RemoteModel.call( this, [list_count_url , list_url] );
//    };
//    RemoteModel = inheritConstructor(Slick.Data.RemoteModelBase , function RemoteModel(){}, {});

    // 正しい継承
    Slick.Data.inherits(RemoteModel, Slick.Data.RemoteModelBase);
    //    RM.prototype.constructor = RM;

    RemoteModel.prototype.addData = function addData( name , url , add_date ) {
	console.log("addData");

	if (this.category_id == null && this.path == null) {
	    return;
	}

	if (this.req) {
	    this.req.abort();
	    this.data = undefined;
	    /*
	    this.data = { index: 0 };
	    this.data[0].id = item.id
	    this.data[0].name = item.name;
	    this.data[0].url = item.url;
	    */
	}

	var send_data = {
	    name: name,
	    url: encodeURIComponent( url ),
	    add_date: add_date
	}

	if (this.category_id == null) {
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
		self.data = { length: 0 }
	    }
	    else if( self.data === undefined ) {
		self.data = { length: 0 }
	    }
	    self.data[0] = null; // null indicates a 'requested but not available yet'

	    self.req = $.ajax({
		data: send_data,
//		type: "POST",
		type: "GET",
		url: self.add_item_url,
		cache: true,
		success: function (data, dataType) {
		    // this;
		    self.onSuccess(json, recStart)
		},
		error: function (XMLHttpRequest, textStatus, errorThrown) {
		    self.onError(fromPage, toPage)
		}
	    });

	}, 50);

    }


    RemoteModel.prototype.onSuccess = function(json, recStart) {
	var recEnd = recStart;
	if (json.length > 0) {
	    //	if (json.count > 0) {
	    var results = json
	    recEnd = recStart + results.length;
	    //data.length = 100;
	    //data.length = Math.min(parseInt(results.length),1000); // limitation of the API
	    this.data.length = Math.min(recEnd,1000);
	    for (var i = 0; i < results.length; i++) {
		var item = results[i];

		this.data[recStart + i] = { index: recStart + i };
		this.data[recStart + i].id = item.id
		this.data[recStart + i].name = item.name;
		this.data[recStart + i].url = item.url;
	    }
	}
	req = null;

	this.onDataLoaded.notify({from: recStart, to: recEnd});
    }

    RemoteModel.prototype.onError = function (fromPage, toPage) {
	alert("Chbk:error loading pages " + fromPage + " to " + toPage);
    }

    $.extend(true, window, { Slick: { Data: { RemoteModel: RemoteModel }}});
})(jQuery);
    
