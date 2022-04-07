# frozen_string_literal: true

module BlacklightRangeLimit
  class FacetFieldPresenter < Blacklight::FacetFieldPresenter
    def collapsed?
      !active? && facet_field.collapse
    end

    def active?
      search_state.filter(key).any?
    end

    def in_modal?
      search_state.params[:action] == "range_limit_panel"
    end

    def label
      view_context.facet_field_label(key)
    end
  end
end
