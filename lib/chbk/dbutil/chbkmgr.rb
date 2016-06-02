# -*- coding: utf-8 -*-
require 'active_record'
require 'forwardable'
require 'pp'

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
      belongs_to :categories , foreign_key: 'category_id'
      belongs_to :counts , foreign_key: 'count_id'
    end

    class Invalidbookmark < ActiveRecord::Base
      belongs_to :bookmarks ,
                 foreign_key: 'org_id'
      belongs_to :counts , foreign_key:'count_id'
    end

    class Currentbookmark < ActiveRecord::Base
      has_and_belongs_to_many :Counts
      belongs_to :counts , foreign_key: 'count_id'
      belongs_to :bookmarks , foreign_key: 'org_id'
    end

    class Category < ActiveRecord::Base
      has_and_belongs_to_many :Counts
      has_many :bookmarks
    end

    class Invalidcategory < ActiveRecord::Base
      belongs_to :categories , foreign_key: 'org_id'
      belongs_to :counts , foreign_key: 'count_id'
    end

    class Currentcategory < ActiveRecord::Base
      belongs_to :counts , foreign_key: 'count_id'
      belongs_to :categories , foreign_key: 'org_id'
    end

    class Management < ActiveRecord::Base end

    class ChbkMgr
      extend Forwardable
      
      def initialize(register_time)
        @register_time = register_time
        @count = Count.create( countdatetime: @register_time )
        @management = nil
        ensure_management
        @latest_add_date = @management.add_date
        @latest_last_modified = @management.last_modified
        @category_hs = {}
        @bookmakr_hs = {}
        @bookmark_by_categoryname = {}
        @bookmark_hs = {}

        @valid_bminfo = Set.new
        @valid_categoryinfo = Set.new
      end

      def ensure_invalid
        invalid_ids = Currentbookmark.pluck(:org_id) - @valid_bminfo.to_a
        Invalidbookmark.where( id: invalid_ids ).update_all( end_count_id: @count.id )

        invalid_ids = Currentcategory.pluck(:org_id) - @valid_categoryinfo.to_a
        Invalidcategory.where( id: invalid_ids ).update_all( end_count_id: @count.id )
      end
    
      def update_management( add_date , last_modified ) 
        Management.find(1).update( add_date: add_date , last_modified: last_modified ) 
      end
      
      def update_integer( model , hs )
        value_hs = hs.reduce({}){ |hsx,item|
          val = model.send(item[0])
          if val != nil and item[1] != nil and val  < item[1]
            hsx[ item[0] ] = item[1]
          end
          hsx
        }
        model.update(value_hs) if value_hs.size > 0
      end
      
      def add_category( category_name , add_date = nil, last_modified = nil )
        hs = {add_date: add_date, last_modified: last_modified }.reduce({}){ |hash, x|
          if x[1] != nil
            hash[ x[0] ] = x[1]
          end
          hash
        }
        
        if (category = @category_hs[category_name] ) != nil
          category_id = category.id
          if hs.size > 0
            update_integer( category , hs )
          end
        else
          cur_category = Currentcategory.where( name: category_name ).limit(1)
          if cur_category.size == 0
            begin
              category = Category.create( name: category_name , add_date: add_date, last_modified: last_modified )
              @category_hs[category_name] = category
              category_id = category.id
            rescue => ex
              p "In add_category"
              p ex.class
              p ex.message
              pp ex.backtrace
              exit
              
              category = nil
              categorycount = nil
            end
          else
            cur_category = cur_category.first
            category_id = cur_category['org_id']
            category = Category.find( category_id )
            if hs.size > 0
              update_integer( category , hs )
            end
          end
        end
        @valid_categoryinfo << category_id
        
        category_id
      end

      def ensure_management
        unless @management
          begin
            @management = Management.find(1)
          rescue
          end
          @management = Management.create( add_date: 0 , last_modified: 0 ) unless @management
        end
      end
      
      def get_add_date_from_management
        ensure_management
        Management.find(1).add_date
      end

      def get_last_modified_from_management
        ensure_management
        Management.find(1).add_date
      end
      
      def category_add( category_name , add_date , last_modified )
#        puts category_name if last_modified != nil
        add_category( category_name , add_date , last_modified )
      end
      
      def add( category_name , name , url , add_date = nil )
        category_id = add_category( category_name )
        @bookmark_hs[category_id] ||= {}
        
        #        hs = {:category_id => category_id, :name => name, :url => url , add_date: add_date }
        hs = {}
        if add_date != nil
          hs[:add_date] = add_date
        end
        
        if ( bookmark = @bookmark_hs[category_id][url] )
            update_integer( bookmark , hs )
        else
          cur_bookmark = Currentbookmark.where( category_id: category_id , url: url ).limit(1)
          if cur_bookmark.size == 0
            begin
              bookmark = Bookmark.create( category_id: category_id, name: name, url: url, add_date: add_date )
              @bookmark_hs[category_id][name] = bookmark
            rescue => ex
              puts "In add"
              p ex.class
              p ex.message
              pp ex.backtrace
              exit
              
              bookmark = nil
              bookmarkcount = nil
            end
          else
            bookmark = cur_bookmark.first
            update_integer( bookmark , hs )
          end
        end
        
        if bookmark
          @bookmark_hs[category_id][url] = bookmark
          @valid_bminfo << bookmark.id
        end
        bookmark
      end
    end
  end
end

