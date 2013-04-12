class Merge::Blog

  include DataMapper::Resource

  property :id, Serial
  property :old_id, Integer
  property :new_id, Integer 
  property :source_repo, String
  property :old_domain, String, length: 255
  property :new_domain, String, length: 255

  validates_uniqueness_of :old_id, scope: [:source_repo]
end
