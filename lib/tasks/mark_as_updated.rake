namespace :merge do 
  desc "Crea o aggiorna la riga della versione del blog in wp_blog_versions"
  task :mark_as_updated => :environment do 
    DataMapper::Logger.new(STDOUT) if Rails.env.to_s.eql? 'development'
    DataMapper.auto_upgrade!
    adapter = DataMapper.repository(:destination).adapter
    DataMapper.repository(:destination) do      
      Wp::Blog.all.each do |blog|
        begin
          adapter.execute("INSERT INTO `wp_blog_versions` (`blog_id`,`db_version`,`last_updated`) VALUES (#{blog.blog_id},'22441',NOW());")
        rescue Exception => e
          sleep 1
          puts e.message
        end
      end
    end
  end
end
