# -*- coding: utf-8 -*-
require 'csv'
require 'pp'
require 'forwardable'
require 'chbk/dbutil/chbkmgr'

module Chbk
  class Chbk
    attr_reader :latest_add_date , :latest_last_modified , :latest_op_date
    
    extend Forwardable

    def_delegator( :@mgr , :add , :db_add )
    def_delegator( :@mgr , :category_add , :db_category_add )
    def_delegator( :@mgr , :update_add_date, :dg_update_add_date)
    def_delegator( :@mgr , :update_last_modified, :db_update_last_modified)
    def_delegator( :@mgr , :get_add_date_from_management, :db_get_latest_add_date)
    def_delegator( :@mgr , :get_last_modified_from_management, :db_get_latest_last_modified)
    def_delegator( :@mgr , :update_management, :db_update_management)
    def_delegator( :@mgr , :ensure_invalid, :db_ensure_invalid)

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
      @bminfos_by_url = {}
      @bminfos_by_category = {}


      @bookmarkinfo = Struct.new("BookmarkInfo", :category, :name, :url , :add_date, :last_modified)
      @categoryinfo = Struct.new("CategoryInfo", :name, :add_date, :last_modified)

      @dbmgr = Arxutils::Store.init( kind , hs ){ | register_time |
        @mgr = Dbutil::ChbkMgr.new( register_time )
      }
      @prev_latest_add_date = @latest_add_date = db_get_latest_add_date
      @prev_latest_last_modified = @latest_last_modified = db_get_latest_last_modified
      @prev_latest_op_date = @latest_op_date = [@latest_add_date, @latest_last_modified].max
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

    def update_add_date_if_new( add_date )
      @latest_add_date = add_date if add_date != nil and add_date > @latest_add_date
    end

    def update_last_modified_if_new( last_modified )
      @latest_last_modified = last_modified if last_modified != nil and last_modified > @latest_last_modified
    end
    
    def get_all_bm
      if @bminfo_array.size == 0
        array = @input_bookmark_file.readlines
        array.shift(@ignore_lines)
        count = 0
        @bminfo_array = array.map{ |line|
          it = @bookmarkinfo.new( *get_record_from_tsv(line))
          if it
            @bminfos_by_add_date[it.add_date] ||= []
            @bminfos_by_add_date[it.add_date] << it
            
            @bminfos_by_url[it.url] ||= []
            @bminfos_by_url[it.url] << it
            
            @bminfos_by_category[it.category] ||= []
            @bminfos_by_category[it.category] << it

            update_add_date_if_new( it.add_date )
          end
          it
        }.select{ |x|
          x != nil
        }
      end
    end

    def get_all_category
      if @categoryinfo_array.size == 0
        count = 0
        array = @input_category_file.readlines
        @categoryinfo_array = array.map{ |line|
          it = @categoryinfo.new( *get_category_record_from_tsv(line) )
          update_add_date_if_new( it.add_date )
          update_last_modified_if_new( it.last_modified )

          it
        }.select{ |x|
          x != nil
        }
      end
    end
    
    def list_bookmark
      get_all_bm
      @bminfo_array.map{|bookmarkinfo|
        db_add(  bookmarkinfo.category , bookmarkinfo.name , bookmarkinfo.url , bookmarkinfo.add_date , bookmarkinfo.last_modified )
      }
    end

    def list_category
      get_all_category
      @categoryinfo_array.map{|x|
        db_category_add(  x.name , x.add_date , x.last_modified )
      }
    end

    def need_update_management?
      @latest_add_date > @prev_latest_add_date or @latest_last_modified > @prev_latest_last_modified
    end
    
    def ensure_management
       if need_update_management?
         db_update_management( @latest_add_date, @latest_last_modified );
         @prev_latest_add_date = @latest_add_date
         @prev_latest_last_modified = @latest_last_modified 
       end
    end

    def ensure_invalid
      db_ensure_invalid
    end
    
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

    def pickup_not_sutable_bookmarks_for_folder
      ensure_all_bm_and_all_category
      puts "In pickup_not_sutable_bookmarks_for_folder"
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
      puts "In pickup_multiple_bookmarks_between_gitmarks_and_other"
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
    
    def pickup_multiple_bookmarks_by_url
      ensure_all_bm_and_all_category      

      @bminfos_by_url.map{ |x|
        if x[1].size > 1
          puts x[0]
          puts x[1].map{|y| puts [y.category, y.name].join("|") ; puts "----" }
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
  end
end
