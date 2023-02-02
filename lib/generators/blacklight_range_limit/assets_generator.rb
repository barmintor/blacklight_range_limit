# frozen_string_literal: true

module BlacklightRangeLimit
  class AssetsGenerator < Rails::Generators::Base
    class_option :'bootstrap-version', type: :string, default: ENV.fetch('BOOTSTRAP_VERSION', '~> 5.1'), desc: "Set the generated app's bootstrap version"

    def run_asset_pipeline_specific_generator
      generated_options = "--bootstrap-version='#{options[:'bootstrap-version']}'" if options[:'bootstrap-version']

      generator = if defined?(Propshaft)
                    say_status("warning", "GENERATING PROPSHAFT ASSETS", :yellow)
                    'blacklight_range_limit:assets:propshaft'
                  elsif defined?(Importmap)
                    say_status("warning", "GENERATING IMPORTMAP ASSETS", :yellow)
                    'blacklight_range_limit:assets:importmap'
                  elsif defined?(Sprockets)
                    say_status("warning", "GENERATING SPROCKETS ASSETS", :yellow)
                    'blacklight_range_limit:assets:sprockets'
                  else
                    say_status("warning", "NO ASSET BUNDLER DETECTED!", :red)
                  end

      generate generator, generated_options if generator
    end
  end
end
