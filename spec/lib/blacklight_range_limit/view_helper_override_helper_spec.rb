require 'spec_helper'

RSpec.describe BlacklightRangeLimit::ViewHelperOverride, type: :helper do
  describe '#render_constraints_filters' do
    before do
      allow(helper).to receive_messages(
        facet_field_label: 'Date Range',
        search_action_path: '/catalog',
        blacklight_config: CatalogController.blacklight_config,
        search_state: BlacklightRangeLimit::SearchState::Default.new(params, CatalogController.blacklight_config)
      )
      allow(controller).to receive_messages(
        search_state_class: BlacklightRangeLimit::SearchState::Default,
      )
    end

    it 'does not return any content when the range parameter invalid' do
      params = ActionController::Parameters.new(range: 'garbage')

      expect(helper.render_constraints_filters(params)).to eq ''
    end

    it 'renders a constraint for the given data in the range param' do
      params = ActionController::Parameters.new(
        range: { pub_date_si: { 'begin' => 1900, 'end' => 2000 } }
      )
      constraints = helper.render_constraints_filters(params)

      expect(constraints).to have_css(
        '.constraint .filter-name', text: 'Date Range'
      )
      expect(constraints).to have_css(
        '.constraint .filter-value', text: '1900 to 2000'
      )
    end
  end

  describe 'render_search_to_s_filters' do
    before do
      allow(helper).to receive_messages(
        facet_field_label: 'Date Range',
        search_action_path: '/catalog',
        blacklight_config: CatalogController.blacklight_config,
        search_state: BlacklightRangeLimit::SearchState::Default.new(params, CatalogController.blacklight_config)
      )
      allow(controller).to receive_messages(
        search_state_class: BlacklightRangeLimit::SearchState::Default,
      )
    end

    it 'does not return any content when the range parameter invalid' do
      params = ActionController::Parameters.new(range: 'garbage')

      expect(helper.render_search_to_s_filters(params)).to eq ''
    end

    it 'renders a constraint for the given data in the range param' do
      params = ActionController::Parameters.new(
        range: { pub_date_si: { 'begin' => 1900, 'end' => 2000 } }
      )
      constraints = helper.render_search_to_s_filters(params)

      expect(constraints).to have_css(
        '.constraint .filter-name', text: 'Date Range:'
      )
      expect(constraints).to have_css(
        '.constraint .filter-values', text: '1900 to 2000'
      )
    end
  end

  describe '#range_params' do
    it 'handles no range input' do
      expect(
        helper.send(:range_params, ActionController::Parameters.new(q: 'blah'))
      ).to eq({})
    end

    it 'handles non-compliant range input' do
      expect(
        helper.send(:range_params, ActionController::Parameters.new(range: 'blah'))
      ).to eq({})

      expect(
        helper.send(:range_params, ActionController::Parameters.new(range: ['blah']))
      ).to eq({})

      expect(
        helper.send(:range_params, ActionController::Parameters.new(range: { 'wrong' => 'data' }))
      ).to eq({})

      expect(
        helper.send(
          :range_params,
          ActionController::Parameters.new(range: { field_name: { 'wrong' => 'data' } })
        )
      ).to eq({})

      expect(
        helper.send(
          :range_params,
          ActionController::Parameters.new(range: { field_name: { 'begin' => '', 'end' => '' } })
        )
      ).to eq({})
    end

    it 'returns the range parameters that are present' do
      expect(
        helper.send(
          :range_params,
          ActionController::Parameters.new(range: { field_name: { 'missing' => true } })
        ).permit!.to_h
      ).to eq({ 'field_name' => { 'missing' => true } })

      expect(
        helper.send(
          :range_params,
          ActionController::Parameters.new(range: { field_name: { 'begin' => '1800', 'end' => '1900' } })
        ).permit!.to_h
      ).to eq({ 'field_name' => { 'begin' => '1800', 'end' => '1900' } })

      expect(
        helper.send(
          :range_params,
          ActionController::Parameters.new(
            range: {
              field_name: { 'begin' => '1800', 'end' => '1900' },
              field_name2: { 'begin' => '1800', 'end' => '1900' }
            }
          )
        ).permit!.to_h
      ).to eq(
        {
          'field_name' => { 'begin' => '1800', 'end' => '1900' },
          'field_name2' => { 'begin' => '1800', 'end' => '1900' }
        }
      )
    end
    describe '#remove_range_param' do
      let(:params) { ActionController::Parameters.new(q: 'blah', range: range_params) }
      let(:other_range_field) { 'other_date_si' }
      let(:range_field) { 'pub_date_si' }
      let(:range_params) { { range_field => { 'begin' => 1900, 'end' => 2000 } } }
      before do
        allow(controller).to receive_messages(
          search_state_class: BlacklightRangeLimit::SearchState::Default
        )
        allow(helper).to receive_messages(
          blacklight_config: CatalogController.blacklight_config,
          params: params
        )
      end
      it 'removes the specified range param if present' do
        expect(helper.send(:remove_range_param, range_field)).to eql(
          {
            'q' => 'blah'
          }
        )
      end
      it 'does nothing if specified range param if absent' do
        expect(helper.send(:remove_range_param, other_range_field)).to eql(
          params.permit!.to_h
        )
      end
    end
  end
end
