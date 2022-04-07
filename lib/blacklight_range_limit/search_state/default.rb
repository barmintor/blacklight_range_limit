# frozen_string_literal: true

module BlacklightRangeLimit
  module SearchState
    class Default < ::Blacklight::SearchState
      include BlacklightRangeLimit::SearchState
    end
  end
end
