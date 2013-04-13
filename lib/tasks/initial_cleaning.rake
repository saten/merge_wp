require 'pp'
namespace :merge do
  desc "Rimuove il blog con blog_id 1 e l'utente con id 1"
  task :initial_cleaning => :environment do 
    DataMapper::Logger.new(STDOUT)# if Rails.env.to_s.eql? 'development'
    puts "Specifica un repo come REPO=nome " and exit unless ENV['REPO']
    repo = ENV['REPO']      
    DataMapper.auto_upgrade!
    #settings= YAML.load File.read(File.join(Rails.root.to_s,'config','database.yml'))
    #repositories= settings[Rails.env]['repositories']
    adapter= DataMapper.repository(repo).adapter

    #cancello il blog con blog_id = 1
    adapter.execute("DELETE from `wp_blogs` where `blog_id`=1;")

    #cancello l'utente con ID 1
    adapter.execute("DELETE FROM `wp_usermeta` WHERE user_id=1;")
    adapter.execute("DELETE FROM `wp_openid_identities` WHERE user_id=1;")
    adapter.execute("DELETE FROM `wp_users` WHERE ID=1;")
    
    #drop tabelle poll
    table_names= adapter.select "show tables;"
    table_names_for_dropping= table_names.grep(/_[0-9]+_/).find_all{|tn| tn =~ /poll/}
    adapter.execute("DROP TABLE IF EXISTS #{table_names_for_dropping.join(',')}") if table_names_for_dropping.any?

    #al volo invece che blog per blog
    adapter.execute "UPDATE wp_blogs SET domain = REPLACE(domain,'wpsport.com','#{Settings.wp_domain}');"
    adapter.execute "UPDATE wp_blogs SET domain = REPLACE(domain,'wpevery.com','#{Settings.wp_domain}');"
    adapter.execute "UPDATE wp_blogs SET domain = REPLACE(domain,'wpdevel.org','#{Settings.wp_domain}');"
    #adapter.execute "UPDATE wp_blogs SET domain = REPLACE(domain,'wpdevel.loc','#{Settings.wp_domain}');"

    #migrazione indirizzo
    DataMapper.repository(repo) do
        Wp::Blog.all.each do |blog|
            new_domain = blog.domain.sub /\..*/, ".#{Settings.wp_domain}"
            adapter.execute "UPDATE wp_#{blog.blog_id}_options SET option_value = REPLACE(option_value, '#{blog.domain}', '#{new_domain}') WHERE option_name = 'home' OR option_name = 'siteurl';"
            adapter.execute "UPDATE wp_#{blog.blog_id}_posts SET guid = REPLACE (guid, '#{blog.domain}', '#{new_domain}');"
            adapter.execute "UPDATE wp_#{blog.blog_id}_posts SET post_content = REPLACE (post_content, '#{blog.domain}', '#{new_domain}');"
            adapter.execute "UPDATE wp_#{blog.blog_id}_postmeta SET meta_value = REPLACE (meta_value, '#{blog.domain}','http#{new_domain}');"
        end
    end
  end
end