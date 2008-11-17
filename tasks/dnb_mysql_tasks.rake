DB_DUMP_ADAPTERS = %w(mysql)

namespace :db do
  task :check => :environment do
    unless DB_DUMP_ADAPTERS.include?(db_config['adapter'])
      raise "#{db_config['adapter']} adapter not supported yet" 
    end
  end

  desc 'Dump SQL file and gzip for RAILS_ENV.  Initial path of dump is to "db/".  Set alternate path with INITIAL_PATH=path/to/dump/.  To skip gzip use GZIP=no.  Specify tables with TABLES="table1 table2 table3"'
  task :dump => :check do
    db_dump ENV['INITIAL_PATH'], ENV.to_hash
  end
  
  desc 'Import SQL dump .sql or .sql.gz file into the specified RAILS_ENV.  Select file with FILE=path/to/file/dump.sql.gz.'
  task :import => :check do
    db_import ENV['FILE']
  end
  
  desc 'Import SQL dump .sql or .sql.gz file into the specified RAILS_ENV.  Select file with FILE=path/to/file/dump.sql.gz.'
  task :imp => :check do
    db_import ENV['FILE']
  end
  
end

def db_config
  @db_config ||= ActiveRecord::Base.configurations[RAILS_ENV || 'development']
end

def mysql_dump_command
  `which mysqldump5 || which mysqldump`.chomp
end

def mysql_import_command
  `which mysql5 || which mysql`.chomp
end

def db_dump(initial_path, options = {})
  send(db_config['adapter'] + '_dump', initial_path, options)
end

def dump_suffix
  t = Time.now.getgm
  '_' + t.strftime("%m-%d-%Y-") + t.to_i.to_s
end

def mysql_dump(initial_path, options = {})
  
  options = {
    'GZIP' => 'yes',
    'TABLES' => ''
  }.merge(options)
  
  username = db_config['username']
  database = db_config['database']
  
  initial_path ||= File.join(RAILS_ROOT, 'db')
    
  dump_file = File.join(initial_path, "#{database}#{dump_suffix}.sql")
  
  gzip_command = 
    if ENV['GZIP'] != 'no'
      dump_file += '.gz'
      '| gzip'
    end
  
  run("#{mysql_dump_command} -u #{username} #{password_option} #{database} #{ENV['TABLES']} #{gzip_command} > #{dump_file}")  

  puts "Database #{db_config['database']} dumped to #{dump_file}"
  
  return dump_file
end

def db_import(file)
  send(db_config['adapter'] + '_import', file)
end

def mysql_import(file)
  cat_dump_command =
    if file.include?('.gz')
      'gunzip --stdout'
    else
      'cat'
    end
    
  run("#{cat_dump_command} #{file} | #{mysql_import_command} -u #{db_config['username']} #{password_option} #{db_config['database']}")
  
  puts "Imported #{file} to #{db_config['database']} database."
end

def password_option
  if db_config.include?('password')
    "--password=#{db_config['password']}"
  end
end

def run(command)
  puts command
  system(command)
end