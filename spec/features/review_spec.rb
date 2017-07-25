require 'features_helper'

describe 'review ' do
  before(:each) do
    start_new_dataset!
  end

  describe 'publication date' do
    DATE_FORMAT = '%B %e, %Y'.freeze

    before(:each) do
      navigate_to_review!
    end

    it 'defaults to today' do
      today_str = Date.today.strftime(DATE_FORMAT)
      expect(page).to have_content("Publication date: #{today_str}")
    end

    it 'reflects the embargo date, if any' do
      future_button = find_by_id('future_button')
      future_button.click

      end_date = Date.today + 3.months
      fill_in_future_pub_date(end_date)

      navigate_to_metadata!
      navigate_to_review!

      end_date_str = end_date.strftime(DATE_FORMAT)
      expect(page).to have_content("Publication date: #{end_date_str}")
    end
  end

  describe 'without required fields' do
    before(:each) do
      navigate_to_review!
    end

    it 'disables submit' do
      submit = find_button('submit_dataset', disabled: :all)
      expect(submit).not_to be_nil
      expect(submit).to be_disabled
    end
  end

  describe 'with required fields' do
    before(:each) do
      fill_required_fields!
      navigate_to_review!
      find_by_id('agree_to_license').click
    end

    it 'allows submit' do
      submit = find_button('submit_dataset', disabled: :all)
      expect(submit).not_to be_nil
      expect(submit).not_to be_disabled
    end
  end
end
