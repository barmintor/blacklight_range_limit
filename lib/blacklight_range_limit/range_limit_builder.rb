require 'blacklight_range_limit/segment_calculation'

module BlacklightRangeLimit
  module RangeLimitBuilder
    extend ActiveSupport::Concern
    include BlacklightRangeLimit::SegmentCalculation

    included do
      # Use setters so not to propagate changes
      self.default_processor_chain += [:add_range_limit_params]
    end

    # Method added to to fetch proper things for date ranges.
    def add_range_limit_params(solr_params)
      ranged_facet_configs =
        blacklight_config.facet_fields.select { |key, config| config.range }
      # In ruby 1.8, hash.select returns an array of pairs, in ruby 1.9
      # it returns a hash. Turn it into a hash either way.
      ranged_facet_configs = Hash[ ranged_facet_configs ] unless ranged_facet_configs.kind_of?(Hash)

      ranged_facet_configs.each_pair do |field_key, config|
        solr_params["stats"] = "true"
        solr_params["stats.field"] ||= []
        solr_params["stats.field"] << config.field

        range_config = BlacklightRangeLimit.range_config(blacklight_config, config.field)
        next if range_config[:segments] == false

        filter = search_state.filter(field_key)
        filter_value = filter.values.first
        boundaries = filter_value.blank? ? range_config[:assumed_boundaries] : boundaries_from_value(filter_value)
        add_range_segments_to_solr!(solr_params, field_key, boundaries[0], boundaries[1]) if boundaries
      end

      solr_params
    end

    # @param [Range, Blacklight::SearchState::FilterField::MISSING] filter_value
    # @return [Array<Integer>, FalseClass]
    def boundaries_from_value(filter_value)
      return false if filter_value == Blacklight::SearchState::FilterField::MISSING
      start = filter_value.first
      finish = filter_value.last
      if (start != "*" && finish != "*")
        return [start.to_i, finish.to_i]
      end
      false
    end

    # Another processing method, this one is NOT included in default processing chain,
    # it is specifically swapped in *instead of* add_range_limit_params for
    # certain ajax requests that only want to fetch range limit segments for
    # ONE field. 
    #
    # It turns off facetting and sets rows to 0 as well, only results for
    # single specified field are needed. 
    #
    # Specified field and parameters are specified in incoming parameters
    # range_field, range_start, range_end
    def fetch_specific_range_limit(solr_params)
      field_key = blacklight_params[:range_field] # what field to fetch for
      start = blacklight_params[:range_start].to_i
      finish = blacklight_params[:range_end].to_i

      add_range_segments_to_solr!(solr_params, field_key, start, finish )

      # Remove all field faceting for efficiency, we won't be using it.
      solr_params.delete("facet.field")
      solr_params.delete("facet.field".to_sym)

      # We don't need any actual rows either
      solr_params[:rows] = 0      

      return solr_params
    end

  end
end
