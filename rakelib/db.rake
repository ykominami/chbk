# coding: utf-8
require 'arxutils'

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
        ["url" , "string", "false"],
        ["add_date" , "int", "true"],
      ],
      :plural => "bookmarks"
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
      :plural => "categories"
    },
    
    {
      :flist => %W!noitem!,
      :classname => "Management",
      :classname_downcase => "management",

      :items => [
        ["add_date" , "int", "false"],
        ["last_modified" , "int", "false"],
      ],
      :plural => "managements"
    },
  ]

  dbconfig = Arxutils::Dbutil::DBCONFIG_MYSQL
  dbconfig = Arxutils::Dbutil::DBCONFIG_SQLITE3

  forced = true
  Arxutils::Migrate.migrate(
    db_def_ary,
    0,
    dbconfig,
    forced
  )

end
