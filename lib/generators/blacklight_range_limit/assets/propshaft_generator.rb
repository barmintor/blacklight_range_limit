# frozen_string_literal: true

module BlacklightRangeLimit
  module Assets
    class PropshaftGenerator < Rails::Generators::Base
      def add_package
        run 'yarn add blacklight-range-limit'
      end

      def add_package_assets
        append_to_file 'app/assets/stylesheets/application.bootstrap.scss' do
          <<~CONTENT
            @import "blacklight-range-limit/app/assets/stylesheets/blacklight_range_limit/blacklight_range_limit";
            @import "blacklight-range-limit/vendor/assets/stylesheets/slider";
          CONTENT
        end

        append_to_file 'app/javascript/application.js' do
          <<~CONTENT
            import BlacklightRangeLimit from "blacklight-range-limit/app/assets/javascripts/blacklight_range_limit/blacklight-range-limit.esm";
          CONTENT
        end
      end
    end
  end
end
