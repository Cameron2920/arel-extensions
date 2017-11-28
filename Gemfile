source "https://rubygems.org"

gemspec

group :development, :test do
  gem "sqlite3", :platforms => [:mri, :mswin, :x64_mingw, :mingw]
  gem "mysql2", :platforms => [:mri, :mswin, :x64_mingw, :mingw]
  gem "pg", :platforms => [:mri, :mingw, :x64_mingw, :mswin]

  gem "jdbc-sqlite3", :platforms => :jruby
  gem "activerecord-jdbcsqlite3-adapter", :platforms => :jruby
  gem "activerecord-jdbcmysql-adapter", :platforms => :jruby
  gem "activerecord-jdbcpostgresql-adapter", :platforms => :jruby

	
  gem "tiny_tds", :platforms => [:mingw, :x64_mingw, :mswin]
  gem "activerecord-sqlserver-adapter", '~> 4.2.0', :platforms => [:mingw, :x64_mingw, :mswin]

  gem 'activesupport', '~> 4.0'
  gem 'activemodel', '~> 4.0'
  gem 'activerecord', '~> 4.0'
end
