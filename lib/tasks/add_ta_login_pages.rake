namespace :merge do 
  desc "Create pages for the login plugin"
  task :ta_login_pages => :environment do 
    DataMapper::Logger.new(STDOUT) if Rails.env.to_s.eql? 'development'
    DataMapper.auto_upgrade!
    adapter = DataMapper.repository(:destination).adapter
    DataMapper.repository(:destination) do      
      Wp::Blog.all.each do |blog|
        next if blog.blog_id.eql? 1
        begin
          domain = blog.domain
          p_time=Time.now - 1.day
          table= "wp_#{blog.blog_id}_posts"
          last_id = adapter.select("select max(ID) from `#{table}`;").first
          adapter.execute("INSERT IGNORE INTO `#{table}` (`ID`,`post_author`,`post_date`,`post_date_gmt`,`post_content`,`post_title`,`post_excerpt`,`post_status`,`comment_status`,`ping_status`,`post_name`,`to_ping`,`pinged`,`post_modified`,`post_modified_gmt`,`post_content_filtered`,`guid`,`post_type`) VALUES "\
          "(#{last_id+1},1,'#{p_time.strftime("%Y-%m-%d %H:%M:%S")}','#{p_time.gmtime.strftime("%Y-%m-%d %H:%M:%S")}','','TeamArtist Login','','publish','closed','closed','ta_login','','','#{p_time.strftime("%Y-%m-%d %H:%M:%S")}','#{p_time.gmtime.strftime("%Y-%m-%d %H:%M:%S")}','','http://#{domain}/?page_id=#{last_id+1}','page'),"\
          "(#{last_id+2},1,'#{p_time.strftime("%Y-%m-%d %H:%M:%S")}','#{p_time.gmtime.strftime("%Y-%m-%d %H:%M:%S")}','','Ottieni una nuova password','','publish','closed','closed','','','ta_forgot_password','#{p_time.strftime("%Y-%m-%d %H:%M:%S")}','#{p_time.gmtime.strftime("%Y-%m-%d %H:%M:%S")}','','http://#{domain}/?page_id=#{last_id+2}','page'),"\
          "(#{last_id+3},1,'#{p_time.strftime("%Y-%m-%d %H:%M:%S")}','#{p_time.gmtime.strftime("%Y-%m-%d %H:%M:%S")}','','Resetta password','','publish','closed','closed','reset_password','','','#{p_time.strftime("%Y-%m-%d %H:%M:%S")}','#{p_time.gmtime.strftime("%Y-%m-%d %H:%M:%S")}','','http://#{domain}/?page_id=#{last_id+3}','page');")
          adapter.execute("REPLACE INTO `wp_#{blog.blog_id}_options` (`option_name`,`option_value`) VALUES ('ta_login_page_ids','a:3:{i:0;i:#{last_id+1};i:1;i:#{last_id+2};i:2;i:#{last_id+3};}');")
        rescue Exception => e
          sleep 1
          puts e.message
        end
      end
    end
  end
end
