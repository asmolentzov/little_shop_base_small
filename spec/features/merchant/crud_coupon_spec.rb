require 'rails_helper' 

describe 'As a merchant on the site' do
  include ActionView::Helpers::NumberHelper

  before(:each) do
    @merchant = create(:merchant)
    visit login_path
    fill_in :email, with: @merchant.email
    fill_in :password, with: @merchant.password
    click_button 'Log in'
  end
  describe 'on my dashboard' do
    it 'I see links to the coupon index and to create a new coupon' do
      visit dashboard_path
      
      expect(page).to have_link("My Coupons")
      click_link("My Coupons")
      expect(current_path).to eq(coupons_path)
      
      visit dashboard_path
      expect(page).to have_link("Create New Coupon: Percentage")
      expect(page).to have_link("Create New Coupon: Dollars")
      click_link("Create New Coupon: Percentage")
      expect(current_path).to eq(new_coupon_path)
      
      visit dashboard_path
      click_link("Create New Coupon: Dollars")
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
        expect(page).to have_content("This coupon has not been used")
      end      
    end

    it 'will not allow me to create a coupon with missing or bad info' do
      visit new_coupon_path
      
      click_button 'Create Coupon'
      
      expect(page).to have_content("Create a New Coupon!")
      expect(page).to have_content("Coupon type can't be blank")
      expect(page).to have_content("Amount can't be blank")
      expect(page).to have_content("Code can't be blank")
      
      coupon = create(:percent_coupon, user: @merchant)
      
      fill_in :coupon_coupon_type, with: 'percentage'
      fill_in :coupon_amount, with: -1
      fill_in :coupon_code, with: coupon.code
      click_button 'Create Coupon'
      
      expect(page).to have_content("Create a New Coupon!")
      expect(page).to have_content("Amount must be greater than or equal to 0")
      expect(page).to have_content("Code has already been taken")
      expect(find_field("coupon[coupon_type]").value).to eq('percentage')
      expect(find_field("coupon[code]").value).to eq(coupon.code)
    end
  end
  
  describe 'on my coupons index page' do
    it 'shows me a list of my coupons' do
      coupon_1 = create(:percent_coupon, user: @merchant)
      coupon_2 = create(:dollar_coupon, user: @merchant, used: true)
      coupon_3 = create(:percent_coupon)
      
      visit coupons_path
      
      within "#coupon-#{coupon_1.id}" do
        expect(page).to have_content(coupon_1.code)
        expect(page).to have_content("#{coupon_1.amount}% discount")
        expect(page).to have_content("This coupon has not been used")
      end  
      
      within "#coupon-#{coupon_2.id}" do
        expect(page).to have_content(coupon_2.code)
        expect(page).to have_content("#{number_to_currency(coupon_2.amount)} discount")
        expect(page).to have_content("USED")
      end  
      expect(page).to_not have_content(coupon_3.code)
    end
    
    it 'allows me to delete an unused coupon' do
      coupon_1 = create(:percent_coupon, user: @merchant, used: true)
      coupon_2 = create(:dollar_coupon, user: @merchant)
      
      visit coupons_path
      
      within "#coupon-#{coupon_1.id}" do
        expect(page).to_not have_link('Delete')
      end
      within "#coupon-#{coupon_2.id}" do
        expect(page).to have_link('Delete')
        click_link('Delete')
      end
      
      expect(current_path).to eq(coupons_path)
      within "#coupons" do  
        expect(page).to_not have_content(coupon_2.code)
        expect(page).to have_content(coupon_1.code)
      end
      expect(page).to have_content("Coupon #{coupon_2.code} was successfully deleted")
    end
    
    it 'allows me to edit an unused coupon' do
      coupon_1 = create(:percent_coupon, user: @merchant, used: true)
      coupon_2 = create(:dollar_coupon, user: @merchant)
      
      visit coupons_path
      
      within "#coupon-#{coupon_1.id}" do
        expect(page).to_not have_link('Edit')
      end
      within "#coupon-#{coupon_2.id}" do
        expect(page).to have_link('Edit')
        click_link('Edit')
      end
      
      expect(current_path).to eq(edit_coupon_path(coupon_2))
      expect(find_field('coupon[coupon_type]').value).to eq('dollars')
      expect(find_field('coupon[amount]').value).to eq(coupon_2.amount.to_s)
      expect(find_field('coupon[cart_minimum]').value).to eq(coupon_2.cart_minimum.to_s)
      expect(find_field('coupon[code]').value).to eq(coupon_2.code)
    end
  end
  
  describe 'on the edit coupon page' do
    it 'allows me to update a coupon' do
      coupon = create(:dollar_coupon, amount: 10, user: @merchant)
      new_amount = 20
      
      visit edit_coupon_path(coupon)
      
      fill_in :coupon_amount, with: new_amount
      click_button('Update Coupon')
      
      expect(current_path).to eq(coupons_path)
      expect(page).to have_content("Coupon #{coupon.code} was successfully updated!")
      within "#coupon-#{coupon.id}" do
        expect(page).to have_content("#{number_to_currency(new_amount)} discount")
      end
    end
    it 'does not allow me update a coupon if info is wrong/missing' do
      coupon = create(:dollar_coupon, amount: 10, user: @merchant)
      coupon_2 = create(:dollar_coupon)
      
      visit edit_coupon_path(coupon)
      
      fill_in :coupon_coupon_type, with: ''
      fill_in :coupon_amount, with: ''
      fill_in :coupon_code, with: ''
      click_button('Update Coupon')
      
      expect(page).to have_content 'Edit Coupon' 
      expect(page).to have_content("Coupon type can't be blank")
      expect(page).to have_content("Amount is not a number")
      expect(page).to have_content("Code can't be blank")
      
      fill_in :coupon_code, with: coupon_2.code
      fill_in :coupon_amount, with: -1
      click_button('Update Coupon')
      
      expect(page).to have_content("Edit Coupon")
      expect(page).to have_content("Amount must be greater than or equal to 0")
      expect(page).to have_content("Code has already been taken")
    end
  end
end

