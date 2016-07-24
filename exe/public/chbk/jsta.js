var SlickX = function(){
}

SlickX.prototype.redraw_viewport = function redraw_viewport() {
    var vp = this.grid.getViewport();
    var from = vp.top;
    var to = vp.bottom;
    if( this.page_size == 0 ){
	this.page_size = to - from + 1;
    }
    from = 0;
    to = (this.page_size * (this.page_num + 1));
    console.log( "from=" + from );
    console.log( "to=" + to );
    this.loader.getDataCount();
}

SlickX.prototype.do_search = function do_search( category_id ) {
    $( this.text_field ).val( category_id );
    this.loader.setSearch( category_id );
    this.redraw_viewport();
//    redraw_viewport();
}    

SlickX.prototype.init = function init( search_field  , sgrid , score , upbtn , downbtn , acinput , items_count_url , items_url , add_item_url ) {
    var self = this;
    this.search_field  = search_field;
    this.sgrid = sgrid;
    this.score = score;
    this.upbtn = upbtn;
    this.downbtn = downbtn;
    this.acinput = acinput;

//    var s;
    this.text_field = search_field;
    this.score = score;
    this.page_num = 0;
    this.page_size = 0;
    this.columns = [
	//        {id: "mpn", name: "name", field: "name", formatter: mpnFormatter, width: 100, sortable: true },
	//        {id: "id", name: "id", field: "id", formatter: brandFormatter, width: 100, sortable: true },
        {id: "name", name: "name"       , field: "name"             , width: 300 , editor: Slick.Editors.Text },
        {id: "id"  , name: "id"         , field: "id"               , width:  80 },
        {id: "desc", name: "Description", field: "short_description", width: 300 , editor: Slick.Editors.LongText},
        {id: "url" , name: "Url"        , field: "url"              , width: 300 , editor: Slick.Editors.Text},
    ];
    this.options = {
        rowHeight: 21,
        editable: true,
        enableAddRow: true,
        enableCellNavigation: true,
	asyncEditorLoading: false,
	autoEdit: false,
//	editCommandHandler: queueAndExecuteCommand
    };
    
    this.loadingIndicator = null;

    var loader = new Slick.Data.RemoteModel( );
    this.loader = loader.initialize( items_count_url , items_url , add_item_url );

    console.log( this.loader.data );
    
    this.grid = new Slick.Grid( this.sgrid , this.loader.data, this.columns, this.options );

    this.grid.setSelectionModel(new Slick.CellSelectionModel());
    this.grid.onAddNewRow.subscribe(function (e, args) {
	var item = args.item;
	if( item["name"] == null || item["desc"] == null || item["url"] == null ){
	    return;
	}
	self.grid.invalidateRow(datax.length);
	self.loader.addData( item["name"] , item["url"] , new Date() );
	self.grid.updateRowCount();
	self.grid.render();
    });

    this.grid.onViewportChanged.subscribe(function (e, args) {
	//	this.prototype.redraw_viewport();
	console.log( self.redraw_viewport() );
	self.redraw_viewport();
//	redraw_viewport();
    });
    this.grid.onSort.subscribe( function (e, args) {
        self.loader.setSort(args.sortCol.field, args.sortAsc ? 1 : -1);
	self.redraw_viewport();
//	redraw_viewport();
    });
    
    this.loader.onDataLoading.subscribe(function () {
        if (!self.loadingIndicator) {
	    self.loadingIndicator = $("<span class='loading-indicator'><label>Buffering...</label></span>").appendTo(document.body);
	    var $g = $( sgrid );
	    self.loadingIndicator
                .css("position", "absolute")
                .css("top", $g.position().top + $g.height() / 2 - self.loadingIndicator.height() / 2)
                .css("left", $g.position().left + $g.width() / 2 - self.loadingIndicator.width() / 2);
        }
        self.loadingIndicator.show();
    });

    this.loader.onDataLoaded.subscribe(function (e, args) {
        for (var i = args.from; i <= args.to; i++) {
	    self.grid.invalidateRow(i);
        }
        self.grid.updateRowCount();
        self.grid.render();
        self.loadingIndicator.fadeOut();
    });
    this.loader.onCountDataLoaded.subscribe(function (e, args) {
	console.log( "onCountDataLoaded=" + args.count );
        self.loader.ensureData( 0 , args.count);
    });

    $( this.text_field ).keyup(function (e) {
        if (e.which == 13) {
	    self.do_search( $(self).val() );
        }
    });

    this.loader.setSearch($( this.text_field ).val());
    this.loader.setSort( this.score , -1);
    this.grid.setSortColumn( this.score , false);
    // load the first page
    this.grid.onViewportChanged.notify();

    $( this.upbtn ).click( function() {
	self.page_num = self.page_num + 1;
	var category_id = $("#txtSearch").val( );
	do_search( category_id );
    } );
    $( this.downbtn ).click( function() {
	if( self.page_num > 0 ){
	    self.page_num = self.page_num - 1;
	}
	var category_id = $("#txtSearch").val( );
	do_search( category_id );
    } );

    // AutoComplete
    $( this.acinput ) . autocomplete( {
        source: function( request, res ){
	    $.ajax({
		url: "/chbk/api",
		type: "POST",
		cache: false,
		dataType: "json",
		data: {q:request.term},
		success: function(o){
		    res(o);
		},
		error: function(xhr, ts, err){
		    res(['']);
		}
	    } );
	},
	search: function(event, ui){
	    if (event.keyCode == 229) return false;
	    return true;
	},
	open: function() {
	    $(self).removeClass("ui-corner-all");
	}
    } )
	.keyup(function(event){
	    if (event.keyCode == 13) {
		$(self).autocomplete('#jquery-ui-autocomplete-input');
	    }
	} );
    
}


var Jst = function(){
}

Jst.prototype.init = function ( slickx , search_field , category_url ){
    var self = this;
    this.slickx = slickx;
    this.search_field  = search_field;

    this.to = false;

    this.jst = $("#jstree").jstree({
	'core' : {
	    'check_callback' : function( operation , node, node_parent, node_position, more ) {
		// operation can be 'create_node', 'rename_node', 'delete_node', 'move_node' or 'copy_node'
		// in case of 'rename_node' node_position is filled with the new node name
		//	return operation === 'rename_node' ? true : false;
		//		var ret = false;
		var ret = true;
		return ret;
	    },
	    'multiple' : false,
	    'error' : function() {
		console.log("error");
	    },
	    'themes' : {
		// default 'expand_selected_onload' : true,
		// default 'workder' : true,
		// default 'force_text' : false,
		// default 'dbclick_toggle' : true,
		'icons' : false,
		'stripes' : true,
		'responsive' : true
	    },

            "data": {
		"url" : category_url,
		'data' : function (node) {
		    return;
		}
	    },

	    "state" : { "key" : "git-git" },
	    "plugins" : [ "dnd" , "contextmenu" , "search" , "state" , "wholerow" ]
	}
    });
    this.jst.on( 'select_node.jstree' , function (e, data) {
	console.log( "select_node" );
	var node = data.instance.get_node( data.selected[0] )
	var path = data.instance.get_path( data.selected[0] , '/' , false );
	var next_dom = data.instance.get_next_dom( data.selected[0] , true );
	var prev_dom = data.instance.get_prev_dom( data.selected[0] , true );
	var json = data.instance.get_json( data.selected[0] , true );
	var inst = data.instance.get_node( data.selected[0] )
	if ( inst !== null ) {
	    var category_id = inst.id;
	    page_num = 0;
	    self.slickx.do_search( category_id );
	}
    });

    this.jst.on( 'move_node.jstree', function(e, n) {
	console.log( "# move_node" );
	console.log( "n.parent=" + n.parent );
	console.log( "n.position=" + n.position );	
	console.log( "n.old_parent=" + n.old_parent );
	console.log( "n.old_position=" + n.old_position );
	console.log( "n.is_multi=" + n.multi );
    }
	  );

    this.jst.on( 'dnd_scroll.vakata' , function(node) {
	console.log( "dnd_scroll.vakata" );
    });
    this.jst.on( 'dnd_start.vakata' , function(node) {
	console.log( "dnd_start.vakata" );
    });
    this.jst.on( 'dnd_move.vakata' , function(node) {
	console.log( "dnd_move.vakata" );
    });
    
    $(document).on( 'dnd_end.vakata' , function(node) {
	console.log( "dnd_end.vakata" );
    });
    this.jst.on( 'model.jstree' , function(nodes, parent) {
	console.log( "model" );
    });
    this.jst.on( 'activate_node.jstree' , function(node) {
	console.log( "active_node" );
    });
    this.jst.on( 'copy_node.jstree' , function(node) {
	console.log( "copy_node" );
    });
    this.jst.on( 'changed.jstree' , function(node , action, selected , event) {
	console.log( "changed" );
    });
    this.jst.on( 'deselect_node.jstree' , function(node , selected , event) {
	console.log( "deselect_node" );
    });
    this.jst.on( 'cut.jstree' , function(node) {
	console.log( "cut" );
    });
    this.jst.on( 'copy.jstree' , function(node) {
	console.log( "copy" );
    });
    this.jst.on( 'paste.jstree' , function(node) {
	console.log( "paste" );
    });
    this.jst.on( 'edit.jstree' , function(node) {
	console.log( "edit" );
    });

    $( this.search_field ).keyup(function ()
		 {
		     if(self.to) { clearTimeout(to); }
		     self.to = setTimeout(function(){
			 var v = $('#category-search').val();
			 //console.log( v );
			// console.log( jst );
			 $('#jstree').jstree(true).search(v);
		     }, 250);
		 }
				);
    
}

$(document).ready(function(){
    var slickx = new SlickX();
    slickx.init( "#txtSearch" , "#myGrid" , "score" , '#upbtn' , '#downbtn' , '#jquery-ui-autocomplete-input' , '/chbk/bookmarks_count' , '/chbk/bookmarks' , '/chbk/add_bookmark');
    // 'http://localhost:4567/chbk/repos'

    var jst = new Jst();
    jst.init( slickx , '#category-search' , '/chbk/categories.json' );

    console.log( slickx.search_field );
});
