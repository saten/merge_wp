require 'pp'
namespace :merge do
  desc "Copies a blog from translating the ids"
  task :copy_blog => :environment do
    settings= YAML.load File.read(File.join(Rails.root.to_s,'config','database.yml'))
    repositories= settings[Rails.env]['repositories']
    repositories.keys.each do |repo|
      next if repo =~ /destination/
      adapter = DataMapper.repository(repo).adapter 
      table_names= adapter.select "show tables;"
      blog_ids= table_names.grep(/_[0-9]+_/).collect{|t| t =~ /_([0-9]+)_/; $1 }.uniq.map &:to_i
      pp blog_ids
    end
  end
end