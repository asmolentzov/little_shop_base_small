require 'rails_helper' 

describe 'Coupon apply workflow' do
  include ActionView::Helpers::NumberHelper
  
  describe 'I can apply a coupon code on my cart page' do
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
  
  describe 'I can only apply one coupon code' do
    before(:each) do
      @merchant = create(:merchant)
      @item = create(:item, user: @merchant)
      @coupon = create(:percent_coupon, user: @merchant)
      @coupon_2 = create(:dollar_coupon, user: @merchant)
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
      
      fill_in :coupon_code, with: @coupon.code
      click_button "Apply Coupon"
      
      expect(current_path).to eq(cart_path)
      expect(page).to have_content("Coupon #{@coupon.code} was successfully applied!")
      
      expect(page).to_not have_content("Add Coupon")
      expect(page).to_not have_button("Apply Coupon")
    end
  end
  
  describe 'I can remove a coupon code then apply a new one' do
    before(:each) do
      @merchant = create(:merchant)
      @item = create(:item, user: @merchant)
      @coupon = create(:percent_coupon, user: @merchant)
      @coupon_2 = create(:dollar_coupon, user: @merchant)
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
      
      fill_in :coupon_code, with: @coupon.code
      click_button "Apply Coupon"
      
      expect(current_path).to eq(cart_path)
      expect(page).to have_content("Coupon #{@coupon.code} was successfully applied!")
      
      expect(page).to_not have_content("Add Coupon")
      expect(page).to_not have_button("Apply Coupon")
      
      expect(page).to have_button('Remove Coupon')
      click_button('Remove Coupon')
      
      expect(current_path).to eq(cart_path)
      expect(page).to have_content("Coupon #{@coupon.code} was successfully removed")
      within "#coupon" do  
        expect(page).to_not have_content(@coupon.code)
        expect(page).to have_content('Add Coupon')
        expect(page).to_not have_button('Remove Coupon')
      end
      
      fill_in :coupon_code, with: @coupon_2.code
      click_button 'Apply Coupon'
      
      expect(current_path).to eq(cart_path)
      expect(page).to have_content("Coupon #{@coupon_2.code} was successfully applied!")
    end
  end
  
  describe 'I cannot apply an invalid coupon code' do
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
      
      wrong_code = 'WRONG'
      fill_in :coupon_code, with: wrong_code
      click_button "Apply Coupon"
      
      expect(current_path).to eq(cart_path)
      expect(page).to have_content("Coupon #{wrong_code} is not a valid coupon")
      
      expect(page).to have_content('Add Coupon')
      expect(page).to have_content("Grand Total: #{number_to_currency(@item.price)}")
    end
  end
  
  describe 'I can continue shopping and the cart reflects the updates' do
    before(:each) do
      @merchant = create(:merchant)
      @item = create(:item, user: @merchant)
      @item_2 = create(:item, user: @merchant)
      @item_3 = create(:item)
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
      
      fill_in :coupon_code, with: @coupon.code
      click_button "Apply Coupon"
      
      expect(current_path).to eq(cart_path)
      expect(page).to have_content("Coupon #{@coupon.code} was successfully applied!")
      
      visit item_path(@item_2)
      click_button "Add to Cart"
      visit item_path(@item_3)
      click_button "Add to Cart"
      
      visit cart_path
      
      expect(page).to have_content(@coupon.code)
      expect(page).to_not have_content('Add Coupon')
      
      within "#coupon" do
        expect(page).to have_content("Subtotal: #{number_to_currency(@item.price + @item_2.price + @item_3.price)}")
        expect(page).to have_content("Coupon #{@coupon.code} discount: #{@coupon.amount}%")
      end
      discount_total = @item.price + @item_2.price + @item_3.price - ((@item.price + @item_2.price) * (@coupon.amount / 100.0))
      expect(page).to have_content("Grand Total: #{number_to_currency(discount_total)}")
    end
  end
end