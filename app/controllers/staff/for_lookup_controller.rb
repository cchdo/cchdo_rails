class Staff::ForLookupController < ApplicationController
    def pis
        pis = Cruise.find(:all,:select => ["DISTINCT Chief_Scientist"])
        for_lookup('pis', pis) {|x| x.Chief_Scientist }
    end

    def expocodes
        expocodes = Cruise.find(:all,:select => ["DISTINCT ExpoCode"])
        for_lookup('expocodes', expocodes) {|x| x.ExpoCode }
    end

    def ships
        ships = Cruise.find(:all,:select => ["DISTINCT Ship_Name"])
        for_lookup('ships', ships) {|x| x.Ship_Name }
    end

    def countries
        countries = Cruise.find(:all,:select => ["DISTINCT Country"])
        for_lookup('countries', countries) {|x| x.Country }
    end

    def contacts
        contacts = Contact.find(:all, :select => ["DISTINCT LastName"])
        for_lookup('contacts', contacts) {|x| x.LastName }
    end

    def parameters
        parameters = Parameter.column_names.delete_if do |x|
            x =~ /ExpoCode/ or x =~ /id/ or x =~ /_PI/ or x =~ /Date/i
        end
        for_lookup('parameters', parameters) {|x| x}
    end

    def lines
        @lines = Cruise.find(:all, :select => ["DISTINCT Line"])
        for_lookup('lines', lines) {|x| x.Line}
    end

protected
    def for_lookup(varname, list, &code)
        headers['Content-Type'] = 'text/javascript'
        list_contents = list.map do |item|
            "\"#{code.call(item)}\""
        end
        str = "var #{varname} = [#{list_contents.join(',')}];"
        render :text => str
    end
end
