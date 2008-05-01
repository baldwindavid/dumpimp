namespace :db do
  
  namespace :mysql do
    desc 'Dump MySQL file and gzip for RAILS_ENV.  Initial path of dump is to "db/".  Set alternate path with INITIAL_PATH=path/to/dump/.  To skip gzip use GZIP=no.'
    task :dump => :environment do
      dump_from_mysql ENV['INITIAL_PATH'], ENV['GZIP']
    end

    desc 'Import MySQL dump .sql or .sql.gz file into the specified RAILS_ENV.  Select file with FILE=path/to/file/dump.sql.gz.  If the file is gzipped, it will be unzipped, imported and then gzipped back again.'
    task :import => :environment do
      import_from_mysql ENV['FILE']
    end
  end
  
  namespace :mysql5 do
    desc 'Dump MySQL file and gzip for RAILS_ENV.  Initial path of dump is to "db/".  Set alternate path with INITIAL_PATH=path/to/dump/.  To skip gzip use GZIP=no.'
    task :dump => :environment do
      dump_from_mysql ENV['INITIAL_PATH'], ENV['GZIP'], 'mysql5'
    end
    
    desc 'Import MySQL dump .sql or .sql.gz file into the specified RAILS_ENV.  Select file with FILE=path/to/file/dump.sql.gz.  If the file is gzipped, it will be unzipped, imported and then gzipped back again.'
    task :import => :environment do
      import_from_mysql ENV['FILE'], 'mysql5'
    end
  end
  
end


def dump_from_mysql(initial_path, gzip, mysql_version = 'mysql')
  
  initial_path ||= 'db/'
  # make sure we have a slash at the end of the path to designate a directory
  initial_path = (initial_path[-1,1] == "/") ? initial_path : initial_path + '/'
  
  connection = ActiveRecord::Base.establish_connection  
  puts "Creating .sql dump file. Enter MySQL password for this database. Press enter for none"
  # dump file
  `#{mysql_version == 'mysql5' ? 'mysqldump5' : 'mysqldump'} -u #{connection.config[:username]} -p 
#{connection.config[:database]} > #{initial_path}#{connection.config[:database]}_dump.sql`
  
  if gzip == 'no'
    puts "Database dumped to #{initial_path}#{connection.config[:database]}_dump.sql"
  else
    `gzip #{initial_path}#{connection.config[:database]}_dump.sql`
    puts "Database dumped and gzipped to #{initial_path}#{connection.config[:database]}_dump.sql.gz"
  end
  
end


def import_from_mysql(file, mysql_version = 'mysql')
  
  if file.include?('.gz')
    sql_file = file.gsub(/.gz/, '')
    gzip = true
  else
    sql_file = file
    gzip = false
  end
  
  if gzip
    # gunzip sql file
    puts "Unzipping #{file}"
    `gunzip #{file}`
  end
  
  connection = ActiveRecord::Base.establish_connection
  # import to current environment's database
  puts "Enter MySQL password for this database. Press enter for none"
  `#{mysql_version} -u #{connection.config[:username]} -p #{connection.config[:database]} < #{sql_file}`
  puts "Imported #{sql_file} to #{connection.config[:database]} database."
  
  if gzip
    # gzip backup again
    `gzip #{sql_file}`
    puts "Gzipped back again to #{file}"
  end
  
end

