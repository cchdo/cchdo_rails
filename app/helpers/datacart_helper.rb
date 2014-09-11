module DatacartHelper
    def datacart_link(act, link={}, html={})
        html[:rel] = ' nofollow' + (html[:ref] || '')
        link_to(content_tag(:div, "", :class => "datacart-icon"), "javascript:;", html)
    end

    def datacart_link_file(dir, basename, expocode)
        act = "placeholder"
        classname = 'datacart-link-file-placeholder'

        datacart_link(act,
            {
            }, {
              :filepath => dir.FileName + "/" + basename,
                :expocode => expocode,
                :class => classname,
            })
    end

    def datacart_link_cruise_action(act, cruise)
        classname = 'datacart-cruise-placeholder'

        datacart_link("#{act} all",
            {
            }, {
                :class => classname,
                :expocode => cruise.ExpoCode
            })
    end

    def datacart_link_cruises(cruises, div_attributes={})
        link_params = {
        }
        link_attrs = {
            :class => 'datacart-results-placeholder',
        }
        div_attrs = {:class => "datacart-cruises-links"}
        div_attrs_proper = div_attributes.merge(div_attrs)
        if div_attributes.include?(:class)
            puts div_attributes.inspect
            div_attrs_proper[:class] = "#{div_attrs[:class]} #{div_attributes[:class]}"
        end
        link = datacart_link("", link_params, link_attrs)
        content_tag(:div, link, div_attrs_proper)
    end

    def datacart_link_cruise(cruise)
        nfiles_in_cart, nfiles = @datacart.cruise_files_in_cart(cruise)
        if nfiles_in_cart > 0
            link = datacart_link_cruise_action('Remove', cruise)
        elsif nfiles > 0
            link = datacart_link_cruise_action('Add', cruise)
        else
            link = ''
        end
        content_tag(:div, link, :class => "datacart-cruise-links")
    end
end
