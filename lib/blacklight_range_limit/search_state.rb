# frozen_string_literal: true
require 'blacklight'

module BlacklightRangeLimit
  # This mixin adds range parameter parsing to your app's search state class
  module SearchState
    def filter_class(field)
      return field.filter_class if field.filter_class
      field.range ? BlacklightRangeLimit::SearchState::FilterField : Blacklight::SearchState::FilterField
    end

    def filter(field_key_or_field)
      field = field_key_or_field if field_key_or_field.is_a? Blacklight::Configuration::Field
      field ||= blacklight_config.facet_fields[field_key_or_field]
      field ||= Blacklight::Configuration::NullField.new(key: field_key_or_field)

      filter_class(field).new(field, self)
    end

    def has_selected_range_limit?(field_key_or_field)
      solr_field = field_key_or_field.is_a?(Blacklight::Configuration::Field) ? field_key_or_field.key : field_key_or_field
      return false unless @params.dig("range", solr_field)
      %W[begin end missing].detect { |k| @params.dig("range", solr_field).fetch(k, nil).present? }
    end

    def selected_missing_for_range_limit?(field_key_or_field)
      solr_field = field_key_or_field.is_a?(Blacklight::Configuration::Field) ? field_key_or_field.key : field_key_or_field
      @params.dig("range", solr_field, "missing")
    end
  end
  require 'blacklight_range_limit/search_state/default'
  require 'blacklight_range_limit/search_state/filter_field'
end