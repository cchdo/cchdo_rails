require 'set'

# Datacart contains files that are meant to be bulk downloaded.
class Datacart < Set
    extend Forwardable

    def initialize enum = nil, &block
        @hash = ActiveSupport::OrderedHash.new
        super
    end
end
