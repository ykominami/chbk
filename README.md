# Chbk
HTMLファイルからブックマークのカテゴリ別に分類してブックマークの一覧を得、DBを更新する（DB内に存在するがHTMLファイルに存在しないものを、invalidとする。DB内に存在しないが、HTMLファイルに存在するものを登録する）

	bundle exec ruby exe/chbk 入力ファイル 

入力ファイルと同じディレクトリに存在する、 カテゴリファイル（入力ファイル名_category.入力ファイルの拡張子)も入力とする

「入力ファイル名_category.入力ファイルの拡張子」を用意する

環境変数ENV=production

現在は処理に数十分かかる。

 DB : db/chbk/production.sqlite3

@mode
MIXED_MODE
ADD_ONLY_MODE
DELETE_ONLY_MODE
TRACE_MODE

# Chbk2
HTMLファイルからブックマークのカテゴリ別に分類してブックマークの一覧を得る
（処理時間計測して表示）

	bundle exec ruby exe/chbk2.rb 入力ファイル モード

入力ファイルと同じディレクトリに存在する、 カテゴリファイル（入力ファイル名_category.入力ファイルの拡張子)も入力とする

モード: TRACE_MODE(省略時値)
       
 DB : db/chbk/production.sqlite3

# Chbk3db
HTMLファイルからブックマークのカテゴリ別に分類してブックマークの一覧を得る

# makemigrate
bundle exec ruby exe/makemigrate



Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/chbk`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'chbk'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install chbk

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment. Run `bundle exec chbk` to use the gem in this directory, ignoring other installed copies of this gem.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/chbk. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

# 
