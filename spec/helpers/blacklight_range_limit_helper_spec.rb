require "spec_helper"

describe "Blacklight Range Limit Helper" do

  it "should render range text fields with/without labels" do
    begin_html = Capybara.string(helper.render_range_input('pub_date', 'begin'))
    begin_from_pub_html = Capybara.string(helper.render_range_input('pub_date', 'begin', 'from pub date'))
    expect(begin_html).to have_css 'input.form-control.range_begin#range_pub_date_begin'
    expect(begin_from_pub_html).to have_css 'label.sr-only[for="range_pub_date_begin"]'
  end

  it "should render range text fields with specified maxlength, defaulting to 4 if not specified" do
    html_maxlength_default = Capybara.string(helper.render_range_input('pub_date', 'begin'))
    html_maxlength_6 = Capybara.string(helper.render_range_input('pub_date', 'begin', nil, 6))
    expect(html_maxlength_default).to have_css 'input.form-control.range_begin#range_pub_date_begin[maxlength="4"]'
    expect(html_maxlength_6).to have_css 'input.form-control.range_begin#range_pub_date_begin[maxlength="6"]'
  end

  context "when building requests" do
    let(:config) {
      Blacklight::Configuration.new.tap do |config|
        config.add_facet_field field_key, range: true
        config.default_solr_params[:'facet.field'] = config.facet_fields.keys
      end
     }
    let(:params) { { q: '', page: '2' } }
    let(:search_state) { Blacklight::SearchState.new(params, config, controller) }
    let(:field_key) { 'test_si' }

    before do
      allow(helper).to receive(:blacklight_config).and_return(config)
      allow(helper).to receive_messages(search_state: search_state)
    end

    it "should exclude page when adding a range" do
      updated_params = helper.add_range(field_key, '1900', '1995', params)
      expect(updated_params).not_to include(:page)
    end

    it "should exclude page when adding a missing range" do
      updated_params = helper.add_range_missing(field_key, params)
      expect(updated_params).not_to include(:page)
    end
  end
end
