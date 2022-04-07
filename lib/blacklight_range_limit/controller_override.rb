# Meant to be applied on top of a controller that implements
# Blacklight::SolrHelper. Will inject range limiting behaviors
# to solr parameters creation.
require 'blacklight_range_limit/segment_calculation'
module BlacklightRangeLimit
  module ControllerOverride
    extend ActiveSupport::Concern

    included do
      helper BlacklightRangeLimit::ViewHelperOverride
      helper RangeLimitHelper
      helper_method :has_range_limit_parameters?
    end
    module ClassMethods
      def configure_blacklight(*args, &block)
        blacklight_config.configure(*args, &block)

        blacklight_config.facet_fields.each do |key, facet_field|
          next unless facet_field.range
          # set range facet default configs
          facet_field.item_presenter ||= BlacklightRangeLimit::FacetItemPresenter
          facet_field.filter_class ||= BlacklightRangeLimit::SearchState::FilterField
        end
      end
    end
    # Action method of our own!
    # Delivers a _partial_ that's a display of a single fields range facets.
    # Used when we need a second Solr query to get range facets, after the
    # first found min/max from result set.
    def range_limit
      # We need to swap out the add_range_limit_params search param filter,
      # and instead add in our fetch_specific_range_limit filter,
      # to fetch only the range limit segments for only specific
      # field (with start/end params) mentioned in query params
      # range_field, range_start, and range_end

      @response, _ = search_service.search_results do |search_builder|
        search_builder.except(:add_range_limit_params).append(:fetch_specific_range_limit)
      end
      render('blacklight_range_limit/range_segments', :locals => {:solr_field => params[:range_field]}, :layout => !request.xhr?)
    end

    def has_range_limit_parameters?(my_params = params)
      my_params[:range] &&
        my_params[:range].to_unsafe_h.any? do |key, v|
          v.present? && v.respond_to?(:'[]') &&
          (v["begin"].present? || v["end"].present? || v["missing"].present?)
        end
    end

    def range_limit_panel
      @facet = blacklight_config.facet_fields[params[:id]]
      raise ActionController::RoutingError, 'Not Found' unless @facet

      @response = search_service.search_results.first

      respond_to do |format|
        format.html do
          # Draw the partial for the "more" facet modal window:
          return render 'blacklight_range_limit/range_limit_panel', layout: !request.xhr?
        end
      end
    end
  end
end
