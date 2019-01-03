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
  
  describe 'on the coupon creation form' do
    it 'shows me a form and allows me to create a new coupon' do
      visit new_coupon_path
      
      code = 'NEWYEAR2019'
      amount = 10
      fill_in :coupon_coupon_type, with: 'percentage'
      fill_in :coupon_amount, with: amount
      fill_in :coupon_cart_minimum, with: 0
      fill_in :coupon_code, with: code
      click_button 'Create Coupon'
      
      expect(current_path).to eq(coupons_path)
      coupon = Coupon.last
      expect(coupon.code).to eq(code)
      expect(page).to have_content("Coupon #{code} was successfully created!")
      
      within "#coupon-#{coupon.id}" do
        expect(page).to have_content(code)
        expect(page).to have_content("#{amount}% discount")
        expect(page).to have_content("No cart minimum amount")
        expect(page).to have_content("This coupon has not been used")
      end
    end
  end
end

