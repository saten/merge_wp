class Wp::User

  include DataMapper::Resource
  
  property :ID, Serial
  property :user_login, String, length: 60
  property :user_pass, String, length: 64
  property :user_nicename, String, length: 50
  property :user_email, String, length: 100
  property :user_url, String, length: 100
  property :user_registered, DateTime
  property :user_activation_key, String, length: 60
  property :user_status, Integer, default: 0
  property :display_name, String, length: 250
  property :spam, Boolean, default: false
  property :deleted, Boolean, default: false

end
