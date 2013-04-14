namespace :merge do 
  desc "Merge users based on the first user with the same login"
  task :merge_users => :environment do 
    DataMapper::Logger.new(STDOUT) #if Rails.env.to_s.eql? 'development'
    DataMapper.auto_upgrade!
    adapter = DataMapper.repository(:destination).adapter
    table_names= adapter.select "show tables;"  
    table_names_for_user_shift = {}
    table_names_for_user_shift[:comments]=table_names.grep(/_[0-9]+_comments/)
    table_names_for_user_shift[:posts]=table_names.grep(/_[0-9]+_posts/)
    res = adapter.select "select user_login,count(user_login) from wp_users group by user_login having count(user_login) >1;"
    total = res.size      
    total_drop=[]
    res.each_with_index do |double_user_data,i|
      pp "#{i+1}/#{total}" if ((i+1)%10 ).eql? 0
      login= double_user_data.user_login
      user_ids = adapter.select "select ID from wp_users where user_login = '#{login}';"
      keep = user_ids.first
      drop = user_ids[1,user_ids.size]
      total_drop << drop
      #per ogni wp_x_post wp_x_comment
      table_names_for_user_shift[:posts].each do |table|
        adapter.execute("UPDATE `#{table}` SET post_author=#{keep} where post_author in ( #{drop.join(',')} );")
      end
      table_names_for_user_shift[:comments].each do |table|
        adapter.execute("UPDATE `#{table}` SET user_id=#{keep} where user_id in (#{drop.join(',')}) ;")
      end
    end
    #cancello gli user meta appesi
    total_drop.flatten!
    adapter.execute("DELETE from `wp_users` where ID in (#{total_drop.join(',')});")
    adapter.execute("DELETE from `wp_usermeta` where user_id in (#{total_drop.join(',')});")
  end
end
