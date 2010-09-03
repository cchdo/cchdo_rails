# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100903175154) do

  create_table "argo_downloads", :id => false, :force => true do |t|
    t.column "argo_file_id", :integer
    t.column "datetime", :datetime
    t.column "ip", :integer
  end

  create_table "argo_files", :force => true do |t|
    t.column "user_id", :integer
    t.column "ExpoCode", :string
    t.column "description", :text
    t.column "display", :boolean, :default => false
    t.column "size", :integer
    t.column "filename", :string
    t.column "content_type", :string
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
  end

  create_table "assignments", :force => true do |t|
    t.column "ExpoCode", :text
    t.column "project", :text
    t.column "current_status", :text
    t.column "cchdo_contact", :text
    t.column "data_contact", :text
    t.column "action", :text
    t.column "parameter", :text
    t.column "history", :text
    t.column "changed", :date
    t.column "notes", :text
    t.column "priority", :integer
    t.column "deadline", :date
    t.column "manager", :string
  end

  create_table "audit_trails", :force => true do |t|
    t.column "record_id", :integer
    t.column "record_type", :string
    t.column "event", :string
    t.column "user_id", :integer
    t.column "time", :date
  end

  create_table "carina_cruises", :force => true do |t|
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
  end

  create_table "carina_documents", :force => true do |t|
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
  end

  create_table "codes", :force => true do |t|
    t.column "Code", :integer
    t.column "Status", :text
  end

  create_table "contacts", :force => true do |t|
  end

  create_table "cruises", :force => true do |t|
    t.column "ExpoCode", :text
    t.column "Line", :text
    t.column "Country", :text
    t.column "Chief_Scientist", :text
    t.column "Begin_Date", :date
    t.column "EndDate", :date
    t.column "Ship_Name", :text
    t.column "Alias", :text
    t.column "Group", :text
  end

  create_table "documents", :force => true do |t|
    t.column "Size", :text
    t.column "FileType", :text
    t.column "FileName", :text
    t.column "ExpoCode", :text
    t.column "Files", :text
    t.column "LastModified", :date
    t.column "Modified", :text
  end

  create_table "events", :force => true do |t|
    t.column "ExpoCode", :text
    t.column "First_Name", :text
    t.column "LastName", :text
    t.column "Data_Type", :text
    t.column "Date_Entered", :date
    t.column "Summary", :text
    t.column "Note", :text
  end

  create_table "map_images", :force => true do |t|
    t.column "expocode", :string, :null => false
    t.column "line", :string, :default => "Cruise"
    t.column "west", :string, :default => "179W"
    t.column "east", :string, :default => "179E"
    t.column "south", :string, :default => "80S"
    t.column "north", :string, :default => "80N"
    t.column "label_mod", :string, :default => "12"
    t.column "font_type", :string, :default => "1"
    t.column "font_size", :string, :default => "8"
    t.column "angle", :string, :default => "25.0"
    t.column "justify", :string, :default => "LT"
    t.column "label_color", :string, :default => "BLACK"
    t.column "x_shift", :string, :default => "0.1i"
    t.column "y_shift", :string, :default => "0.1i"
    t.column "lon_annot", :string, :default => "20"
    t.column "lat_annot", :string, :default => "10"
    t.column "annot_font_size", :string, :default => "12"
    t.column "header_font", :string, :default => "1"
    t.column "header_font_size", :string, :default => "18"
    t.column "ocean_color", :string, :default => "100/180/255"
    t.column "land_color", :string, :default => "BLACK"
    t.column "coastline_color", :string, :default => "BLACK"
    t.column "coastline_width", :string, :default => "0.00i"
    t.column "map_frame_width", :string, :default => "6.0i"
    t.column "station_size_inches", :string, :default => "0.04i"
    t.column "station_color", :string, :default => "255/48/48"
    t.column "station_outline_color", :string, :default => "139/0/0"
    t.column "station_outline_width", :string, :default => "0.0i"
    t.column "cruise_line_width_inches", :string, :default => "0.01i"
    t.column "cruise_line_color", :string, :default => "BLACK"
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
  end

  create_table "maps", :force => true do |t|
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
  end

  create_table "parameter_descriptions", :force => true do |t|
    t.column "Parameter", :string
    t.column "FullName", :string
    t.column "Description", :string
    t.column "Units", :string
    t.column "Range", :string
    t.column "Alias", :string
    t.column "Group", :string
  end

  create_table "parameter_groups", :force => true do |t|
    t.column "group", :text
    t.column "parameters", :text
  end

  create_table "parameters", :force => true do |t|
    t.column "ExpoCode", :text
    t.column "SALNTY", :text
    t.column "SALNTY_PI", :text
    t.column "OXYGEN", :text
    t.column "OXYGEN_PI", :text
    t.column "SILCAT", :text
    t.column "SILCAT_PI", :text
    t.column "NITRAT", :text
    t.column "NITRAT_PI", :text
    t.column "NITRIT", :text
    t.column "NITRIT_PI", :text
    t.column "PHSPHT", :text
    t.column "PHSPHT_PI", :text
    t.column "CFC-11", :text
    t.column "CFC-11_PI", :text
    t.column "CFC-12", :text
    t.column "CFC-12_PI", :text
    t.column "TRITUM", :text
    t.column "TRITUM_PI", :text
    t.column "HELIUM", :text
    t.column "HELIUM_PI", :text
    t.column "DELHE3", :text
    t.column "DELHE3_PI", :text
    t.column "DELC14", :text
    t.column "DELC14_PI", :text
    t.column "DELC13", :text
    t.column "DELC13_PI", :text
    t.column "KR-85", :text
    t.column "KR-85_PI", :text
    t.column "ARGON", :text
    t.column "ARGON_PI", :text
    t.column "AR-39", :text
    t.column "AR-39_PI", :text
    t.column "NEON", :text
    t.column "NEON_PI", :text
    t.column "RA-228", :text
    t.column "RA-228_PI", :text
    t.column "RA-226", :text
    t.column "RA-226_PI", :text
    t.column "O18/O16", :text
    t.column "O18/O16_PI", :text
    t.column "SR-90", :text
    t.column "SR-90_PI", :text
    t.column "CS-137", :text
    t.column "CS-137_PI", :text
    t.column "TCARBN", :text
    t.column "TCARBN_PI", :text
    t.column "ALKALI", :text
    t.column "ALKALI_PI", :text
    t.column "PCO2", :text
    t.column "PCO2_PI", :text
    t.column "PH", :text
    t.column "PH_PI", :text
    t.column "CFC113", :text
    t.column "CFC113_PI", :text
    t.column "CCL4", :text
    t.column "CCL4_PI", :text
    t.column "IODATE", :text
    t.column "IODATE_PI", :text
    t.column "IODIDE", :text
    t.column "IODIDE_PI", :text
    t.column "NH4", :text
    t.column "NH4_PI", :text
    t.column "CH4", :text
    t.column "CH4_PI", :text
    t.column "DON", :text
    t.column "DON_PI", :text
    t.column "N2O", :text
    t.column "N2O_PI", :text
    t.column "CHLORA", :text
    t.column "CHLORA_PI", :text
    t.column "PPHYTN", :text
    t.column "PPHYTN_PI", :text
    t.column "DMS", :text
    t.column "DMS_PI", :text
    t.column "BARIUM", :text
    t.column "BARIUM_PI", :text
    t.column "POC", :text
    t.column "POC_PI", :text
    t.column "PON", :text
    t.column "PON_PI", :text
    t.column "BACT", :text
    t.column "BACT_PI", :text
    t.column "DOC", :text
    t.column "DOC_PI", :text
    t.column "COMON", :text
    t.column "COMON_PI", :text
    t.column "C13ERR", :text
    t.column "C13ERR_PI", :text
    t.column "C14ERR", :text
    t.column "C14ERR_PI", :text
    t.column "BTLNBR", :text
    t.column "BTLNBR_PI", :text
    t.column "CASTNO", :text
    t.column "CASTNO_PI", :text
    t.column "CTDOXY", :text
    t.column "CTDOXY_PI", :text
    t.column "CTDPRS", :text
    t.column "CTDPRS_PI", :text
    t.column "CTDRAW", :text
    t.column "CTDRAW_PI", :text
    t.column "CTDSAL", :text
    t.column "CTDSAL_PI", :text
    t.column "CTDTMP", :text
    t.column "CTDTMP_PI", :text
    t.column "FLUOR", :text
    t.column "FLUOR_PI", :text
    t.column "NO2+NO3", :text
    t.column "NO2+NO3_PI", :text
    t.column "PCO2TMP", :text
    t.column "PCO2TMP_PI", :text
    t.column "PHTEMP", :text
    t.column "PHTEMP_PI", :text
    t.column "REVPRS", :text
    t.column "REVPRS_PI", :text
    t.column "REVTMP", :text
    t.column "REVTMP_PI", :text
    t.column "SAMPNO", :text
    t.column "SAMPNO_PI", :text
    t.column "STNNBR", :text
    t.column "STNNBR_PI", :text
    t.column "TDN", :text
    t.column "TDN_PI", :text
    t.column "THETA", :text
    t.column "THETA_PI", :text
    t.column "XMISS", :text
    t.column "XMISS_PI", :text
    t.column "AOU", :text
    t.column "AOU_PI", :text
    t.column "ARAB", :text
    t.column "ARAB_PI", :text
    t.column "AZOTE", :text
    t.column "AZOTE_PI", :text
    t.column "BRDU", :text
    t.column "BRDU_PI", :text
    t.column "CALCIUM", :text
    t.column "CALCIUM_PI", :text
    t.column "CU", :text
    t.column "CU_PI", :text
    t.column "DCNS", :text
    t.column "DCNS_PI", :text
    t.column "DELHE4", :text
    t.column "DELHE4_PI", :text
    t.column "DELHER", :text
    t.column "DELHER_PI", :text
    t.column "DIC", :text
    t.column "DIC_PI", :text
    t.column "FUC", :text
    t.column "FUC_PI", :text
    t.column "GAL", :text
    t.column "GAL_PI", :text
    t.column "GLU", :text
    t.column "GLU_PI", :text
    t.column "HELIER", :text
    t.column "HELIER_PI", :text
    t.column "IOD-129", :text
    t.column "IOD-129_PI", :text
    t.column "MAN", :text
    t.column "MAN_PI", :text
    t.column "MCHFRM", :text
    t.column "MCHFRM_PI", :text
    t.column "NEONER", :text
    t.column "NEONER_PI", :text
    t.column "NI", :text
    t.column "NI_PI", :text
    t.column "NO2", :text
    t.column "NO2_PI", :text
    t.column "PEUK", :text
    t.column "PEUK_PI", :text
    t.column "PRO", :text
    t.column "PRO_PI", :text
    t.column "RHAM", :text
    t.column "RHAM_PI", :text
    t.column "SF6", :text
    t.column "SF6_PI", :text
    t.column "SYN", :text
    t.column "SYN_PI", :text
    t.column "TOC", :text
    t.column "TOC_PI", :text
    t.column "TRITER", :text
    t.column "TRITER_PI", :text
    t.column "CF12ER", :text
    t.column "CF12ER_PI", :text
    t.column "PHPUNC", :text
    t.column "PHPUNC_PI", :text
    t.column "SILUNC", :text
    t.column "SILUNC_PI", :text
    t.column "NRAUNC", :text
    t.column "NRAUNC_PI", :text
    t.column "NRIUNC", :text
    t.column "NRIUNC_PI", :text
  end

  create_table "priorities", :force => true do |t|
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
  end

  create_table "sea_hunts", :force => true do |t|
    t.column "cruise_name", :string
    t.column "dates", :string
    t.column "location", :string
    t.column "status", :string
    t.column "contact-1", :string
    t.column "email", :string
    t.column "phone", :string
    t.column "institution", :string
    t.column "institution-2", :string
    t.column "notes", :string
    t.column "country", :string, :default => ""
    t.column "display_status", :integer, :default => 2, :null => false
    t.column "duration", :string, :default => ""
    t.column "frequency", :string, :default => ""
    t.column "ship", :string, :default => ""
    t.column "url", :string, :default => ""
    t.column "real_date", :date, :default => Wed, 01 Jan 1001, :null => false
    t.column "cruise_track_thumb", :binary, :limit => 16777215, :default => "", :null => false
    t.column "basin", :string, :default => ""
  end

  create_table "seahunts", :force => true do |t|
  end

  create_table "sessions", :force => true do |t|
    t.column "session_id", :string
    t.column "data", :text
    t.column "updated_at", :datetime
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "stations", :force => true do |t|
    t.column "ExpoCode", :string
    t.column "FileName", :string
    t.column "Basin", :string
    t.column "Track", :text
    t.column "lat", :text
    t.column "long", :text
    t.column "stnnum", :text
    t.column "event_code", :text
    t.column "cor_depth", :text
    t.column "max_press", :text
  end

  create_table "submissions", :force => true do |t|
    t.column "name", :text
    t.column "institute", :text
    t.column "Country", :text
    t.column "email", :text
    t.column "public", :text
    t.column "ExpoCode", :text
    t.column "Ship_Name", :text
    t.column "Line", :text
    t.column "cruise_date", :date
    t.column "action", :text
    t.column "notes", :text
    t.column "file", :text
    t.column "assigned", :boolean
    t.column "assimilated", :boolean
  end

  create_table "tracks", :force => true do |t|
    t.column "ExpoCode", :string
    t.column "FileName", :string
    t.column "Basin", :string
    t.column "Track", :text
  end

  create_table "users", :force => true do |t|
    t.column "username", :string
    t.column "password_salt", :string
    t.column "password_hash", :string
  end

end
