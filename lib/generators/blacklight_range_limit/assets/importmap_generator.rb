# frozen_string_literal: true

module BlacklightRangeLimit
  module Assets
    class ImportmapGenerator < Rails::Generators::Base
      class_option :'bootstrap-version', type: :string, default: ENV.fetch('BOOTSTRAP_VERSION', '~> 5.1'), desc: "Set the generated app's bootstrap version"

      def import_javascript_assets
        append_to_file 'config/importmap.rb' do
          <<~CONTENT
            pin "blacklight_range_limit", to: "blacklight_range_limit/blacklight_range_limit.js"
          CONTENT
        end
      end

      def append_range_limit_javascript
        append_to_file 'app/javascript/application.js' do
          <<~CONTENT
            import "blacklight_range_limit"
          CONTENT
        end
      end

      def add_stylesheet
        gem "sassc-rails", "~> 2.1" if Rails.version > '7'

        create_file 'app/assets/stylesheets/blacklight.scss' do
          <<~CONTENT
            @import 'blacklight_range_limit';
          CONTENT
        end
      end

      def bootstrap_4?
        options[:'bootstrap-version'].match?(/\A[^0-9]*4\./)
      end
    end
  end
end
