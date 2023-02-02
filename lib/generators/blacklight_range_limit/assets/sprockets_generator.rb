# frozen_string_literal: true

module BlacklightRangeLimit
  module Assets
    class SprocketsGenerator < Rails::Generators::Base
      ##
      # Remove the empty generated app/assets/images directory. Without doing this,
      # the default Sprockets 4 manifest will raise an exception.
      def appease_sprockets4
        return if Rails.version > '7' || Sprockets::VERSION < '4'

        append_to_file 'app/assets/config/manifest.js', "\n//= link application.js"
        empty_directory 'app/assets/images'
      end

      def assets
        application_css = Dir["app/assets/stylesheets/application{.css,.scss,.css.scss}"].first

        if application_css

          insert_into_file application_css, :before => "*/" do
%q{
 *
 * Used by blacklight_range_limit
 *= require  'blacklight_range_limit'
 *
}
          end
        else
          say_status "warning", "Can not find application.css, did not insert our require", :red
        end

        append_to_file "app/assets/javascripts/application.js" do
%q{

// For blacklight_range_limit built-in JS, if you don't want it you don't need
// this:
//= require 'blacklight_range_limit'

}
        end
      end
    end
  end
end
