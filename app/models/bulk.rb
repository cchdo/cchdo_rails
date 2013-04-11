require 'set'

# Bulk contains files that are meant to be bulk downloaded.
class Bulk < Set
    extend Forwardable

    def initialize enum = nil, &block
        @hash = ActiveSupport::OrderedHash.new
        super
    end
end
