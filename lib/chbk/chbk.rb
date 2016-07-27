# -*- coding: utf-8 -*-
require 'arxutils'
require 'forwardable'
require 'chbk/relation'

module Chbk
  class Chbk
    extend Forwardable
    include Arxutils
    
    def_delegator( :@hierop , :register, :register_categoryhier )
    def_delegator( :@hierop , :get_category_hier_json , :get_category_hier_json )

    def set_mode( mode = :MIXED_MODE )
      @mode = mode
      # :TRACE_MODE
      # :ADD_ONLY_MODE
      # :DELETE_ONLY_MODE
      # :MIXED_MODE (default value)

      case @mode
      when :TRACE_MODE
        @tsg.trace
      when :ADD_ONLY_MODE
        @tsg.reset
      when :DELETE_ONLY_MODE
        @tsg.reset
      else
        # :MIXED_MODE
        @tsg.reset
      end
    end

    def initialize( kind , hs )
      # HierOpはArxutilsで定義されている階層構造表すテーブルに対する操作を行うクラス
      @hierop = HierOp.new( "category_id" , :name , "category" , Category , Categoryhier, Currentcategory , Invalidcategory )

      @mode = :MIXED_MODE
      @tsg = TransactStateGroup.new( :category , :bookmark , :url )
      
      @ignore_lines = 1
      @ignore_lines_category = 0

      @input_bookmark_file = nil
      @input_category_file = nil
      
      @bminfo_array = []
      @categoryinfo_array = []

      @bookmarkinfo = Struct.new("BookmarkInfo", :category, :name, :url , :add_date)
      @categoryinfo = Struct.new("CategoryInfo", :name, :add_date, :last_modified)

      Store.init( kind , hs ){ | register_time |
        @count = Count.create( countdatetime: register_time )
      }

      @management = nil
      restore_management
    end

    def load_bookmark_file( in_file )
      @input_bookmark_file = load_file( in_file )
    end
    
    def load_category_file( in_file )
      @input_category_file = load_file( in_file )
    end

    def set_add_date_if_need( add_date )
      @latest_add_date = add_date if add_date != nil and add_date > @latest_add_date
    end

    def set_last_modified_if_need( last_modified )
      @latest_last_modified = last_modified if last_modified != nil and last_modified > @latest_last_modified
    end
    
    def get_all_bm
      if @bminfo_array.size == 0
        array = @input_bookmark_file.readlines
        if array.first =~ /^category/
          #            array.shift(@ignore_lines)
          array.shift
        end
        count = 0
        @bminfo_array = array.reduce([]){ |ary, line|
          begin
            category, name, url, add_date, tmp_ignore = line.chomp.split("\t")
            if add_date != nil and add_date !~ /^\s*$/
              add_date = add_date.to_i
              it = @@bookmarkinfo.new( category, name, url, add_date )
              set_add_date_if_need( it.add_date ) if it.add_date != nil
              ary << it
            end
          rescue => ex
            puts ex.message
            puts ary
            puts "Exit!!"
            exit
          end
          ary
        }
      end
    end

    def get_all_category
      if @categoryinfo_array.size == 0
        count = 0
        array = @input_category_file.readlines
        @categoryinfo_array = array.reduce([]){ |ary, line|
          name, add_date, last_modified, tmp_ignore = line.chomp.split("\t")
          add_date, last_modified = normalize_to_integer( add_date, last_modified )
          if name != nil and add_date != nil
            it = @categoryinfo.new( name, add_date, last_modified )
            set_add_date_if_need( it.add_date )
            set_last_modified_if_need( it.last_modified )
            ary << it
          end
          ary
        }
      end
    end
    
    def list_bookmark
      get_all_bm
      @bminfo_array.map{|bookmarkinfo|
        case @mode
        when :TRACE_MODE
          register_bookmark(  bookmarkinfo.category , bookmarkinfo.name , bookmarkinfo.url , bookmarkinfo.add_date )
        else
          add_bookmark(  bookmarkinfo.category , bookmarkinfo.name , bookmarkinfo.url , bookmarkinfo.add_date )
        end
      }
    end

    def list_category
      get_all_category
      @categoryinfo_array.map{|x|
        register_category(  x.name , x.add_date , x.last_modified )
      }
    end

    def need_update_management?
      @latest_add_date > @prev_latest_add_date or @latest_last_modified > @prev_latest_last_modified
    end
    
    def setup_management
      unless @management
        begin
          @management = Management.find(1)
        rescue
          # レコードが0個の場合、例外が発生する
        end
        @management = Management.create( add_date: 0 , last_modified: 0 ) unless @management
      end
    end
    
    def restore_management
      setup_management
      @prev_latest_add_date = @latest_add_date = @management.add_date
      @prev_latest_last_modified = @latest_last_modified = @management.last_modified
    end

    def update_management( add_date , last_modified ) 
      @management.update( add_date: add_date , last_modified: last_modified ) 
    end
    
    def register_category( category_name , add_date = nil, last_modified = nil )
      category_id = nil
      current_category = nil
      hs = {}
      hs[:add_date] = add_date if add_date
      hs[:last_modified] = last_modified if last_modified

      current_category = @hierop.current_klass.find_by( name: category_name )
      if current_category
        category_id = current_category.org_id
        if hs.size > 0
          update_integer( current_category.category , hs )
        end
      else
        begin
          category = @hierop.base_klass.create( name: category_name , add_date: add_date, last_modified: last_modified )
          category_id = category.id
        rescue => ex
          p "In add_category"
          p ex.class
          p ex.message
          pp ex.backtrace
          exit
          
          category_id = nil
        end
      end

      if category_id
        @tsg.category.add( category_id )
      end
      
      category_id
    end

    def ensure_categoryhier
      @hierop.base_klass.pluck(:name).map{|x|
        register_categoryhier( x )
      }
    end
    
    def get_add_date_from_management
      Management.find(1).add_date
    end

    def get_last_modified_from_management
      Management.find(1).last_modified
    end

#    def register_bkattr( bookmark_id = nil , desc = nil , attr1 = nil, attr2 = nil, attr3 = nil )
    def register_bkattr( args )
      puts "register_bkattr"
      bookmark_id = args[:bookmark_id]
      desc = args[:desc]
      attr1 = args[:attr1]
      attr2 = args[:attr2]
      attr3 = args[:attr3]

      p bookmark_id
      p desc

      bkattr = nil
      begin
        bkattr = Bkattr.find_by( bookmark_id: bookmark_id )
      rescue => ex
        # do nothing
      end
      hs = { bookmark_id: bookmark_id , :desc => desc }
      hs[:attr1] = attr1 if attr1
      hs[:attr2] = attr2 if attr2
      hs[:attr3] = attr3 if attr3

      if bkattr
        bkattr.update( hs )
      else
        p hs
        bkattr = Bkattr.create( hs )
      end
      bkattr
    end

    def add_bookmark_with_bookmark_id( orginal_bookmark_id , category_name , name , desc, url , add_date = nil )
      category_id = register_category( category_name )
      add_bookmark_with_bookmark_id_by_category_id( orginal_bookmark_id , category_id , name , desc, url , add_date = nil )
    end

    def add_bookmark_with_bookmark_id_by_category_id( original_bookmark_id , category_id , name , desc, url , add_date = nil )
      bkattr = nil
      url_id = register_url( url )
      bookmark = Bookmark.create( category_id: category_id, name: name, url_id: url_id, add_date: add_date )
      bookmark_id = bookmark.id
      puts "bookmark_id=#{bookmark_id}"
      puts "desc=#{desc}"
      bkattr = register_bkattr( bookmark_id: bookmark.id , desc: desc ) if desc

      JSON(
        [ { "original_id" => original_bookmark_id , "id" => bookmark_id , "name" => bookmark.name , "desc" => bkattr ? bkattr.desc : nil , "url" => bookmark.url.val } ]
      )
    end

    def add_bookmark( category_name , name , desc, url , add_date = nil )
      category_id = register_category( category_name )
      add_bookmark_by_category_id( category_id , name , desc, url , add_date = nil )
    end

    def add_bookmark_by_category_id( category_id , name , desc, url , add_date = nil )
      url_id = register_url( url )
      bookmark = Bookmark.create( category_id: category_id, name: name, url_id: url_id, add_date: add_date )
      bookmark_id = bookmark.id
      puts "bookmark_id=#{bookmark_id}"
      puts "desc=#{desc}"
      register_bkattr( bookmark_id: bookmark.id , desc: desc ) if desc

      JSON(
        [ { "id" => bookmark_id , "name" => bookmark.name , "desc" => bookmark.bkattr ? bookmark.bkattr.desc : nil , "url" => bookmark.url.val } ]
      )
    end

    def update_bookmark_by_category_id( category_id , name , desc, url )
      url_id = register_url( url )
      bookmark = current_bookmark.bookmark.update( category_id: category_id, name: name, url_id: url_id )
      register_bkattr( bookmark_id: bookmark.id , desc: desc ) if desc
    end

    def register_bookmark_with_bookmark_id( bookmark_id, category_name , name , desc, url , add_date = nil )
      category_id = register_category( category_name )
      register_bookmark_with_bookmark_id_by_category_id( bookmark_id, category_id , name , desc, url , add_date )
    end

    def register_bookmark_by_category_id( bookmark_id, category_id , name , desc, url , add_date )
      current_bookmark = Currentbookmark.find( bookmark_id )
      if current_bookmark
        bookmark = update_bookmark_by_category_id( category_id , name , desc, url )
      else
        bookmark = add_bookmark_by_category_id( category_id , name , desc, url , add_date )
      end
      bookmark
    end

    def register_url( val )
      url_id = nil
      current_url = Currenturl.find_by( val: val )
      if current_url
        url_id = current_url.org_id
      else
        begin
          url = Url.create( val: val )
          url_id = url.id
        rescue => ex
          puts "In add"
          p ex.class
          p ex.message
          pp ex.backtrace
          exit

          current_url = nil
        end
      end

      if url_id
        @tsg.url.add( url_id )
      end

      url_id
    end

    def register_bookmark( category_name , name , url , add_date = nil )
      category_id = register_category( category_name )
      url_id = register_url( url )
      current_bookmark = Currentbookmark.find_by( category_id: category_id , url_id: url_id , add_date: add_date)
      if current_bookmark
        bookmark_id = current_bookmark.org_id
      else
        begin
          bookmark = Bookmark.create( category_id: category_id, name: name, url_id: url_id, add_date: add_date )
          bookmark_id = bookmark.id
        rescue => ex
          puts "In add"
          p ex.class
          p ex.message
          pp ex.backtrace
          exit

          current_bookmark = nil
        end
      end

      if bookmark_id
        @tsg.bookmark.add( bookmark_id )
      end

      bookmark_id
    end

    #
    # interface      
    def get_latest_bookmark
      get_all_bm
      @bminfo_array.max{ |a,b|
        a.add_date <=> b.add_date
      }
    end

    def ensure_management
      if need_update_management?
        update_management( @latest_add_date, @latest_last_modified );
        @prev_latest_add_date = @latest_add_date
        @prev_latest_last_modified = @latest_last_modified 
      end
    end

    def ensure_invalid
      invalid_ids = Currentbookmark.pluck(:org_id) - @tsg.bookmark.ids
      invalid_ids.map{|x|
        Invalidbookmark.create( org_id: x , count_id: @count.id )
      }

      invalid_ids = @hierop.current_klass.pluck(:org_id) - @tsg.category.ids
      invalid_ids.map{|x|
        @hierop.invalid_klass.create( org_id: x , count_id: @count.id )
      }

      invalid_ids = Currenturl.pluck(:org_id) - @tsg.url.ids
      invalid_ids.map{|x|
        Invalidurl.create( org_id: x , count_id: @count.id )
      }
    end

    def get_bookmarks_json( hier , start , limit )
      cur = @hierop.current_klass.find_by( name: hier )
      if cur
        category_id = cur.org_id
        get_bookmarks_by_id_json( category_id , start , limit )
      else
        JSON([])
      end
    end

    def get_bookmarks_by_id_json( category_id , start , limit )
      puts "category_id=#{category_id}|start=#{start}|limit=#{limit}"
      if category_id
        JSON(
          Currentbookmark.where( category_id: category_id ).all[ start , limit ].map{ |x|
            bkattr = x.bookmark.bkattr
            desc = bkattr ? bkattr.desc : ""
            { "id" => x.org_id , "name" => x.name , "desc" => desc , "url" => x.bookmark.url.val }
          }
        )
      else
        JSON([])
      end
    end

    def get_bookmarks_count_json( hier )
      cur = @hierop.current_klass.find_by( name: hier )
      if cur
        category_id = cur.org_id
        get_bookmarks_count_by_id_json( category_id )
      else
        JSON([ { "count" => 0 } ])
      end
    end

    def get_bookmarks_count_by_id_json( category_id )
      puts "category_id=#{category_id}"
      if category_id
        JSON(
          [ { "count" => Currentbookmark.where( category_id: category_id ).pluck( :org_id ).count } ]
        )
      else
        JSON([])
      end
    end

=begin
     # interface      
     def ensure_all_bm_and_all_category
       get_all_bm
       get_all_category
     end
     
     def get_differenc_between_bminfos_by_category_and_bminfo_array
       ensure_all_bm_and_all_category

       keys1 = @bminfos_by_category.keys
       keys2 = @bminfo_array.map{|x| x.category }.uniq
       [keys1.size, keys2.size] + keys1 - keys2
     end

     def get_all_bm_last_modified
       get_all_bm
       @bminfo_latest_modified_array = @bminfo_array.select{ |x|
         x.last_modified != nil and x.last_modified.strip == ""
       }
     end
     
     def get_latest_modified_bookmark
       get_all_bm_last_modified
       @bminfo_latest_modified_array.max { |a,b|
         a.last_modified <=> b.last_modified
       }
     end

     def get_latest_category
       get_all_category
       @categoryinfo_array.max_by{ |item|
         if item.add_date == nil
           0
         else
           item.add_date
         end
       }
     end

     def get_list_category
       get_all_category
       @categoryinfo_array
     end

     def bookmark_count
       get_all_bm
       @bminfo_array.size
     end
     
     def category_count
       get_all_category
       @categoryinfo_array.size
     end

     def pickup_multiple_bookmarks_by_url
       ensure_all_bm_and_all_category      

       @bminfos_by_url.map{ |x|
         if x[1].size > 1
           puts x[0]
           puts x[1].map{|y| puts [y.category, y.name].join("|") ; puts "----" }
         end
       }
     end
     
     def pickup_not_sutable_bookmarks_for_folder
       ensure_all_bm_and_all_category
       @bminfos_by_category.keys.select{|x|
         x =~ /Gitmarks/
       }.map{|category_name|
         @bminfos_by_category[category_name].select{ |x|
           x.url !~ /github\.com/
         }
       }.flatten
     end
     
     def pickup_multiple_bookmarks_between_gitmarks_and_other
       ensure_all_bm_and_all_category
       categoryes = @bminfos_by_category.keys.select{|x|
         x =~ /Gitm/
       }
       categoryes.map{|category_name|
         @bminfos_by_category[category_name].map{|x|
           bminfos = @bminfos_by_url[x.url]
           if bminfos.size > 1
             puts x.url
             bminfos.map{|y| puts [y.category , y.name].join("|") }
             puts "==="
           end
         }
       }
     end
=end
  
  end
end
