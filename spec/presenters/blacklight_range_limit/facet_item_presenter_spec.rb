# frozen_string_literal: true
require 'spec_helper'

RSpec.describe BlacklightRangeLimit::FacetItemPresenter, type: :presenter do
  subject(:presenter) do
    described_class.new(facet_item, facet_config, view_context, facet_field, search_state)
  end

  let(:facet_item) { ('0'..'199') }
  let(:facet_config) { Blacklight::Configuration::FacetField.new(key: 'key', range: true) }
  let(:facet_field) { instance_double(Blacklight::Solr::Response::Facets::FacetField) }
  let(:filter_field) { instance_double(BlacklightRangeLimit::SearchState::FilterField) }
  let(:view_context) { controller.view_context }
  let(:search_state) { instance_double(BlacklightRangeLimit::SearchState::Default) }

  describe '#selected?' do
    before do
      allow(search_state).to receive(:filter).with(facet_config).and_return(filter_field)
      allow(filter_field).to receive(:include?).with(facet_item).and_return(true)
    end
    it 'works' do
      expect(presenter.selected?).to be true
    end
  end

  describe '#label' do
    it "is the facet value for a range facet" do
      allow(facet_config).to receive_messages(query: nil, date: nil, helper_method: nil, url_method: nil)
      expect(presenter.label).to eq '<span class="from" data-blrl-begin="0">0</span> to <span class="to" data-blrl-end="199">199</span>'
    end
  end

  describe '#href' do
    let(:facet_selected) { false }
    let(:field_key) { 'key' }
    let(:range_params) { { range: { field_key => facet_item } } }
    before do
      allow(search_state).to receive(:filter).with(facet_config).and_return(filter_field)
      allow(search_state).to receive(:filter).with(field_key).and_return(filter_field)
      allow(filter_field).to receive(:include?).with(facet_item).and_return(facet_selected)
      allow(filter_field).to receive(:any?).and_return(facet_selected)
    end

    it 'is the url to apply the facet' do
      allow(filter_field).to receive(:add).and_return(range_params)
      allow(search_state).to receive(:reset_search).with({}).and_return(search_state)
      allow(search_state).to receive(:to_h).and_return({})
      allow(view_context).to receive(:search_action_path).with(range_params).and_return('/catalog?f=x')

      expect(presenter.href).to eq '/catalog?f=x'
    end

    context 'with a selected facet' do
      let(:facet_selected) { true }
      it 'is the url to remove the facet' do
        allow(search_state).to receive(:to_h).and_return(range_params)
        allow(search_state).to receive(:reset_search).with(range_params).and_return(search_state)
        allow(filter_field).to receive(:remove).with(facet_item).and_return({})
        allow(view_context).to receive(:search_action_path).with({}).and_return('/catalog')

        expect(presenter.href).to eq '/catalog'
      end
    end
  end
end
