# -*- coding: utf-8 -*-
require 'chbk/dbutil/chbkmgr'
require 'forwardable'
require 'pp'

module Chbk
  module Dbutil
    class DbMgr
      extend Forwardable
      
      def_delegator( :@mgr , :add, :add)
      def_delegator( :@mgr , :category_add, :category_add)
      def_delegator( :@mgr , :update_add_date, :update_add_date)
      def_delegator( :@mgr , :update_last_modified, :update_last_modified)
      def_delegator( :@mgr , :get_add_date_from_management, :get_add_date_from_management)
      def_delegator( :@mgr , :get_last_modified_from_management, :get_last_modified_from_management)
      def_delegator( :@mgr , :update_management, :update_management)

      def initialize( register_time )
        @mgr = ChbkMgr.new( register_time )
      end
    end
  end
end

