# Additional helper methods used by view templates inside this plugin.
module RangeLimitHelper
  def range_limit_url(options = {})
    main_app.url_for(search_state.to_h.merge(action: 'range_limit').merge(options))
  end

  def range_limit_panel_url(options = {})
    main_app.url_for(search_state.to_h.merge(action: 'range_limit_panel').merge(options))
  end

  # type is 'begin' or 'end'
  def render_range_input(solr_field, type, input_label = nil, maxlength=4)
    type = type.to_s

    default = params.dig("range", solr_field, type)

    html = number_field_tag("range[#{solr_field}][#{type}]", default, :maxlength=>maxlength, :class => "form-control text-center range_#{type}")
    html += label_tag("range[#{solr_field}][#{type}]", input_label, class: 'sr-only visually-hidden') if input_label.present?
    html
  end

  # type is 'min' or 'max'
  # Returns smallest and largest value in current result set, if available
  # from stats component response.
  def range_results_endpoint(solr_field, type)
    stats = stats_for_field(solr_field)

    return nil unless stats
    # StatsComponent returns weird min/max when there are in
    # fact no values
    return nil if @response.total == stats["missing"]

    return stats[type].to_s.gsub(/\.0+/, '')
  end

  def range_display(solr_field, my_params = params)
    value = search_state.filter(solr_field).values.first || {}
    format_range_display_value(value, solr_field)
  end

  ##
  # A method that is meant to be overridden downstream to format how a range
  # label might be displayed to a user. By default it just returns the value
  # as rendered by the presenter
  def format_range_display_value(value, solr_field)
    facet_item_presenter(facet_configuration_for_field(solr_field), value, solr_field).label
  end

  # Show the limit area if:
  # 1) we have a limit already set
  # OR
  # 2) stats show max > min, OR
  # 3) count > 0 if no stats available.
  def should_show_limit(solr_field)
    stats = stats_for_field(solr_field)

    (params.dig("range", solr_field)) ||
    (  stats &&
      stats["max"] > stats["min"]) ||
    ( !stats  && @response.total > 0 )
  end

  def stats_for_field(solr_field)
    @response.dig("stats", "stats_fields", solr_field)
  end

  def stats_for_field?(solr_field)
    stats_for_field(solr_field).present?
  end

  def add_range_missing(solr_field, my_params = params)
    my_params = search_state.reset(my_params.except(:page))
    my_params.filter(solr_field).add(Blacklight::SearchState::FilterField::MISSING).to_h
  end

  def add_range(solr_field, from, to, my_params = params)
    my_params = search_state.reset(my_params.except(:page))
    from = '*' unless from.present?
    to = '*' unless to.present?
    my_params.filter(solr_field).add((from.to_s..to.to_s)).to_h
  end

  def has_selected_range_limit?(solr_field)
    search_state.filter(solr_field).values.present?
  end

  def selected_missing_for_range_limit?(solr_field)
    search_state.filter(solr_field).values.include? Blacklight::SearchState::FilterField::MISSING
  end

end
