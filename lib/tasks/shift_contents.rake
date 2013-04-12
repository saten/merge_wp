require 'pp'
namespace :merge do
  desc "Shift user ids in a repo based on an offset given by the destination repo"
  task :shift_contents => :environment do
    DataMapper::Logger.new(STDOUT) if Rails.env.to_s.eql? 'development'
    puts "Specifica un repo come REPO=nome " and exit unless ENV['REPO']
    repo = ENV['REPO']      
    DataMapper.auto_upgrade!
    settings= YAML.load File.read(File.join(Rails.root.to_s,'config','database.yml'))
    repositories= settings[Rails.env]['repositories']
    user_offset= DataMapper.repository(:destination) { [Wp::User.last.ID,Wp::User.count].max }
    blog_offset= DataMapper.repository(:destination) { [Wp::Blog.last.blog_id,Wp::Blog.count].max }
    umeta_offset= DataMapper.repository(:destination).adapter.select("SELECT umeta_id from `wp_usermeta` order by umeta_id DESC limit 1")
    umeta_offset.any? ? umeta_offset= umeta_offset.first : umeta_offset= 0
    openid_offset= DataMapper.repository(:destination).adapter.select("SELECT uurl_id from `wp_openid_identities` order by uurl_id DESC limit 1")
    openid_offset.any? ? openid_offset= openid_offset.first : openid_offset= 0

    pp blog_offset: blog_offset
    pp user_offset: user_offset
    pp umeta_offset: umeta_offset
    pp openid_offset: openid_offset
    adapter= DataMapper.repository(repo).adapter
    begin
      table_names= adapter.select "show tables;"
    rescue Exception =>e
      pp e.message
      sleep 5
      retry
    end
    table_names_for_user_shift = {}
    table_names_for_user_shift[:comments]=table_names.grep(/_[0-9]+_comments/)
    table_names_for_user_shift[:posts]=table_names.grep(/_[0-9]+_posts/)
    DataMapper.repository repo do
      #shiftare di user_offset tutti gli id utente
      users = Wp::User.all(:order => [ :ID.desc ])
      total = users.size
      users.each_with_index do |u,i|
        #pp "Applico user_offset all'utente #{u.ID}"
        pp "#{i+1}/#{total}" if ((i+1)%100).eql? 0

        user = Wp::User.get u.ID
        DataMapper.repository(:default) do
          mu= Merge::User.create! old_id: u.ID, new_id: (u.ID + user_offset), source_repo: repo, old_email: u.user_email, old_login: u.user_login
          #aggiorno i riferimenti a questo utente in tutte le tabelle del repo
          adapter.execute("UPDATE `wp_usermeta` SET user_id=#{mu.new_id} where user_id=#{mu.old_id};")
          #per ogni wp_x_post wp_x_comment
          table_names_for_user_shift[:posts].each do |table|
            adapter.execute("UPDATE `#{table}` SET post_author='#{mu.new_id}' where post_author='#{mu.old_id}' ;")
          end
          table_names_for_user_shift[:comments].each do |table|
            adapter.execute("UPDATE `#{table}` SET user_id='#{mu.new_id}' where user_id='#{mu.old_id}' ;")
          end
        end          
        user.ID = user.ID + user_offset
        user.save!
      end
      #vanno shiftati in avanti anche tutte le chiavi primarie in wp_usermeta e wp_openid_identities
      #disattivo temporaneamente la chiave primaria, for the win
      adapter.execute("ALTER TABLE  `wp_usermeta` CHANGE  `umeta_id`  `umeta_id` BIGINT( 20 ) UNSIGNED NOT NULL;")
      adapter.execute("ALTER TABLE `wp_usermeta` DROP PRIMARY KEY;")
      adapter.execute("UPDATE `wp_usermeta` SET umeta_id=(umeta_id + #{umeta_offset});")
      adapter.execute("ALTER TABLE  `wp_usermeta` CHANGE  `umeta_id`  `umeta_id` BIGINT( 20 ) UNSIGNED NOT NULL PRIMARY KEY;")
      adapter.execute("ALTER TABLE  `wp_usermeta` CHANGE  `umeta_id`  `umeta_id` BIGINT( 20 ) UNSIGNED NOT NULL AUTO_INCREMENT;")
      #same for wp_openid_identities
      adapter.execute("ALTER TABLE  `wp_openid_identities` CHANGE  `uurl_id`  `uurl_id` BIGINT( 20 ) UNSIGNED NOT NULL;")
      adapter.execute("ALTER TABLE `wp_openid_identities` DROP PRIMARY KEY;")
      adapter.execute("UPDATE `wp_openid_identities` SET uurl_id=(uurl_id + #{openid_offset});")
      adapter.execute("ALTER TABLE  `wp_openid_identities` CHANGE  `uurl_id`  `uurl_id` BIGINT( 20 ) UNSIGNED NOT NULL PRIMARY KEY;")
      adapter.execute("ALTER TABLE  `wp_openid_identities` CHANGE  `uurl_id`  `uurl_id` BIGINT( 20 ) UNSIGNED NOT NULL AUTO_INCREMENT;")
        
      #shiftare di blog_offset tutti gli id blog, e propagare
      blogs = Wp::Blog.all(:order=>[:blog_id.desc])
      total= blogs.size
      blogs.each_with_index do |b,i|
        #pp "Applico blog_offset al blog #{b.blog_id}"
        pp "#{i+1}/#{total}" if ((i+1)%100).eql? 0
        blog = Wp::Blog.get b.blog_id
        new_domain = blog.domain.sub /\..*/, ".#{Settings.wp_domain}"
        DataMapper.repository(:default) do
          Merge::Blog.create! old_id: b.blog_id, new_id: (b.blog_id + blog_offset), source_repo: repo, old_domain: blog.domain, new_domain: new_domain
        end
        blog.blog_id = b.blog_id + blog_offset
        blog.save!
      end
      #adesso vanno rinominate tutte le tabelle e i riferimenti interni ad ogni blog
      #per i blog è sufficiente rinominare le tabelle e aggiornare dei record in wp_x_options
      #opzioni: upload_path, wp_x_user_roles
      #prima faccio gli update, poi rinomino le tabelle (è indifferente l'ordine, cmq)
      merge_blogs= DataMapper.repository(:default) {Merge::Blog.all(:order=>[:old_id.desc],:conditions=>{source_repo: repo})}
      merge_blogs.each do |mb|
        adapter.execute("UPDATE `wp_#{mb.old_id}_options` SET option_value='wp-content/blogs.dir/#{mb.new_id}/files' where option_name = 'upload_path';")
        adapter.execute("UPDATE `wp_#{mb.old_id}_options` SET option_name='wp_#{mb.new_id}_user_roles' where option_name='wp_#{mb.old_id}_user_roles' ")
        #primary_blog
        adapter.execute("UPDATE `wp_usermeta` SET meta_value=#{mb.new_id} where meta_value=#{mb.old_id};")
        #wp_x_capabilities
        adapter.execute("UPDATE `wp_usermeta` SET meta_key='wp_#{mb.new_id}_user_level' where meta_key='wp_#{mb.old_id}_user_level';")
        #wp_x_user_level
        adapter.execute("UPDATE `wp_usermeta` SET meta_key='wp_#{mb.new_id}_capabilities' where meta_key='wp_#{mb.old_id}_capabilities';")
        
        #tabelle da rinominare
        table_names_for_rename= table_names.grep(/_#{mb.old_id}_/) #.delete_if{|tn| tn =~ /options/ }
        pp("RENAME TABLE #{ table_names_for_rename.collect{|tn| "#{tn} TO #{tn.sub(mb.old_id.to_s,mb.new_id.to_s)}" }.join(',') };")
        adapter.execute("RENAME TABLE #{ table_names_for_rename.collect{|tn| "#{tn} TO #{tn.sub(mb.old_id.to_s,mb.new_id.to_s)}" }.join(',') };")
      end
    end 
  end
end
