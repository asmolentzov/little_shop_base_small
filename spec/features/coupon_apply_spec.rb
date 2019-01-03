require 'rails_helper' 

describe 'Coupon apply workflow' do
  include ActionView::Helpers::NumberHelper
  
  describe 'I see a field to apply a coupon code on my cart page' do
    before(:each) do
      @merchant = create(:merchant)
      @item = create(:item, user: @merchant)
      @coupon = create(:percent_coupon, user: @merchant)
    end
    scenario 'as a visitor' do
      visit item_path(@item)
    end
    scenario 'as a registered user' do
      customer = create(:user)
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(customer)
      
      visit item_path(@item)
    end
    
    after(:each) do
      click_button "Add to Cart"
      
      visit cart_path
      
      expect(page).to have_content("Add Coupon")
      fill_in :coupon_code, with: @coupon.code
      click_button "Apply Coupon"
      
      expect(current_path).to eq(cart_path)
      expect(page).to have_content("Coupon #{@coupon.code} was successfully applied!")
      new_total = @item.price - ((@coupon.amount / 100.0) * @item.price)
      
      expect(page).to have_content("Subtotal: #{number_to_currency(@item.price)}")
      expect(page).to have_content("Coupon #{@coupon.code} discount: #{@coupon.amount}%")
      expect(page).to have_content("Grand Total: #{number_to_currency(new_total)}")
      
    end
  end
end