# namespace :merge do
#   desc "Collect users from REPO env and creates them on the destination db keeping the ID"
#   task :collect_users => :environment do
#     DataMapper.auto_upgrade!
#     settings= YAML.load File.read(File.join(Rails.root.to_s,'config','database.yml'))
#     users={}
#     puts "Specifica un repo come REPO=nome " and exit unless ENV['REPO']
#     repo = ENV['REPO']
#     repo_name = repo
#     db_name = settings[Rails.env]['repositories'][repo_name]["database"]
#     next if repo_name =~ /destination/

#     DataMapper.repository repo_name do
#       users[repo_name]= Wp::User.all
#       puts "#{repo_name} has #{users[repo_name].size} users"
#     end
#     users.each do |repo_name,repo_name_users|
#       puts "importing #{repo_name_users.size} users from #{repo_name}"
#       repo_name_users.each do |user|
#         puts "skipping user 1" and next if user.ID.eql? 1
#         puts "importing user #{user.ID} from #{repo_name}"
#         mu= Merge::User.create old_id: user.ID, old_email: user.user_email, old_login: user.user_login, source_repo: repo_name
#         if mu.id
#           DataMapper.repository(:destination) do
#             #se non esiste un utente con questa login e email
#             if Wp::User.count(conditions: ['user_login =? and user_email =?',mu.old_login,mu.old_email]) < 1
#               attributes = DataMapper.repository(mu.source_repo){Wp::User.get(mu.old_id).attributes}
#               u = Wp::User.create attributes
#               puts "creato utente #{u.ID} "
#               mu.new_id = u.ID
#               mu.save!
#             end          
#           end
#         end
#       end
#     end
#   end
# end