class Wp::Blog

  include DataMapper::Resource

  property :blog_id, Serial
  property :site_id, Integer, default: 0
  property :domain, String, length: 200
  property :path, String, length: 100
  property :registered, DateTime
  property :last_updated, DateTime
  property :public, Boolean, default: true
  property :archived, String, default: "0"
  property :mature, Boolean, default: false
  property :spam, Boolean, default: false
  property :deleted, Boolean, default: false
  property :lang_id, Integer, default: 0



end
