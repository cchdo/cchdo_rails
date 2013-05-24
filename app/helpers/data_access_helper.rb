module DataAccessHelper
    def self_or_empty(x)
        x ? x : ''
    end

    def estimate_textarea_height(text, width=80)
        if text.nil?
            return 0
        end
        # Estimate the textarea height for the given text and width in monospace.
        count = 0
        for line in text.split("\n")
            count += 1 + line.length / width
        end
        return count + 1
    end
end
