require 'builder'
task :update_spatial_groups => :environment do
    # rake --silent update_spatial_groups RAILS_ENV=production

    Cruise.all.each do |cruise|
        groups = cruise.groups
        basin_names = ['Arctic', 'Atlantic', 'Indian', 'Pacific', 'Southern']
        simple_basins = []
        basins = Set.new()
        for basin in basin_names
            if groups.include?(basin)
                simple_basins << basin
                basins << basin
            end
        end

        for basin in basin_names
            if cruise.Group and cruise.Group.include?(basin)
                basins << basin
            end
        end

        spg = cruise.spatial_groups
        unless basins.empty?
            unless spg
                spg = SpatialGroups.new()
                cruise.spatial_groups = spg
                spg.ExpoCode = cruise.ExpoCode
                spg.area = cruise.Line
            end

            puts "#{cruise.ExpoCode}\t#{basins.to_a.join(', ')}"
            for basin in basins
                getsym = basin.downcase.to_sym
                setsym = "#{basin.downcase}=".to_sym
                unless spg.send(getsym)
                    spg.send(setsym, true)
                end
            end
            spg.save()
        else
            if spg
                puts "#{cruise.ExpoCode} has basins not in Group"
            end
        end

        cruise.Group = (groups - simple_basins).join(',')
        cruise.save()
    end

    Cruise.find(:all, :include => :spatial_groups).each do |cruise|
        unless cruise.spatial_groups
            puts "#{cruise.ExpoCode} has no spatial groups."
        end
    end
end
