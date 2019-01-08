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
      expect(page).to have_content("Coupon #{@coupon.code} discount: #{@coupon.amount}% for items from merchant: #{@coupon.user.name}")
      expect(page).to have_content("Grand Total: #{number_to_currency(new_total)}")
      
      within("#item-#{@item.id}") do
        expect(page).to have_content("Discounted Subtotal: #{number_to_currency(@item.discounted_price(@coupon))}")
      end
    end
  end
  
  describe 'I can apply a dollars coupon code with a cart minimum on my cart page' do
    before(:each) do
      @merchant = create(:merchant)
      @item = create(:item, price: 10, user: @merchant)
      @item_2 = create(:item, price: 25)
      @coupon = create(:dollar_coupon, cart_minimum: 20, user: @merchant)
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
      
      visit item_path(@item_2)
      click_button "Add to Cart"
      
      visit cart_path
      
      expect(page).to have_content("Add Coupon")
      fill_in :coupon_code, with: @coupon.code
      click_button "Apply Coupon"
      
      expect(current_path).to eq(cart_path)
      expect(page).to have_content("Coupon #{@coupon.code} was successfully applied!")
      
      total = @item.price + @item_2.price
      
      expect(page).to have_content("Subtotal: #{number_to_currency(total)}")
      expect(page).to have_content("Coupon #{@coupon.code} discount: #{number_to_currency(@coupon.amount)}  from merchant #{@coupon.user.name}")
      expect(page).to have_content("#{number_to_currency(@coupon.cart_minimum)} cart minimum amount")
      expect(page).to have_content("Cart Minimum for merchant #{@merchant.name} is NOT MET")
      expect(page).to have_content("Grand Total: #{number_to_currency(total)}")
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
      @item = create(:item, user: @merchant, price: 10)
      @item_2 = create(:item, user: @merchant)
      @item_3 = create(:item)
      @coupon = create(:dollar_coupon, user: @merchant, amount: 10)
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
      
      expect(page).to have_content("Subtotal: #{number_to_currency(@item.price + @item_2.price + @item_3.price)}")
      within "#coupon" do
        expect(page).to have_content("Coupon #{@coupon.code} discount: #{number_to_currency(@coupon.amount)} from merchant #{@coupon.user.name}")
      end
      
      discount_total = @item.price + @item_2.price + @item_3.price - @coupon.amount
      
      expect(page).to have_content("Grand Total: #{number_to_currency(discount_total)}")
    end
  end
  
  describe 'A coupon code is validated at checkout' do
    before(:each) do
      @merchant = create(:merchant)
      @item = create(:item, user: @merchant)
      @coupon = create(:percent_coupon, user: @merchant)
    end
    scenario 'as a visitor who logs in' do
      visit item_path(@item)
      click_button "Add to Cart"
      
      visit cart_path
      
      fill_in :coupon_code, with: @coupon.code
      click_button "Apply Coupon"
      
      customer = create(:user)
      visit login_path
      fill_in :email, with: customer.email
      fill_in :password, with: customer.password
      click_button 'Log in' 
      
      visit cart_path
    end
    scenario 'as a registered user' do
      customer = create(:user)
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(customer)
      
      visit item_path(@item)
      click_button "Add to Cart"
      
      visit cart_path
      
      fill_in :coupon_code, with: @coupon.code
      click_button "Apply Coupon"
    end
    
    after(:each) do
      # Coupon is used by someone else
      @coupon.update(used: true)
      
      click_button('Check out')
      
      expect(page).to have_content("Coupon #{@coupon.code} is no longer valid. Please remove coupon.")
      expect(current_path).to eq(cart_path)
    end
  end
  
  describe 'A coupon code is used after the customer checks out' do
    before(:each) do
      @merchant = create(:merchant)
      @item = create(:item, user: @merchant)
      @coupon = create(:percent_coupon, user: @merchant)
    end
    scenario 'as a visitor who logs in' do
      visit item_path(@item)
      click_button "Add to Cart"
      
      visit cart_path
      
      fill_in :coupon_code, with: @coupon.code
      click_button "Apply Coupon"
      
      customer = create(:user)
      visit login_path
      fill_in :email, with: customer.email
      fill_in :password, with: customer.password
      click_button 'Log in' 
      
      visit cart_path
    end
    scenario 'as a registered user' do
      customer = create(:user)
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(customer)
      
      visit item_path(@item)
      click_button "Add to Cart"
      
      visit cart_path
      
      fill_in :coupon_code, with: @coupon.code
      click_button "Apply Coupon"
    end
    
    after(:each) do
      click_button 'Check out' 
      
      expect(current_path).to eq(profile_path)
      click_link 'My Orders'
      
      order = Order.last
      within "#order-#{order.id}" do
        expect(page).to have_content(@coupon.code)
      end
      expect(Coupon.find(@coupon.id).used).to eq(true)
      
      visit item_path(@item)
      click_button "Add to Cart"
      
      visit cart_path
      fill_in :coupon_code, with: @coupon.code
      click_button 'Apply Coupon' 
      
      expect(page).to have_content("Coupon #{@coupon.code} is not a valid coupon")
    end
  end
end