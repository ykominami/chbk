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
    
