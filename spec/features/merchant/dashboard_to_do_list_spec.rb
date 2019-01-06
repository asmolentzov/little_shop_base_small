require 'rails_helper'

describe 'As a merchant on the site' do  
  include ActionView::Helpers::NumberHelper
  
  context 'To Do List' do
    before(:each) do
      @merchant = create(:merchant)
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(@merchant)
    end
    it 'should show me a to do list' do
      visit dashboard_path
      
      expect(page).to have_content("To Do List")
      within "#to-do" do
        expect(page).to have_content("Items Using Placeholder Images")
        expect(page).to have_content("Unfulfilled Orders")
      end
    end
    
    it 'should show me all items that are using placeholder images' do      
      item_1 = create(:item, user: @merchant, image: 'https://picsum.photos/200/300/?image=524')
      item_2 = create(:item, user: @merchant)
      item_3 = create(:item, user: @merchant, image: 'https://picsum.photos/200/300/?image=524')
      
      visit dashboard_path
      
      within "#to-do-images" do
        expect(page).to have_link(item_1.name)
        expect(page).to have_link(item_3.name)
        expect(page).to_not have_content(item_2.name)
      end
    end
    
    it 'should let me update items with placeholder images' do
      item_1 = create(:item, user: @merchant, image: 'https://picsum.photos/200/300/?image=524')
      item_2 = create(:item, user: @merchant)
      item_3 = create(:item, user: @merchant, image: 'https://picsum.photos/200/300/?image=524')
      
      visit dashboard_path
      
      within "#to-do-images" do
        click_link(item_1.name)
      end
      expect(current_path).to eq(edit_dashboard_item_path(item_1))
      fill_in :item_image, with: 'https://picsum.photos/200/300/?image=5'
      click_button 'Update Item'
      
      expect(current_path).to eq(dashboard_items_path)
      click_link('Dashboard')
      
      within "#to-do-images" do
        expect(page).to have_link(item_3.name)
        expect(page).to_not have_link(item_1.name)
        expect(page).to_not have_link(item_2.name)
      end
    end
    
    it 'should show me information about my unfulfilled orders' do
      item_1 = create(:item, user: @merchant)
      item_2 = create(:item, user: @merchant)
      item_3 = create(:item, user: @merchant)
      
      order_1 = create(:order)
      order_2 = create(:order)
      order_3 = create(:order)
      order_4 = create(:completed_order)
      order_5 = create(:cancelled_order)
      
      # Standard unfulfilled order 
      oi_1 = create(:order_item, item: item_1, order: order_1)
      
      visit dashboard_path
      
      within "#to-do" do
        expect(page).to have_content("You have 1 unfulfilled order, worth #{number_to_currency(oi_1.price * oi_1.quantity)}")
      end
      
      # Order with one item fulfilled and one unfulfilled
      oi_2 = create(:order_item, item: item_2, order: order_2)
      create(:fulfilled_order_item, item: item_1, order: order_2)
      
      # Order where merchant's only item is fulfilled (but order is not completed)
      create(:fulfilled_order_item, item: item_3, order: order_3)
      
      # Completed order with fulfilled order_item
      create(:fulfilled_order_item, item: item_3, order: order_4)
      
      # Cancelled order with unfulfilled order_item
      create(:order_item, item: item_3, order: order_5)
      
      visit dashboard_path
      
      unfulfilled_orders = 2
      unfulfilled_orders_revenue = (oi_1.price * oi_1.quantity) + (oi_2.price * oi_2.quantity)
      
      within "#to-do" do
        expect(page).to have_content("You have #{unfulfilled_orders} unfulfilled orders, worth #{number_to_currency(unfulfilled_orders_revenue)}.")
      end
    end
    
    it 'should show me a list of items never ordered' do
      item_1 = create(:item, user: @merchant)
      item_2 = create(:item, user: @merchant)
      item_3 = create(:item, user: @merchant)
      
      create(:order_item, item: item_2)
      
      visit dashboard_path
      
      within "#to-do-unordered-items" do
        expect(page).to have_content("The following items have never been ordered. Consider promoting them!")
        expect(page).to have_content(item_1.name)
        expect(page).to have_content(item_3.name)
        expect(page).to_not have_content(item_2.name)
        click_link(item_1.name)
      end
      
      expect(current_path).to eq(dashboard_items_path)
    end
  end
end
