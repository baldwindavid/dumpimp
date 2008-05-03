DB_DUMP_ADAPTERS = %w(mysql)

namespace :db do
  
  desc 'Dump SQL file and gzip for RAILS_ENV.  Initial path of dump is to "db/".  Set alternate path with INITIAL_PATH=path/to/dump/.  To skip gzip use GZIP=no.'
  task :dump => :check do
    db_dump ENV['INITIAL_PATH'], ENV['GZIP']
  end
  
  desc 'Import SQL dump .sql or .sql.gz file into the specified RAILS_ENV.  Select file with FILE=path/to/file/dump.sql.gz.  If the file is gzipped, it will be unzipped, imported and then gzipped back again.'
  task :import => :check do
    db_import ENV['FILE']
  end
  
  task :check => :environment do
    unless DB_DUMP_ADAPTERS.include?(db_config['adapter'])
      raise "#{db_config['adapter']} adapter not supported yet" 
    end
  end
  
end

def db_config
  @db_config ||= ActiveRecord::Base.configurations[RAILS_ENV || 'development']
end

def mysql_dump_command
  `which mysqldump5 || which mysqldump`.chomp
end

def db_dump(initial_path, gzip, mysql_version = 'mysql')
  username = db_config['username']
  database = db_config['database']

  password_option = 
    if db_config.include?('password')
      "--password=#{config['password']}"
    end
  
  initial_path ||= File.join(RAILS_ROOT, 'db')
  
  puts "Creating dump file..."
  
  dump_file = File.join(initial_path, "#{database}_dump.sql")
  
  gzip_command = 
    if gzip != 'no'
      dump_file += '.gz'
      '| gzip'
    end
  
  run("#{mysql_dump_command} -u #{username} #{password_option} #{database} #{gzip_command} > #{dump_file}")  

  puts "Database dumped to #{dump_file}"
end


def db_import(file, mysql_version = 'mysql')
  
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
  system(command)
end