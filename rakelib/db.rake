# coding: utf-8
require 'arxutils'
require 'pp'

desc <<-EOS
  db migration
EOS
task :migrate do
  db_def_ary = [
    {
      :flist => %W!noitem!,
      :classname => "Count",
      :classname_downcase => "count",
      :items => [
        ["countdatetime" , "datetime", "false"],
      ],
      :plural => "counts"
    },

    {
      :flist => %W!base invalid current!,
      :classname => "Bookmark",
      :classname_downcase => "bookmark",

      :items => [
        ["category_id" , "integer", "false"],
        ["name" , "string", "true"],
        ["url_id" , "integer", "false"],
        ["add_date" , "int", "true"],
      ],
      :plural => "bookmarks",
      :relation => [
        %Q!belongs_to :category , foreign_key: 'category_id'!,
        %Q!belongs_to :url , foreign_key: 'url_id'!,
      ]
    },

    {
      :flist => %W!base invalid current!,
      :classname => "Url",
      :classname_downcase => "url",

      :items => [
        ["val" , "string", "false"],
      ],
      :plural => "urls",
      :relation => [
        %Q!has_many :bookmarks!,
      ]
    },

    {
      :flist => %W!base invalid current!,
      :classname => "Category",
      :classname_downcase => "category",

      :items => [
        ["name" , "string", "false"],
        ["add_date" , "int", "true"],
        ["last_modified" , "int", "true"],
      ],
      :plural => "categories",
      :relation => [
        %Q!has_many :bookmarks!,
      ]
    },
    
    {
      :flist => %W!noitem!,
      :classname => "Categoryhier",
      :classname_downcase => "categoryhier",
      :items => [
        ["parent_id" , "int", "false"],
        ["child_id" , "int", "false"],
        ["level" , "int", "false"],
      ],
      :plural => "categoryhiers",
      :relation => [
        %Q!belongs_to :category , foreign_key: 'parent_id'!,
        %Q!belongs_to :category , foreign_key: 'child_id'!,
      ]
    },

    {
      :flist => %W!noitem!,
      :classname => "Management",
      :classname_downcase => "management",

      :items => [
        ["add_date" , "int", "false"],
        ["last_modified" , "int", "false"],
      ],
      :plural => "managements",
    },
  ]

  dbname = 'chbk'
  db_dir = File.join( Arxutils::Dbutil::DB_DIR , dbname )
  config_dir = File.join( Arxutils::Dbutil::CONFIG_DIR , dbname )
  dbconfig = { :kind => Arxutils::Dbutil::DBCONFIG_MYSQL , :dbname => dbname , :db_dir => db_dir }
  dbconfig = { :kind => Arxutils::Dbutil::DBCONFIG_SQLITE3 , :db_dir => db_dir }

  forced = true

  begin
    Arxutils::Migrate.migrate(
      db_def_ary,
      %q!lib/chbk/relation.rb!,
      "Chbk",
      "count",
      dbconfig,
      forced
    )
  rescue => ex
    puts ex.message
    pp ex.backtrace
  end
end
