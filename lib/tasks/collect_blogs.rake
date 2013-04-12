# require 'pp'
# namespace :merge do
#   desc "Copies a blog from translating the ids"
#   task :shifted_copy => :environment do
#     DataMapper.auto_upgrade!
#     settings= YAML.load File.read(File.join(Rails.root.to_s,'config','database.yml'))
#     repositories= settings[Rails.env]['repositories']
#     puts "Specifica un repo come REPO=nome " and exit unless ENV['REPO']
#     repo = ENV['REPO']
#     next if repo =~ /destination/
#     #adapter = DataMapper.repository(repo).adapter 
#     #table_names= adapter.select "show tables;"
#     blog_ids= DataMapper.repository(repo) {Wp::Blog.all.collect{|b| b.blog_id}} # table_names.grep(/_[0-9]+_/).collect{|t| t =~ /_([0-9]+)_/; $1 }.uniq.map &:to_i
#     blog_ids= blog_ids - [1]
#     pp blog_ids
#     blog_ids.each do |blog_id|
#       blog = DataMapper.repository(repo) { Wp::Blog.get(blog_id) }
#       pp blog.inspect
#       if blog
#         new_domain = blog.domain.sub /\..*/, ".#{Settings.wp_domain}"
#         merge_blog = Merge::Blog.create old_id: blog_id, source_repo: repo, old_domain: blog.domain, new_domain: new_domain
#         #non ho già migrato questo blog
#         if merge_blog.id
#           DataMapper.repository(:destination) do 
#             #already migrated or in progress blogs will have the domain field 
#             if Wp::Blog.count(conditions: ['domain = ? or domain = ?',blog.domain,new_domain]) > 0
#               pp "Blog già importato"
#             else
#               pp "Importo Blog"
#               new_blog = Wp::Blog.create blog.attributes.merge({blog_id: nil, domain: new_domain})
#               pp "Creato Blog con id #{new_blog.blog_id}"
#               merge_blog.new_id = new_blog.blog_id
#               merge_blog.save!
#             end
#           end
#         end
#       else
#         pp "Blog già importato"
#       end
#     end
#   end
# end