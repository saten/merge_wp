namespace :merge do 
  desc "Direct copy except user with ID = 1 and its usermeta"
  task :direct_copy => :environment do
    DataMapper::Logger.new(STDOUT) if Rails.env.to_s.eql? 'development'
    DataMapper.auto_upgrade!
    settings= YAML.load File.read(File.join(Rails.root.to_s,'config','database.yml'))
    repositories= settings[Rails.env]['repositories']
    puts "Specifica un repo come REPO=nome " and exit unless ENV['REPO']
    repo = ENV['REPO']
    Dir.mkdir('dumps') unless Dir.exists?('dumps')
    adapter= DataMapper.repository(repo).adapter
    database_name  = repositories[repo]['database']
    table_names= adapter.select "show tables;"
    table_without_creation = ['wp_blogs','wp_users','wp_usermeta']
    table_names_for_dumping= table_names.grep(/_[0-9]+_/).delete_if{|tn| tn =~ /poll/}
    ignored_tables = table_names - table_names_for_dumping

    dump_file = "dumps/#{repo}.sql"
    system "echo > #{dump_file}"
    5.times do |i|
      sleep 1
      puts 5 - i
    end
    total = table_names_for_dumping.size
    table_names_for_dumping.each_with_index do |table,i|
        pp "#{i+1}/#{total}" if ((i+1)%100).eql? 0
        export_command = "mysqldump --opt --add-drop-table=0  -P #{repositories[repo]['port']} -h #{repositories[repo]['host']} -u #{repositories[repo]['user']} -p#{repositories[repo]['password']}  #{repositories[repo]['database']} #{table} >> #{dump_file} 2>/dev/null"
        #pp export_command
        system export_command
    end
    second_export_command = "mysqldump --opt --add-drop-table=0 --no-create-info  -P #{repositories[repo]['port']} -h #{repositories[repo]['host']} -u #{repositories[repo]['user']} -p#{repositories[repo]['password']}  #{repositories[repo]['database']} #{ table_without_creation.join(' ') } >> #{dump_file} 2>/dev/null"
    #pp second_export_command
    system second_export_command
    openid_export_command =  "mysqldump --opt --add-drop-table=0 --insert-ignore --no-create-info  -P #{repositories[repo]['port']}  -h #{repositories[repo]['host']} -u #{repositories[repo]['user']} -p#{repositories[repo]['password']}  #{repositories[repo]['database']} wp_openid_identities >> #{dump_file} 2>/dev/null"
    #pp openid_export_command
    system openid_export_command
    #pp import_command
    import_command = "mysql  -P #{repositories[repo]['port']}  -h #{repositories['destination']['host']} -u #{repositories['destination']['user']} -p#{repositories['destination']['password']} #{repositories['destination']['database']} < #{dump_file}"
    system import_command
    # file_content = File.read dump_file
    # new_file_content = file_content.gsub /(`.*_)([0-9]+)(_.*`)/, "\\1#{new_blog_id}\\3"
    #new_dump_file.write new_file_content
    #new_dump_file.close
  end
end