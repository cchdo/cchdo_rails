# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_cchdo_session',
  :secret      => '3d8470cb5fba7c4b9901cc9a6e4e157ca0969926b72ba8c97a7cd7bfa4fdca3fb828b7db9be3a341db097569e615a06442aa0d57920bebfc40484012fd172b8c3f9c93719d34d8555a78c73fa960b1da40a2f8580aa5e3fd0ab005b424e6753f6c385899de82ad32c04f968ecefbab596244c22e89aa567a4466363640c06ff0ee9aa30e64b8e135a2944cbb5a23bc70bb9950281b43b018927be9d9e1f78eda1b622264666cc423bece5d4db5d6110f3cda2319a4a4031e802932fb6ae5407127a13342a4b489b5ff5794a60a980523120c34030fbb0c99ff69d1605753f3cada9f1836a8ffa8504b843e0d0181a3dafa000abebc75e4096bf0b52b27319c51'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
