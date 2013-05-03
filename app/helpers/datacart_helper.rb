module DatacartHelper
    def datacart_link(act, link={}, html={})
        html[:rel] = ' nofollow' + (html[:ref] || '')
        link_to(content_tag(:div, act, :class => "datacart-icon"), link, html)
    end

    def datacart_link_file(act, dir, basename)
        if act == 'Remove'
            action = 'remove'
            classname = 'datacart-link datacart-remove'
            title = 'Remove from data cart'
        elsif act == 'Add'
            action = 'add'
            classname = 'datacart-link datacart-add'
            title = 'Add to data cart'
        end

        datacart_link(act,
            {
                :controller => 'datacart',
                :action => action,
                :dirid => dir.id,
                :file => basename
            }, {
                :class => classname,
                :title => title
            })
    end

    def datacart_link_cruise_action(act, cruise)
        if act == 'Remove'
            action = 'remove_cruise'
            classname = 'datacart-link datacart-cruise datacart-remove'
            title = 'Remove all cruise data from data cart'
        elsif act == 'Add'
            action = 'add_cruise'
            classname = 'datacart-link datacart-cruise datacart-add'
            title = 'Add all cruise data to data cart'
        end

        datacart_link("#{act} all",
            {
                :controller => 'datacart',
                :action => action,
                :cruise_id => cruise.id
            }, {
                :class => classname,
                :title => title
            })
    end

    def datacart_link_cruises(cruises, div_attributes={})
        nfiles_in_cart_all = 0
        nfiles_all = 0
        for cruise in cruises
            nfiles_in_cart, nfiles = @datacart.cruise_files_in_cart(cruise)
            nfiles_in_cart_all += nfiles_in_cart
            nfiles_all += nfiles
        end
        if nfiles_in_cart_all > 0
            link_str = 'Remove all data in result'
            link_params = {
                :controller => 'datacart',
                :action => 'remove_cruises',
                :ids => cruises.map {|x| x.id}
            }
            link_attrs = {
                :class => 'datacart-link datacart-results datacart-remove',
                :title => 'Remove all result data from data cart',
            }
        elsif nfiles_all > 0
            link_str = 'Add all data in result'
            link_params = {
                :controller => 'datacart',
                :action => 'add_cruises',
                :ids => cruises.map {|x| x.id}
            }
            link_attrs = {
                :class => 'datacart-link datacart-results datacart-add',
                :title => 'Add all result data to data cart',
            }
        else
            link = ''
            link_params = {}
            link_attrs = {}
        end
        div_attrs = {:class => "datacart-cruises-links"}
        div_attrs_proper = div_attributes.merge(div_attrs)
        if div_attributes.include?(:class)
            puts div_attributes.inspect
            div_attrs_proper[:class] = "#{div_attrs[:class]} #{div_attributes[:class]}"
        end
        link = datacart_link(link_str, link_params, link_attrs)
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
