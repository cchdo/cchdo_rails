module DataAccessHelper
    def self_or_empty(x)
        x ? x : ''
    end

    def contact_cruises(cruise)
        items = []
        for cc in cruise.contact_cruises
            next if not cc.contact
            link_contact = link_to("#{cc.contact.LastName}", "/contact?id=#{cc.contact.id}")
            link_inst = cc.institution
            if link_inst.blank?
                link_inst = nil
            end
            links = [link_contact, link_inst].compact
            items << links.join('/')
        end
        items.join(', ')
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
