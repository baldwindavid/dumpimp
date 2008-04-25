namespace :db do
  namespace :mysql do
      desc "dumps the current environment's database to a sql file"
      task :dump => :environment do
        dump_from_mysql ENV['INITIAL_PATH']
      end

      desc "imports mysql FROM=env and to RAILS_ENV=env"
      task :import => :environment do
        import_from_mysql ENV['INITIAL_PATH']
      end
  end
  
  namespace :mysql5 do
      desc "dumps the current environment's database to a sql file"
      task :dump => :environment do
        dump_from_mysql ENV['INITIAL_PATH'], 'mysql5'
      end
      
      desc "imports mysql FROM=env and to RAILS_ENV=env"
      task :import => :environment do
        import_from_mysql ENV['INITIAL_PATH'], 'mysql5'
      end
  end
  
end

def dump_from_mysql(initial_path, mysql_version = 'mysql')
  initial_path ||= '~/dbdumps/'
  connection = ActiveRecord::Base.establish_connection
  puts "Creating .sql dump file. Enter mysql root password. Just press Enter for none"
  # dump file
  `#{mysql_version == 'mysql5' ? 'mysqldump5' : 'mysql'} -u #{connection.config[:username]} -p #{connection.config[:database]} > #{initial_path}#{connection.config[:database]}.sql`
  # gzip file
  `gzip #{initial_path}#{connection.config[:database]}.sql`
end

def import_from_mysql(initial_path, mysql_version = 'mysql')
  initial_path ||= '~/dbdumps/'
  connection = ActiveRecord::Base.establish_connection
  # load all database information
  db = YAML.load_file("#{RAILS_ROOT}/config/database.yml")
  # set from database
  from_db = db[ENV['FROM']]['database']
  puts "Loading #{from_db}.sql.gz Enter mysql root password. Just press Enter for none"
  # gunzip sql file
  `gunzip #{initial_path}#{from_db}.sql.gz`
  # import to current environment's database
  `#{mysql_version} -u #{connection.config[:username]} -p #{connection.config[:database]} < #{initial_path}#{from_db}.sql`
  # gzip backup again
  `gzip #{initial_path}#{from_db}.sql`
end

