class MasterResolver

  attr_reader :errors, :values

  def initialize(report_concepts, search, current_user, actions_required = ['view data distribution', 'view limited data distribution'])
    @report_concepts = report_concepts.compact.to_a
    @current_user = current_user
    @actions_required = actions_required
    @search = search
    @errors = []
    @super_grid = {}
    @values = []
    set_identifier_variable
    set_values
  end

  def all_sources
    (@search.sources.to_a | @report_concepts.collect(&:source)).uniq
  end

  # The identifier variable is used to link across multiple datasets
  def set_identifier_variable
    identifier_variables = []
    Variable.current.where( variable_type: 'identifier' ).with_source(all_sources.collect(&:id)).each do |variable|
      identifier_variables << variable if not all_sources.collect{|s| s.variables.where( variable_type: 'identifier').pluck(:id).include?(variable.id) }.include?(false)
    end
    @identifier_variable = identifier_variables.first
  end

  def set_values
    all_sources.each do |source|
      wrapper = Aqueduct::Builder.wrapper(source, @current_user)

      mappings_for_select_clause = []
      @report_concepts.each_with_index do |report_concept, index|
        m = source.mappings.where( variable_id: report_concept.variable.id ).first if report_concept.source == source
         # TODO remove `variable: m.variable` from hash below, not needed.
        mappings_for_select_clause << { table: m.table, column: m.column, variable: m.variable, report_concept_index: index, mapping: m } if m and m.user_can_view?(@current_user, @actions_required)
      end

      if mappings_for_select_clause.size > 0 and @identifier_variable
        m = source.mappings.where( variable_id: @identifier_variable.id ).first
        mappings_for_select_clause.prepend( { table: m.table, column: m.column } ) if m
      end

      mappings_for_select_clause.uniq!

      tables_covered_by_concepts = (mappings_for_select_clause.collect{|m| m[:table]} | source_tables(source)).uniq
      join_conditions_hash = source.join_conditions(tables_covered_by_concepts, @current_user)
      @errors += join_conditions_hash[:errors]

      result_hash = wrapper.sql_codes
      sql_open = result_hash[:open]
      sql_close = result_hash[:close]
      sql_statement = "SELECT #{mappings_for_select_clause.collect{|m| m[:table] + '.' + sql_open + m[:column] + sql_close}.join(',')} FROM #{tables_covered_by_concepts.join(', ')} WHERE #{join_conditions_hash[:result].join(' and ')}#{' and ' unless join_conditions_hash[:result].blank?}#{source_conditions(source)}"
      if mappings_for_select_clause.size > 0
        begin
          wrapper.connect
          (results, number_of_rows) = wrapper.query(sql_statement)
        rescue
          results = []
        ensure
          wrapper.disconnect
        end
        results.to_a.each do |row|
          @super_grid[row[0].to_s] ||= []
          mappings_for_select_clause.each_with_index do |mapping_hash, mapping_index|
            @super_grid[row[0].to_s][mapping_hash[:report_concept_index]] = mapping_hash[:mapping].human_normalized_value(row[mapping_index]) if mapping_hash[:report_concept_index]
          end

        end
      end
    end

    @super_grid.each do |key, values|
      @values << values
    end
  end

  private

  def generate_resolvers(source)
    @search.criteria.collect{|qc| Resolver.new(qc, source, @current_user)}
  end

  def source_tables(source)
    generate_resolvers(source).collect(&:tables).flatten.compact.uniq
  end

  def source_conditions(source)
    resolvers = generate_resolvers(source)
    join_hash = source.join_conditions(source_tables(source), @current_user)
    resolver_conditions = resolvers.collect(&:conditions_for_entire_search).join(' ')
    resolver_conditions = "( #{resolver_conditions} )" unless resolver_conditions.blank?
    [join_hash[:result], resolver_conditions].select{|c| not c.blank?}.join(' and ')
  end

end
