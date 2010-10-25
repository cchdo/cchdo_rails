# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_cchdo_session',
  :secret      => 'bdb58bec06d37f72e98108fa6e49a4f14732deb979d0eb6d2eb13130ca6c4b173925e56979050ec3a73302e4983685ae4838bac86b016355d83b77ee2c03940d'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
