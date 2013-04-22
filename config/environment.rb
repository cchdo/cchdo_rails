# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
#RAILS_GEM_VERSION = '2.3.5' unless defined? RAILS_GEM_VERSION

# Initialize this before the models
# Relative to Rails.root
ARGO_ROOT = File.join('public', 'data', 'argo')

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence those specified here

  config.action_mailer.delivery_method = :sendmail 

  # Skip frameworks you're not going to use (only works if using vendor/rails)
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper, 
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
  
  # See Rails::Configuration for more options
  config.gem 'rubyzip', :lib => 'zip/zip'
  config.gem 'fastercsv'
end

# Add new inflection rules using the following format 
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# Include your application configuration below

SUBMITLOG = Logger.new(Rails.root.join('log', 'submit.log'))
SUBMITLOG.level = Logger::DEBUG

# Initialize the PassengerUploadBufferDir
require 'fileutils'
passengeruploadbufferdir = Rails.root.join('tmp', 'passengeruploadbuffer')
begin
  FileUtils.mkdir_p(passengeruploadbufferdir)
  FileUtils.chmod(0775, passengeruploadbufferdir)
rescue
  Rails.logger.error("#{passengeruploadbufferdir} could not be created. " + 
                     "Needed for file uploading.")
end
TEMPDIR = Rails.root.join('tmp')
begin
  FileUtils.mkdir_p(TEMPDIR)
  FileUtils.chmod(0775, TEMPDIR)
rescue
  Rails.logger.error("#{TEMPDIR} could not be created.")
end
