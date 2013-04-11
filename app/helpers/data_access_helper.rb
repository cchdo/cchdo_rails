module DataAccessHelper
    def self_or_empty(x)
        x ? x : ''
    end
end
