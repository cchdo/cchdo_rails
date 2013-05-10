require 'treetop'

# Each search term has a type such as date, after, group, parameter, etc.
# The query is the string to search for
class SearchTerm
    attr_accessor :type, :query
  
    def initialize(query, type=nil)
        if type.nil?
            self.type, self.query = self.best_query_for(query)
        else
            self.type = type
            self.query = query
        end
    end

    def nil?
        return (self.type.nil? and self.query.nil?)
    end

    def inspect
        if self.nil?
            "ST(nil)"
        else
            "ST(#{self.type}, #{self.query})"
        end
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
    @@cruise_columns = Cruise.columns.map {|col| col.name}
    @@parameter_names = Parameter.columns.map {|col| col.name}.reject do |x|
        x =~ /(^(id|ExpoCode)$|(_PI|_Date)$)/
    end
    # Generate a list of where clauses and required parameters to be used in
    # SQL query.
    def query_type_to_clause_params()
        where_clause = nil
        sql_parameters = []
        param_query = false
        all_query = false

        type = self.type
        query = self.query
        if type == 'All'
            all_query = true
        elsif type == 'None'
            where_clause = '1=0'
        elsif type == 'Date'
            where_clause = "(Begin_Date REGEXP ? OR EndDate REGEXP ?)"
            sql_parameters << query
            sql_parameters << query
        elsif type == 'after'
            where_clause = "Begin_Date > ?"
            sql_parameters << query
        elsif type == 'before'
            where_clause = "EndDate < ?"
            sql_parameters << query
        elsif type == 'parameter'
            where_clause = "`bottle_dbs`.`parameters` LIKE ?"
            sql_parameters << "%#{query}%"
            param_query = true
        else
            if @@cruise_columns.include?(type)
                where_clause = "`cruises`.`#{type}` REGEXP ?"
                sql_parameters << query
            else
                Rails.logger.debug("Search: unrecognized type #{type}")
                where_clause = nil
            end
        end
        [where_clause, sql_parameters, param_query, all_query]
    end

protected

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

    def best_query_for(query)
        ignored_queries = [
            'commit', 'action', 'controller', 'post', 'FileType', 'limit', 'skip']
        if ignored_queries.include?(query)
            return [nil, nil]
        end

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
                        return ['parameter', val]
                    else
                        Rails.logger.info("Search: Ignored unknown parameter #{val}")
                    end
                else 
                    return [@@keywords[tok], val]
                end
            else
                Rails.logger.debug("Search: unrecognized search keyword #{tok}")
            end
            return [nil, nil]
        end
        # If full country name, replace it with the cchdo country abbrev.
        if COUNTRIES.include?(query.downcase)
            query = COUNTRIES[query.downcase]
            return ['Country', query]
        end
        # Check for four digit year queries
        if query =~ /\b\d{4}\b/
            ncruises = Cruise.count(:all, :conditions => ['`Begin_Date` REGEXP ?', query])
            if ncruises > 0
                return ['Date', query]
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
            return ['parameter', query]
        end
        if query == 'all_cruises'
            return ['all', query]
        end

        return [best_cruise_column_for_query(query, col_multiplier), query]
    end
end


class Term < Treetop::Runtime::SyntaxNode
    def eval
        SearchTerm.new(text_value)
    end

    # Strip nils and rewrite the query
    # Group terms that have a slash in them will be rewritten to the first half
    # or the second half
    def self.rewrite(root)
        if root.is_a?(Array)
            op = root[0]
            rest = root.slice(1..-1).map {|x| self.rewrite(x)}
            rest = rest.reject {|x| x.nil?}
            if rest.empty?
                return nil
            elsif rest.length == 1
                return rest[0]
            else
                return [op] + rest
            end
        else
            if root.type == 'Group' and root.query.include?('/')
                return [:or] + root.query.split('/').map {|x| SearchTerm.new(x, 'Group')}
            else
                return root
            end
        end
    end
end


Treetop.load(File.join(Rails.root, 'lib', 'search.treetop'))


class SearchController < ApplicationController
    def index
        find_by_params_query()
    end

    @@parser = SearchParser.new

protected

    def find_by_params_query(skip=0, limit=nil, count=false)
        @query = params[:query]
        limit = params[:limit]
        Rails.logger.debug("Search: query: #{@query}")

        resp = @@parser.parse("(#{@query})")
        if resp.nil?
            Rails.logger.error("Search: Unable to parse query")
            qtree = SearchTerm.new(nil, 'None')
        else
            qtree = resp.eval()
        end
        Rails.logger.debug("Search: rewriting #{qtree.inspect}")
        qtree = Term::rewrite(qtree)
        Rails.logger.debug("Search: rewritten #{qtree.inspect}")

        from_clause, sql_params, all_query = gen_from_qtree(qtree)

        cruises = Cruise.find_by_sql(
            ["SELECT DISTINCT #{@@select_clause} #{from_clause} " + 
             "#{gen_order_clause()} #{gen_limit_clause(skip, limit)}"
            ] + sql_params)

        @cruises = reduce_specifics(cruises)
        if not limit.nil? and count
            nresults = Cruise.count_by_sql(
                ["SELECT count(cruises.id) #{from_clause}"] + sql_params)
        else
            nresults = nil
        end

        @table_list = Hash.new{|h,k| h[k]={}}
        @param_list = Hash.new{|h,k| h[k]={}}
        for result in @cruises
            expo = result.ExpoCode
            @table_list[expo], @param_list[expo] = load_files_and_params(result)
        end
        [@cruises, qtree, nresults]
    end

private

    @@select_columns = [
        'ExpoCode', 'Line', 'Ship_Name', 'Country', 'Begin_Date', 'EndDate',
        'Chief_Scientist', 'id']
    @@select_clause = @@select_columns.map {|x| "`cruises`.`#{x}`" }.join(',')
  
    @@sortable_columns = [
        "Line", "ExpoCode", "Begin_Date", "Ship_Name", "Chief_Scientist",
        "Country"]
    @@sort_directions = ['ASC', 'DESC']
  
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

    def recursive_where(qtree)
        if not qtree.is_a?(Array)
            clause, params, param_query, all = qtree.query_type_to_clause_params()
            return [clause || '', params, param_query, all]
        else
            op = qtree[0]

            if op == :and
                op = 'AND'
            elsif op == :or
                op = 'OR'
            elsif op == :not
                op = 'NOT'
            else
                return ['', [], false, false]
            end

            if qtree.length == 3
                a_clause, a_params, a_pquery, a_all = recursive_where(qtree[1])
                b_clause, b_params, b_pquery, b_all = recursive_where(qtree[2])
                return ["(#{a_clause} #{op} #{b_clause})",
                        a_params + b_params, a_pquery || b_pquery, a_all || b_all]
            elsif qtree.length == 2
                a_clause, a_params, a_pquery, a_all = recursive_where(qtree[1])
                return ["#{op} #{a_clause}", a_params, a_pquery, q_all]
            else
                return ['', [], false, false]
            end
        end
    end

    def gen_from_qtree(qtree)
        where_clause, sql_params, parameter_query, all_query = recursive_where(qtree)
        sql = "FROM `cruises` "
        if parameter_query
            sql += 'LEFT JOIN `bottle_dbs` ON `cruises`.`ExpoCode` = `bottle_dbs`.`ExpoCode` '
        end
        unless where_clause.empty? and not all_query
            sql += "WHERE #{where_clause} "
        end
        [sql, sql_params, all_query]
    end
end
