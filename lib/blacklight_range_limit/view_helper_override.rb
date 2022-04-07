  # Meant to be applied on top of Blacklight helpers, to over-ride
  # Will add rendering of limit itself in sidebar, and of constraings
  # display.
  module BlacklightRangeLimit::ViewHelperOverride



    def facet_partial_name(display_facet)
      config = range_config(display_facet.name)
      return config[:partial] || 'blacklight_range_limit/range_limit_panel' if config && should_show_limit(display_facet.name)
      super
    end

    def render_constraints_filters(params_or_search_state = params)
      Deprecation.warn(Blacklight::RenderConstraintsHelperBehavior, 'render_constraints_filters is deprecated')
      search_state = convert_to_search_state(params_or_search_state)
      # this line is the only departure from Blacklight 7.x, which checks explicitly for the key 'f' rather than filters
      return "".html_safe if search_state.filters.blank?

      safe_join(search_state.filters.map do |field|
        render_filter_element(field.key, field.values, search_state)
      end, "\n")
    end

    def render_search_to_s_filters(params_or_search_state = params)
      Deprecation.warn(Blacklight::RenderConstraintsHelperBehavior, 'render_search_to_s_filters is deprecated')
      search_state = convert_to_search_state(params_or_search_state)
      return "".html_safe if search_state.filters.blank?

      safe_join(search_state.filters.map do |field|
        render_search_to_s_element(facet_field_label(field.key),
                                   safe_join(field.values.collect do |value|
                                     facet_item_presenter(field.config, value, field.key).label
                                   end,
                                   tag.span(" #{t('blacklight.and')} ", class: 'filter-separator')))
        end, " \n ")
    end

    def remove_range_param(solr_field, params_or_search_state = params)
      search_state = convert_to_search_state(params_or_search_state)
      filter = search_state.filter(solr_field)
      return search_state.params unless filter.values.present?
      filter.remove(filter.values.first).params
    end

    # Looks in the solr @response for ["facet_counts"]["facet_queries"][solr_field], for elements
    # expressed as "solr_field:[X to Y]", turns them into
    # a list of hashes with [:from, :to, :count], sorted by
    # :from. Assumes integers for sorting purposes.
    def solr_range_queries_to_a(solr_field)
      return [] unless @response["facet_counts"] && @response["facet_counts"]["facet_queries"]

      array = []

      @response["facet_counts"]["facet_queries"].each_pair do |query, count|
        if query =~ /#{solr_field}: *\[ *(-?\d+) *TO *(-?\d+) *\]/
          array << { value: ($1..$2), count: count, hits: count}
        end
      end
      array = array.sort_by {|hash| hash[:value].first.to_i }
      return array
    end

    def range_config(solr_field)
      BlacklightRangeLimit.range_config(blacklight_config, solr_field)
    end

    private

    def range_params(my_params = params)
      return {} unless my_params[:range].is_a?(ActionController::Parameters) || my_params[:range].is_a?(Hash)

      my_params[:range].select do |_solr_field, range_options|
        next unless range_options

        [range_options['missing'].presence,
         range_options['begin'].presence,
         range_options['end'].presence].any?
      end
    end
  end
