# frozen_string_literal: true

module BlacklightRangeLimit
  module SearchState
    class FilterField < ::Blacklight::SearchState::FilterField
      ## Override
      # @param [Range,Blacklight::SearchState::FilterField::MISSING,#value] a range filter item to add to the url
      # @return [Blacklight::SearchState] new state
      def add(value = nil)
        value = value.value if value.respond_to? :value

        new_state = search_state.reset_search
        my_params = new_state.to_h
        my_params[:range] ||= {}
        my_params[:range][key] ||= {}
        if value == Blacklight::SearchState::FilterField::MISSING
          my_params[:range][key]["missing"] = "true"
        else
          my_params[:range][key]["begin"] = value.first
          my_params[:range][key]["end"] = value.last
          my_params[:range][key].delete("missing")
        end
        new_state.reset(my_params)
      end

      ## Override
      # @param [Range,Blacklight::SearchState::FilterField::MISSING,#value] a range filter item to remove from the url
      # @return [Blacklight::SearchState] new state
      def remove(value = nil)
        new_state = search_state.reset_search
        my_params = new_state.to_h
        range_value = my_params.dig(:range, key) || {}
        if range_value.present?
          range_value.delete('begin') if range_value['begin'].to_s.eql?(value.first.to_s)
          range_value.delete('end') if range_value['end'].to_s.eql?(value.last.to_s)
          range_value.delete('missing') if value == Blacklight::SearchState::FilterField::MISSING
          my_params[:range]&.delete(key) if range_value.blank?
        end
        my_params.delete(:range) unless my_params[:range].present?
        new_state.reset(my_params)
      end

      ## Override
      # @return [Array] an array of applied filters
      def values
        candidate_values = search_state.params[:range]
        range_params = candidate_values[key] if candidate_values.is_a? Hash
        range_params.present? ? [value_for(range_params)].compact : []
      end
      delegate :any?, to: :values

      def value_for(range_params)
        return nil unless range_params.is_a?(Hash) || range_params.is_a?(ActionController::Parameters)
        return Blacklight::SearchState::FilterField::MISSING if range_params['missing'].present?
        if range_params['begin'].present? || range_params['end'].present?
          first = range_params['begin'].present? ? range_params['begin'] : '*'
          last = range_params['end'].present? ? range_params['end'] : '*'
          return (first..last)
        end
      end
      ## Override
      # @param [String,#value] a filter to remove from the url
      # @return [Boolean] whether the provided filter is currently applied/selected
      def include?(item)
        if item.respond_to?(:field) && item.field != key
          return search_state.filter(item.field).selected?(item)
        end

        values.include?(as_url_parameter(item))
      end
    end
  end
end
