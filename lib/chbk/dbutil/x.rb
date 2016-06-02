# -*- coding: utf-8 -*-
require 'arxutils'

module Chbk
  module Dbutil
    class Count < ActiveRecord::Base
      has_and_belongs_to_many :bookmarks
      has_and_belongs_to_many :categories
      has_and_belongs_to_many :currentbookmarks
      has_and_belongs_to_many :currentcategories
      has_many :invalidbookmarks
      has_many :invalidcategories
    end

    class Bookmark < ActiveRecord::Base
      has_and_belongs_to_many :Counts
      belongs_to :category , foreign_key: 'category_id'
      belongs_to :count , foreign_key: 'count_id'
    end

    class Invalidbookmark < ActiveRecord::Base
      belongs_to :bookmark , foreign_key: 'org_id'
      belongs_to :count , foreign_key: 'count_id'
    end

    class Currentbookmark < ActiveRecord::Base
      has_and_belongs_to_many :Counts
      belongs_to :count , foreign_key: 'count_id'
      belongs_to :bookmark , foreign_key: 'org_id'
    end

    class Category < ActiveRecord::Base
      has_and_belongs_to_many :Counts
      has_many :bookmarks
    end

    class Invalidcategory < ActiveRecord::Base
      belongs_to :category , foreign_key: 'org_id'
      belongs_to :count , foreign_key: 'count_id'
    end

    class Currentcategory < ActiveRecord::Base
      belongs_to :count , foreign_key: 'count_id'
      belongs_to :category , foreign_key: 'org_id'
    end

    class Management < ActiveRecord::Base
    end

    class Categoryhier < ActiveRecord::Base
    end
    
    class TransactState
      attr_accessor :ids , :state
      
      def initialize
        @ids = []
        @state = :NONE
      end

      def add( xid )
        @ids << xid if @state == :TRACE
      end

      def clear
        @ids = []
      end

      def need?
        @ids.size > 0
      end

    end

    class TransactStateGroup
      def initialize( *names )
        @state = :NONE
        @inst = {}
        names.map{|x| @inst[x] = TransactState.new }
      end
      
      def need?
        @state != :NONE
      end
      
      def set_all_inst_state
        @inst.map{|x| x[1].state = @state }
      end
      
      def trace
        @state = :TRACE
        set_all_inst_state
      end
      
      def reset
        @state = :NONE
        set_all_inst_state
      end
      
      def method_missing(name , lang = nil)
        @inst[name] 
      end
    end
    
    class Chbk
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
        @mode = :MIXED_MODE
        @tsg = TransactStateGroup.new( :category , :bookmark )
        
        @ignore_lines = 1
        @ignore_lines_category = 0
        #      @line = 1
        @input_bookmark_file = nil
        @input_category_file = nil
        
        @bminfo_array = []
        @categoryinfo_array = []
        
        
        @bookmarkinfo = Struct.new("BookmarkInfo", :category, :name, :url , :add_date)
        @categoryinfo = Struct.new("CategoryInfo", :name, :add_date, :last_modified)

        Arxutils::Store.init( kind , hs ){ | register_time |
          @count = Count.create( countdatetime: register_time )
        }
#
        @management = nil
        restore_management


      end

      # not used
=begin      
      def set_output_dest( fname )
        if fname
          fname_txt = fname + ".txt"
          fname_csv = fname + ".csv"
          @output = File.open( fname_txt , "w" , { :encoding => 'UTF-8' } )
          @output_csv = CSV.open( fname_csv , "w" , { :encoding => 'UTF-8' } )
        else
          @output = STDOUT
        end
      end

      def get_output_filename_base
        Time.now.strftime("bm-%Y-%m-%d-%H-%M-%S")
      end
=end      

      def load_file( in_file )
        File.open( in_file , "r" , { :encoding => 'UTF-8' } )
      end
      
      def load_bookmark_file( in_file )
        @input_bookmark_file = load_file( in_file )
      end
      
      def load_category_file( in_file )
        @input_category_file = load_file( in_file )
      end

      def normalize_to_integer( *args )
        args.map{ |x|
          if x != nil and x !~ /^\s*$/
            x.to_i
          else
            nil
          end
        }
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
                it = @bookmarkinfo.new( category, name, url, add_date )
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
      
      def restore_management
        setup_management
        @prev_latest_add_date = @latest_add_date = @management.add_date
        @prev_latest_last_modified = @latest_last_modified = @management.last_modified
      end

      def update_management( add_date , last_modified ) 
        @management.update( add_date: add_date , last_modified: last_modified ) 
      end
      
      def update_integer( model , hs )
        value_hs = hs.reduce({}){ |hsx,item|
          val = model.send(item[0])
          if val == nil or val  < item[1]
            hsx[ item[0] ] = item[1]
          end
          hsx
        }
        if value_hs.size > 0
          begin
            model.update(value_hs)
#            model.save
          rescue => ex
            puts ex.message
          end
        end
      end

      def register_category( category_name , add_date = nil, last_modified = nil )
        category_id = nil
        current_category = nil
        hs = {}
        hs[:add_date] = add_date if add_date
        hs[:last_modified] = last_modified if last_modified

        current_category = Currentcategory.find_by( name: category_name )
        if current_category
          category_id = current_category.org_id
          if hs.size > 0
#            category = Category.find( category_id )
#            update_integer( category , hs )
            update_integer( current_category.category , hs )
          end
        else
          begin
            category = Category.create( name: category_name , add_date: add_date, last_modified: last_modified )
#            category.save
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
      
      def get_add_date_from_management
        Management.find(1).add_date
      end

      def get_last_modified_from_management
        Management.find(1).last_modified
      end

      def add_bookmark( category_name , name , url , add_date = nil )
        category_id = register_category( category_name )
        bookmark = Bookmark.create( category_id: category_id, name: name, url: url, add_date: add_date )
#        bookmark.save
        bookmark_id = bookmark.id
      end
      
      def register_bookmark( category_name , name , url , add_date = nil )
        bookmark_id = nil
        category_id = register_category( category_name )
        
        current_bookmark = Currentbookmark.find_by( category_id: category_id , url: url , add_date: add_date)
        if current_bookmark
          bookmark_id = current_bookmark.org_id
        else
          begin
            bookmark = Bookmark.create( category_id: category_id, name: name, url: url, add_date: add_date )
#            bookmark.save
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
        puts "call ensure_invalid"
#        invalid_ids = Currentbookmark.pluck(:org_id) - @valid_bminfo.to_a
        invalid_ids = Currentbookmark.pluck(:org_id) - @tsg.bookmark.ids
#        puts "bookmark invalid_ids="
#        p invalid_ids
        invalid_ids.map{|x|
          Invalidbookmark.create( org_id: x , end_count_id: @count.id )
        }

#        invalid_ids = Currentcategory.pluck(:org_id) - @valid_categoryinfo.to_a
        invalid_ids = Currentcategory.pluck(:org_id) - @tsg.category.ids
#        puts "category invalid_ids="
#        p invalid_ids
        invalid_ids.map{|x|
          Invalidcategory.create( org_id: x , end_count_id: @count.id )
        }
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
end
