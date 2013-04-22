class FormatType
    attr_accessor :key_name, :short_name, :description
    def initialize(key_name, short_name, description)
        @key_name = key_name
        @short_name = short_name
        @description = description
    end
end

class FormatSection
    attr_accessor :title, :types, :subsections
    def initialize(title, types, subsections=[])
        @title = title
        @types = types
        @subsections = subsections
    end

    def has_subsections?
        not @subsections.empty?
    end
end
