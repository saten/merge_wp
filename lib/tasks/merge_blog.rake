# namespace :merge do
#   desc "Merge blogs contents"
#   task :merge_blog => :environment do
#     DataMapper.auto_upgrade!
#     settings= YAML.load File.read(File.join(Rails.root.to_s,'config','database.yml'))
#     repositories= settings[Rails.env]['repositories']
#     puts "Specifica un repo come REPO=nome " and exit unless ENV['REPO']
#     repo = ENV['REPO']
#     Merge::Blog.all(conditions:{source_repo: repo}).each do |merge_blog|
#       #TODO: rimuovere
#       next if merge_blog.old_id != 9
      
#       repo = merge_blog.source_repo
#       adapter= DataMapper.repository(repo).adapter
#       table_names= adapter.select "show tables;"
#       table_names_for_dumping= table_names.grep(/_#{merge_blog.old_id}_/)
#       table_names_for_dumping.delete_if{|tn| tn =~ /poll/ }
#       pp table_names_for_dumping
#       Dir.mkdir('dumps') unless Dir.exists?('dumps')
#       #dump= File.new(File.join('dumps',"#{repo}-#{merge_blog.old_id}"),'w')
#       #dump.close
#       sh "mysqldump --opt -h #{repositories[repo]['host']} -u #{repositories[repo]['user']} -p#{repositories[repo]['password']} -P #{repositories[repo]['port']} #{repositories[repo]['database']} #{table_names_for_dumping.join(' ')} > dumps/#{repo}-#{merge_blog.old_id}"
#     end
#   end
# end