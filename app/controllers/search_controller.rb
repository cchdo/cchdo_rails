# Each search term has a type such as date, after, group, parameter, etc.
# The query is the string to search for
class SearchTerm
    attr_accessor :type, :query
    def initialize(type, query)
        self.type = type
        self.query = query
    end
end

class SearchController < ApplicationController
    def index
        find_by_params_query()
    end

protected

    def find_by_params_query(skip=0, limit=nil, count=false)
        @query = params[:query]
        return unless @query and @query =~ /\w/

        queries = tokenize_query_string(@query)
        terms = best_query_types(queries)

        from_clause, sql_parameters, limit = gen_from_clause(terms, limit)

        Rails.logger.debug(terms.inspect)
        Rails.logger.debug(from_clause.inspect)
        Rails.logger.debug(sql_parameters.inspect)

        if terms.empty?
            cruises = []
        else
            cruises = Cruise.find_by_sql(
                ["SELECT DISTINCT #{@@select_clause} #{from_clause} " + 
                 "#{gen_order_clause()} #{gen_limit_clause(skip, limit)}"
                ] + sql_parameters)
        end

        @cruises = reduce_specifics(cruises)
        if not limit.nil? and count
            nresults = Cruise.count_by_sql(
                ["SELECT count(cruises.id) #{from_clause}"] + sql_parameters)
        else
            nresults = nil
        end

        # XXX
        @cruises = []

        @table_list = Hash.new{|h,k| h[k]={}}
        @param_list = Hash.new{|h,k| h[k]={}}
        for result in @cruises
            expo = result.ExpoCode
            @table_list[expo], @param_list[expo] = load_files_and_params(result)
        end
        [@cruises, terms, nresults]
    end

private

    # Return the Cruise column with the most hits
    # exclude id
    # Defaults to Group column
    def best_cruise_column_for_query(query, col_multiplier={})
        cur_max = 0
        best_column = nil
        for column in @@cruise_columns
            next if column == 'id'
            ncruises = Cruise.count(:all, :conditions => ["`#{column}` regexp ?", query])
            multiplier = col_multiplier[column] || 1
            if ncruises * multiplier > cur_max
                cur_max = ncruises
                best_column = column
            end
        end
        best_column || 'Group'
    end
  
    @@keywords = {
        'group' => 'Group',
        'chief_scientist' => 'Chief_Scientist',
        'expocode' => 'ExpoCode',
        'alias' => 'Alias',
        'ship_name' => 'Ship_Name',
        'ship' => 'Ship_Name',
        'line' => 'Line',
        'date' => 'Date',
        'parameter' => 'Parameter',
        'after' => 'after',
        'before' => 'before',
    }
    @@select_columns = [
        'ExpoCode', 'Line', 'Ship_Name', 'Country', 'Begin_Date', 'EndDate',
        'Chief_Scientist', 'id']
    @@select_clause = @@select_columns.map {|x| "`cruises`.`#{x}`" }.join(',')
  
    @@cruise_columns = Cruise.columns.map {|col| col.name}
    @@parameter_names = Parameter.columns.map {|col| col.name}.reject do |x|
        x =~ /(^(id|ExpoCode)$|(_PI|_Date)$)/
    end
    @@sortable_columns = [
        "Line", "ExpoCode", "Begin_Date", "Ship_Name", "Chief_Scientist",
        "Country"]
    @@sort_directions = ['ASC', 'DESC']
  
    def tokenize_query_string(query_str)
        # Erase illegal characters
        query_str = query_str.strip.tr(";'$%&*()<>@~`+=#?|{}[]", '.')

        # Get the literals and replace them with place holders
        literals = query_str.scan(/".*?"/)
        literals.each {|literal| query_str.gsub!(literal, '?')}
        literals.map! {|query| query[1..-2]}

        # Make all keyworded queries one chunk
        query_str.gsub!(/\:\s*/, ':')

        # All spaces and slashes are now delimiters
        query_str.gsub!(/\s+|\//, ';')

        # Delete all keywords without values
        query_str.gsub!(/\w+\:;/, '')

        # Get all the terms
        terms = query_str.split(';')

        # Fill in all place holders; they are in order of appearance
        count = 0
        terms.each do |term|
            if term.include? '?'
                term.gsub!('?', literals[count])
                count += 1
            end
        end
        return terms
    end

    def best_query_types(queries)
        ignored_queries = [
            'commit', 'action', 'controller', 'post', 'FileType', 'limit', 'skip']
        queries = queries - ignored_queries

        terms = []

        for query in queries
            col_multiplier = {
                'Group' => 1
            }
            # keyword search
            if query =~ /^([\w-]+)\:\s*([\w-]+)$/
                tok = $1.downcase
                val = $2
                if @@keywords.keys.include?(tok)
                    if tok == 'parameter'
                        if @@parameter_names.include?(val)
                            terms << SearchTerm.new('parameter', val)
                        else
                            Rails.logger.info("Ignored unknown parameter #{val}")
                        end
                    else 
                        terms << SearchTerm.new(@@keywords[tok], val)
                    end
                else
                    Rails.logger.debug("Unrecognized search keyword #{tok}")
                end
                next
            end
            # If full country name, replace it with the cchdo country abbrev.
            if COUNTRIES.include?(query.downcase)
                query = COUNTRIES[query.downcase]
                terms << SearchTerm.new('Country', query)
                next
            end
            # Check for four digit year queries
            if query =~ /\b\d{4}\b/
                ncruises = Cruise.count(:all, :conditions => ['`Begin_Date` REGEXP ?', query])
                if ncruises > 0
                    terms << SearchTerm.new('Date', query)
                    next
                end
            end

            # WOCE line numbers
            # Change queries formatted like I9 or A9.5 to be I09 or A09.5 and
            # weight column selection heavily toward Group column
            if query =~ /^([a-zA-Z]{1,3})(\d{1,2})([\w.]*)$/i
                if $2.length < 2
                    query = "#{$1}0#{$2}#{$3}"
                else
                    query = "#{$1}#{$2}#{$3}"
                end
                col_multiplier['Group'] = 100
            end
            # Check for parameters
            if @@parameter_names.include?(query)
                terms << SearchTerm.new('parameter', query)
                next
            end
            if query == 'all_cruises'
                terms << SearchTerm.new('all', query)
                next
            end

            terms << SearchTerm.new(
                best_cruise_column_for_query(query, col_multiplier), query)
        end
        terms
    end

    # Generate a list of where clauses and required parameters to be used in
    # SQL query.
    def query_type_to_clause_params(term, limit)
        where_clauses = []
        sql_parameters = []
        type = term.type
        query = term.query
        if type == 'all'
            limit = nil
        elsif type == 'Date'
            where_clauses << "(Begin_Date REGEXP ? OR EndDate REGEXP ?)"
            sql_parameters << query
            sql_parameters << query
        elsif type == 'after'
            where_clauses << "Begin_Date > ?"
            sql_parameters << query
        elsif type == 'before'
            where_clauses << "EndDate < ?"
            sql_parameters << query
        elsif type == 'parameter'
            where_clauses << "`bottle_dbs`.`parameters` LIKE ?"
            sql_parameters << "%#{query}%"
        else
            if @@cruise_columns.include?(type)
                where_clauses << "`cruises`.`#{type}` REGEXP ?"
                sql_parameters << query
            else
                Rails.logger.debug("Search: unrecognized type #{type}")
            end
        end
        [where_clauses, sql_parameters, limit]
    end

    def gen_order_clause
        if sort_by = params[:Sort] and @@sortable_columns.include?(sort_by)
            dir = params[:Sort_dir]
            if not dir or not @@sort_directions.include?(dir)
                dir = @@sort_directions[0]
            end
            @sort_statement = "ORDER BY cruises.#{sort_by} #{dir}"
        else
            @sort_statement = ""
        end
        @sort_statement
    end

    def gen_limit_clause(skip=0, limit=nil)
        (limit && "LIMIT #{skip}, #{limit}") || ''
    end

    def gen_from_clause(terms, limit)
        where_clauses = []
        sql_parameters = []
        parameter_query = false
        for term in terms
            clauses, params, limit = query_type_to_clause_params(term, limit)
            where_clauses += clauses
            sql_parameters += params
            if term.type == 'parameter'
                parameter_query = true
            end
        end
        sql = "FROM cruises "
        if parameter_query
            sql += 'LEFT JOIN `bottle_dbs` ON cruises.ExpoCode = bottle_dbs.ExpoCode '
        end
        unless where_clauses.empty?
            sql += "WHERE #{where_clauses.join(' AND ')} "
        end
        [sql, sql_parameters]
    end
end
