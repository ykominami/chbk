# -*- coding: utf-8 -*-
require 'csv'
require 'pp'
require 'forwardable'

module Chbk
  class Chbk
    attr_reader :latest_add_date , :latest_last_modified , :latest_op_date
    
    extend Forwardable
    
    def_delegator( :@dbmgr , :add , :db_add )
    def_delegator( :@dbmgr , :category_add , :db_category_add )
    def_delegator( :@dbmgr , :get_add_date_from_management ,      :db_get_latest_add_date )
    def_delegator( :@dbmgr , :get_last_modified_from_management , :db_get_latest_last_modified )

    def initialize( kind , hs )
      @ignore_lines = 1
      @ignore_lines_category = 0
      #      @line = 1
      @input_bookmark_file = nil
      @input_category_file = nil

      @bminfo_array = []
      @bminfo_latest_modified_array = []
      @categoryinfo_array = []
      @categoryinfo_latest_modified_array = []
      @bminfo_by_category = {}
      @bminfos = {}
      @bminfos_by_add_date = {}
      @bookmarkinfo = Struct.new("BookmarkInfo", :category, :name, :url , :add_date, :last_modified)
      @categoryinfo = Struct.new("CategoryInfo", :name, :add_date, :last_modified)

      @dbmgr = Arxutils::Store.init( kind , hs ){ | register_time |
        Dbutil::DbMgr.new( register_time )
      }
      @latest_add_date = db_get_latest_add_date
      @latest_last_modified = db_get_latest_last_modified
      @latest_op_date = [@latest_add_date, @latest_last_modified].max
      set_output_dest( get_output_filename_base )
    end

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
        if x != nil and x =~ /^\s*/
          x.to_i
        else
          nil
        end
      }
    end
      
    def get_record_from_tsv(line)
      category, name, url, add_date, last_modified, tmp_ignore = line.chomp.split("\t")
      add_date, last_modified = normalize_to_integer( add_date, last_modified )
      [category, name, url, add_date, last_modified]
    end
    
    def get_category_record_from_tsv(line)
      name, add_date, last_modified, tmp_ignore = line.chomp.split("\t")
      add_date, last_modified = normalize_to_integer( add_date, last_modified )
      [name, add_date, last_modified]
    end
    
    def get_all_bm
      if @bminfo_array.size == 0
        array = @input_bookmark_file.readlines
        array.shift(@ignore_lines)
        @bminfo_array = array.map{ |line|
          it = @bookmarkinfo.new( *get_record_from_tsv(line) )
          @bminfos_by_add_date[it.add_date] ||= []
          @bminfos_by_add_date[it.add_date] << it
          it
        }.select{ |x|
          @latest_add_date = x.add_date if (ret = (x != nil)) and x.add_date != nil and x.add_date > @latest_add_date
          ret
        }
      end
    end

    def list_bookmark
      get_all_bm
      @bminfo_array.map{|bookmarkinfo|
        db_add(  bookmarkinfo.category , bookmarkinfo.name , bookmarkinfo.url , bookmarkinfo.add_date , bookmarkinfo.last_modified )
      }
    end

    def pickup_multiple_bookmarks
      get_all_bm
      @bminfos_by_add_date.map{ |x|
        if x[1].size > 1
          puts x[0]
          puts x[1].map{|y| puts [y.category, y.name].join("|") }
        end
      }
    end
    
    def bookmark_count
      get_all_bm
      @bminfo_array.size
    end
    
    def get_all_bm_last_modified
      get_all_bm
      @bminfo_latest_modified_array = @bminfo_array.select{ |x|
        x.last_modified != nil and x.last_modified.strip == ""
      }
    end
    
    def get_latest_bookmark
      get_all_bm
      @bminfo_array.max{ |a,b|
        a.add_date <=> b.add_date
      }
    end

    def get_latest_modified_bookmark
      get_all_bm_last_modified
      @bminfo_latest_modified_array.max { |a,b|
        a.last_modified <=> b.last_modified
      }
    end

    def get_all_category
      if @categoryinfo_array.size == 0
        array = @input_category_file.readlines
        array.shift(@ignore_lines_category)
        @categoryinfo_array = array.map{ |line|
          recs = get_category_record_from_tsv(line)
#          puts recs.size
#          p recs
          @categoryinfo.new( *recs  )
        }.select{ |x|
          @latest_add_date = x.add_date if (ret = (x != nil)) and x.add_date != nil and x.add_date > @latest_add_date
          ret
        }
      end
    end
    
    def list_category
      get_all_category
      @categoryinfo_array.map{|x|
        db_category_add(  x.name , x.add_date , x.last_modified )
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

    def category_count
      get_all_category
      @categoryinfo_array.size
    end
=begin
=end
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
    
    def putsx( str )
      @output.puts( str )
    end

    def register_bookmark( category_name , bookmarkinfo )
      @bminfo_by_category[category_name] ||= []
      @bminfo_by_category[category_name] << bookmarkinfo
      @bminfos[bookmarkinfo.name] = bookmarkinfo

      @output_csv << [ category , bookmarkinfo.name , bookmarkinfo.url , bookmarkinfo.add_date , bookmarkinfo.last_modified ]
    end

  end
end
