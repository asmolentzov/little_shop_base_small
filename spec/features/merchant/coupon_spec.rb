require 'rails_helper' 

describe 'As a merchant on the site' do
  before(:each) do
    @merchant = create(:merchant)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(@merchant)
  end
  describe 'on my dashboard' do
    it 'I see a link to create a new coupon' do
      visit dashboard_path
      
      expect(page).to have_link("Create New Coupon")
      click_link("Create New Coupon")
      expect(current_path).to eq(new_coupon_path)
    end
  end
end