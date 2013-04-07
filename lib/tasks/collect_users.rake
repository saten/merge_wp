namespace :merge do
  desc "Collect users from repositories and save info in the db"
  task :collect_users => :environment do
    DataMapper.auto_upgrade!
    settings= YAML.load File.read(File.join(Rails.root.to_s,'config','database.yml'))
    users={}
    settings[Rails.env]['repositories'].keys.each do |repo|
      repo_name = repo
      db_name = settings[Rails.env]['repositories'][repo_name]["database"]
      next if repo_name =~ /destination/

      DataMapper.repository repo_name do
        users[repo_name]= Wp::User.all
        puts "#{repo_name} has #{users[repo_name].size} users"
      end
    end
    users.each do |repo_name,repo_name_users|
      puts "importing #{repo_name_users.size} users from #{repo_name}"
      repo_name_users.each do |user|
        puts "importing user #{user.ID} from #{repo_name}"
        Merge::User.create old_id: user.ID, old_email: user.user_email, old_login: user.user_login, source_repo: repo_name
      end
    end

    #create the users on the new installation
    #and update the corresponding new_ids
    Merge::User.all.group_by{|u| u.old_login}.each do |old_login,mus|
        DataMapper.repository :destination do
        #puts old_login, mus.inspect
        #non discriminiamo i doppioni in questa fase
        mus.each do |mu|
          #se non esiste un utente con questa login e email
          if Wp::User.count(conditions: ['user_login =? and user_email =?',mu.old_login,mu.old_email]) < 1
            attributes = DataMapper.repository(mu.source_repo){Wp::User.get(mu.old_id).attributes}
            u = Wp::User.create attributes.merge({ :ID=> nil})
            puts "creato utente #{u.ID} "
            mu.new_id = u.ID
            mu.save!
          end
        end
      end
    end

  end
end