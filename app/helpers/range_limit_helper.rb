module RangeLimitHelper

  def range_limit_url(options = {})
    main_app.url_for(search_state.to_h.merge(action: 'range_limit').merge(options))
  end
  BlacklightRangeLimit.deprecation.deprecate_methods :range_limit_url

  def range_limit_panel_url(options = {})
    search_facet_path(id: options[:id])
  end
  BlacklightRangeLimit.deprecation.deprecate_methods :range_limit_panel_url

  # type is 'begin' or 'end'
  def render_range_input(solr_field, type, input_label = nil, maxlength=4)
    range_form_component(solr_field).render_range_input(type, input_label, maxlength)
  end
  BlacklightRangeLimit.deprecation.deprecate_methods :render_range_input

  # type is 'min' or 'max'
  # Returns smallest and largest value in current result set, if available
  # from stats component response.
  def range_results_endpoint(solr_field, type)
    presenter = range_facet_field_presenter(solr_field)

    case type.to_s
    when 'min'
      presenter.min
    when 'max'
      presenter.max
    end
  end
  BlacklightRangeLimit.deprecation.deprecate_methods :range_results_endpoint

  def range_display(solr_field, my_params = params)
    facet_config = blacklight_config.facet_fields[solr_field]
    presenter = range_facet_field_presenter(solr_field)
    return unless presenter.selected_range

    facet_item = Blacklight::Solr::Response::Facets::FacetItem.new(value: presenter.selected_range, hits: presenter.response.total)

    facet_config.item_presenter.new(facet_item, facet_config, self, solr_field).label
  end
  BlacklightRangeLimit.deprecation.deprecate_methods :range_display

  ##
  # A method that is meant to be overridden downstream to format how a range
  # label might be displayed to a user. By default it just returns the value
  # as rendered by the presenter
  def format_range_display_value(value, solr_field)
    BlacklightRangeLimit.deprecation.warn(RangeLimitHelper, 'Helper #format_range_display_value is deprecated without replacement')
    facet_item_presenter(facet_configuration_for_field(solr_field), value, solr_field).label
  end

  # Show the limit area if:
  # 1) we have a limit already set
  # OR
  # 2) stats show max > min, OR
  # 3) count > 0 if no stats available.
  def should_show_limit(solr_field)
    presenter = range_facet_field_presenter(solr_field)

    presenter.selected_range ||
      (presenter.max && presenter.min && presenter.max > presenter.min) ||
      @response.total.positive?
  end

  def stats_for_field(solr_field)
    range_facet_field_presenter(solr_field).send(:stats_for_field)
  end
  BlacklightRangeLimit.deprecation.deprecate_methods :stats_for_field

  def stats_for_field?(solr_field)
    stats_for_field(solr_field).present?
  end
  BlacklightRangeLimit.deprecation.deprecate_methods :stats_for_field?

  def add_range_missing(solr_field, my_params = params)
    Blacklight::SearchState.new(my_params.except(:page), blacklight_config).filter(solr_field).add(Blacklight::SearchState::FilterField::MISSING)
  end
  BlacklightRangeLimit.deprecation.deprecate_methods :add_range_missing

  def add_range(solr_field, from, to, my_params = params)
    Blacklight::SearchState.new(my_params.except(:page), blacklight_config).filter(solr_field).add(from..to)
  end
  BlacklightRangeLimit.deprecation.deprecate_methods :add_range

  def has_selected_range_limit?(solr_field)
    range_facet_field_presenter(solr_field).selected_range.present?
  end
  BlacklightRangeLimit.deprecation.deprecate_methods :has_selected_range_limit?

  def selected_missing_for_range_limit?(solr_field)
    search_state.filter(solr_field).values.first == Blacklight::SearchState::FilterField::MISSING
  end
  BlacklightRangeLimit.deprecation.deprecate_methods :selected_missing_for_range_limit?

  def remove_range_param(solr_field, my_params = params)
    Blacklight::SearchState.new(my_params.except(:page), blacklight_config).filter(solr_field).remove(0..0)
  end

  # Looks in the solr @response for ["facet_counts"]["facet_queries"][solr_field], for elements
  # expressed as "solr_field:[X to Y]", turns them into
  # a list of hashes with [:from, :to, :count], sorted by
  # :from. Assumes integers for sorting purposes.
  def solr_range_queries_to_a(solr_field)
    range_facet_field_presenter(solr_field).range_queries.map do |item|
      { from: item.value.first, to: item.value.last, count: item.hits }
    end
  end
  BlacklightRangeLimit.deprecation.deprecate_methods :solr_range_queries_to_a

  def range_config(solr_field)
    BlacklightRangeLimit.range_config(blacklight_config, solr_field)
  end
  BlacklightRangeLimit.deprecation.deprecate_methods :range_config

  private

  def range_facet_field_presenter(key)
    facet_config = blacklight_config.facet_fields[key] || Blacklight::Configuration::FacetField.new(key: key, **BlacklightRangeLimit.default_range_config)
    facet_field_presenter(facet_config, Blacklight::Solr::Response::Facets::FacetField.new(key, [], response: @response))
  end

  def range_form_component(key)
    presenter = range_facet_field_presenter(key)

    BlacklightRangeLimit::RangeFormComponent.new(facet_field: presenter)
  end
end
