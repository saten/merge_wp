class Merge::User

  include DataMapper::Resource

  property :id, Serial
  property :old_id, Integer
  property :old_email, String, length: 100
  property :old_login, String, length: 60
  property :source_repo, String
  property :new_id, Integer 

  validates_uniqueness_of :old_login, scope: [:old_email]

end
