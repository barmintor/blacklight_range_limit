# frozen_string_literal: true

module BlacklightRangeLimit
  class FacetItemPresenter < Blacklight::FacetItemPresenter
    attr_reader :facet_item, :facet_config, :view_context, :search_state, :facet_field

    delegate :key, to: :facet_config

    def initialize(facet_item, facet_config, view_context, facet_field, search_state = view_context.search_state)
      @facet_item = facet_item
      @facet_config = facet_config
      @view_context = view_context
      @facet_field = facet_field
      @search_state = search_state
    end

    ##
    # Check if the query parameters have the given facet field with the
    # given value.
    def selected?
      search_state.filter(facet_config).include?(value)
    end

    ##
    # Get the displayable version of a facet's value
    #
    # @return [String]
    def label
      item_value = value
      return "" unless item_value.present?

      if item_value == Blacklight::SearchState::FilterField::MISSING
        return view_context.t('blacklight.range_limit.missing')
      elsif item_value.is_a? Range
        if item_value.first == item_value.last
          return view_context.t(
            'blacklight.range_limit.single_html',
            begin: format_range_display_value(item_value.first),
            begin_value: item_value.first
          )
        else
          return view_context.t(
            'blacklight.range_limit.range_html',
            begin: format_range_display_value(item_value.first),
            begin_value: item_value.first,
            end: format_range_display_value(item_value.last),
            end_value: item_value.last
          )
        end
      end

      ''
    end

    def value
      if facet_item.respond_to? :value
        facet_item.value
      else
        facet_item
      end
    end

    def href(path_options = {})
      if selected?
        remove_href
      else
        add_href(path_options)
      end
    end

    # @private

    ##
    # A method that is meant to be overridden downstream to format how a range
    # label might be displayed to a user. By default it just returns the value
    # as rendered by the default presenter
    def format_range_display_value(value)
      Blacklight::FacetItemPresenter.new(value, facet_config, view_context, facet_field).label
    end

    def remove_href(path = search_state)
      new_state = search_state.reset_search(path.to_h)
      new_state = new_state.filter(key).remove(value) if new_state.filter(key).any?
      view_context.search_action_path(new_state.to_h)
    end

    # @private
    def add_href(path_options = {})
      if facet_config.url_method
        view_context.public_send(facet_config.url_method, facet_config.key, value)
      else
        new_state = search_state.reset_search(path_options)
        new_state = new_state.filter(facet_config.key).add(value)
        view_context.search_action_path(new_state.to_h)
      end
    end

    private

    def facet_field_presenter
      @facet_field_presenter ||= view_context.facet_field_presenter(facet_config, {})
    end
  end
end
