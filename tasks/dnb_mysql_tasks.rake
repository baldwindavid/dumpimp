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
  connection = ActiveRecord::Base.establish_connection  
  config = YAML.load_file(File.join(RAILS_ROOT, 'config', 'database.yml'))[RAILS_ENV || 'development']
  username = connection.config[:username]
  database = connection.config[:database]

  password_option = 
    if config.include?('password')
      "--password=#{config['password']}"
    end
  
  initial_path ||= File.join(RAILS_ROOT, 'db')
  
  puts "Creating dump file..."
  # dump file
  dump_command = mysql_version == 'mysql5' ? 'mysqldump5' : 'mysqldump'
  dump_file = File.join(initial_path, "#{database}_dump.sql")
  
  gzip_command = 
    if gzip != 'no'
      dump_file += '.gzip'
      '| gzip'
    end
  
  run("#{dump_command} -u #{username} #{password_option} #{database} #{gzip_command} > #{dump_file}")  

  puts "Database dumped to #{dump_file}"
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

def run(command)
  puts command
  `#{command}`
end