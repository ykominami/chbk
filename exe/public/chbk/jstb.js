"use strict";

class SlickX {
    constructor( search_field  , sgrid , score , upbtn , downbtn , acinput , items_count_url , items_url , add_item_url ) {
	var self = this;
	self.search_field  = search_field;
	self.sgrid = sgrid;
	self.score = score;
	self.upbtn = upbtn;
	self.downbtn = downbtn;
	self.acinput = acinput;
	
	//    var s;
	self.text_// FIXME: eld = search_field;
	self.score = score;
	self.page_num = 0;
	self.page_size = 0;
	self.columns = [
	    //        {id: "mpn", name: "name", field: "name", formatter: mpnFormatter, width: 100, sortable: true },
	//        {id: "id", name: "id", field: "id", formatter: brandFormatter, width: 100, sortable: true },
            {id: "name", name: "name"       , field: "name"             , width: 300 , editor: Slick.Editors.Text },
            {id: "id"  , name: "id"         , field: "id"               , width:  80 },
            {id: "desc", name: "Description", field: "desc", width: 300 , editor: Slick.Editors.Text},
            {id: "url" , name: "Url"        , field: "url"              , width: 300 , editor: Slick.Editors.Text},
	];
	self.options = {
            rowHeight: 21,
            editable: true,
            enableAddRow: true,
            enableCellNavigation: true,
	    asyncEditorLoading: false,
	    autoEdit: false,
	    //	editCommandHandler: queueAndExecuteCommand
	};
	
	self.loadingIndicator = null;
	
	self.dataView = new Slick.Data.DataView();
	
	self.loader = new Slick.Data.RemoteModel( items_count_url , items_url , add_item_url );
	
	console.log( self.loader.data );
	
	self.dataView.setItems(self.loader.data);
	self.dataView.onRowCountChanged.subscribe(function (e, args) {
	    console.log("onRowCountChanged");
	    self.grid.updateRowCount();
	    self.grid.render();
	});
	self.dataView.onRowsChanged.subscribe(function (e, args) {
	    console.log("onRowsChanged");
	    self.grid.invalidateRows(args.rows);
	    self.grid.render();
	});
	//    self.grid = new Slick.Grid( self.sgrid , self.loader.data, self.columns, self.options );

	self.grid = new Slick.Grid( self.sgrid , self.dataView, self.columns, self.options );
	
	self.grid.setSelectionModel(new Slick.CellSelectionModel());
//	self.grid.setSelectionModel(new Slick.RowSelectionModel());
	self.grid.onAddNewRow.subscribe(function (e, args) {
	    console.log("onAddNewRow");
	    var item = args.item;
	    console.log("id=" + item["id"]);
	    console.log("name=" + item["name"]);
	    console.log("desc=" + item["desc"]);
	    console.log("url=" + item["url"]);
	    
	    console.log("onAddNewRow 2");
	    self.grid.invalidateRow(self.loader.data.length);
	    var name = item["name"];
	    if( name == null ){
		name = "";
	    }
	    var desc = item["desc"];
	    if( desc == null ){
		desc = "";
	    }
	    var url = item["url"];
	    if( url == null ){
		url = "";
	    }
	    if ( item["id"] === void 0 ){
		self.loader.addData( "" , name , desc , url , Math.trunc( Date.now() / 1000 ) );
	    }
	    else{
		self.dataView.addItem( item );
		self.dataView.syncGridSelection( self.grid , true , true );
		self.grid.updateRowCount();
		self.grid.render();
		self.loader.addData( item["id"] , name , desc , url , Math.trunc( Date.now() / 1000 ) );
	    }
	});
	
	//    self.grid.onViewportChanged.subscribe(function (e, args) {
	//	//	self.prototype.redraw_viewport();
	//	console.log( self.redraw_viewport() );
	//	self.redraw_viewport();
	// //	redraw_viewport();
	//    });
	//    self.grid.onSort.subscribe( function (e, args) {
	//        self.loader.setSort(args.sortCol.field, args.sortAsc ? 1 : -1);
	//	self.redraw_viewport();
	//	redraw_viewport();
	//    });
	
	self.loader.onDataLoading.subscribe(function () {
	    console.log("onDataLoading");
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
	
	self.loader.onDataLoaded.subscribe(function (e, args) {
	    console.log("onDataLoaded");
	    self.dataView.setItems(self.loader.data);
	    /*	
		for (var i = args.from; i <= args.to; i++) {
		self.grid.invalidateRow(i);
		}
		self.grid.updateRowCount();
		self.grid.render();
	    */
            self.loadingIndicator.fadeOut();
	});
	self.loader.onCountDataLoaded.subscribe(function (e, args) {
	    console.log( "onCountDataLoaded=" + args.count );
            self.loader.ensureData( 0 , args.count);
	});
	self.loader.onAddBookmarkDataLoaded.subscribe(function (e, args) {
	    console.log( "onAddBookmarkDataLoaded=" + args.original_id );
	    //            self.loader.ensureData( 0 , args.length);
	    if( args.original_id == "" ){
		console.log( "onAddBookmarkDataLoaded 1 =" + args.original_id );
		self.dataView.addItem( { "id": args["id"] , "name": args["name"] , "desc": args["desc"] , "url": args["url"] } );
	    }
	    else{
		if( args.original_id != args.id ){
		    console.log( "onAddBookmarkDataLoaded 21 =" + args.original_id );
		    self.dataView.deleteItem( args.original_id );
		    self.dataView.addItem( { "id": args["id"] , "name": args["name"] , "desc": args["desc"] , "url": args["url"] } );
		}
		else{
		    console.log( "onAddBookmarkDataLoaded 22 =" + args.original_id );
		}
	    }
	});
	
	$( self.text_field ).keyup(function (e) {
            if (e.which == 13) {
		self.do_search( $(this).val() );
            }
	});
	
	self.loader.setSearch($( self.text_field ).val() );
	self.loader.setSort( self.score , -1 );
	self.grid.setSortColumn( self.score , false );
	// load the first page
	//    self.grid.onViewportChanged.notify();
	
	$( self.upbtn ).click( function() {
	    self.page_num = self.page_num + 1;
	    var category_id = $("#txtSearch").val( );
	    do_search( category_id );
	} );
	$( self.downbtn ).click( function() {
	    if( self.page_num > 0 ){
		self.page_num = self.page_num - 1;
	    }
	    var category_id = $("#txtSearch").val( );
	    do_search( category_id );
	} );
	
	// AutoComplete
	$( self.acinput ) . autocomplete( {
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
		$(this).removeClass("ui-corner-all");
	    }
	} )
	    .keyup(function(event){
		if (event.keyCode == 13) {
		    $(this).autocomplete('#jquery-ui-autocomplete-input');
		}
	    } );
    }

    redraw_viewport() {
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
    
    do_search( category_id ) {
	$( this.text_field ).val( category_id );
	this.loader.setSearch( category_id );
	this.redraw_viewport();
	//    redraw_viewport();
    }    
}
    
class Jst {    
    constructor( slickx , search_field , category_url ){
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
	
	$( // TODO:
	    this.search_field ).keyup(function ()
	    {
		if(this.to) { clearTimeout(to); }
		this.to = setTimeout(function(){
		    var v = $('#category-search').val();
		    //console.log( v );
		    // console.log( jst );
		    $('#jstree').jstree(true).search(v);
		}, 250);
	    }
	);
    }
}

$(document).ready(function(){
    var slickx = new SlickX( "#txtSearch" , "#myGrid" , "score" , '#upbtn' , '#downbtn' , '#jquery-ui-autocomplete-input' , '/chbk/bookmarks_count' , '/chbk/bookmarks' , '/chbk/add_bookmark');
    // 'http://localhost:4567/chbk/repos'

    var jst = new Jst( slickx , '#category-search' , '/chbk/categories.json' );
    
    console.log( slickx.search_field );
});
