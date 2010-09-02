# ARGO_ROOT is set in config/environment.rb

class Argo::File < ActiveRecord::Base
    set_table_name 'argo_files'

    has_attachment :storage => :file_system,
                   :partition => false,
                   :path_prefix => ARGO_ROOT

    belongs_to :user
end

# Ensure Argo root directory exists
FileUtils.mkdir_p(Rails.root.join(ARGO_ROOT))
