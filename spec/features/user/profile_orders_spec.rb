require 'rails_helper'

include ActionView::Helpers::NumberHelper

RSpec.describe 'Profile Orders page', type: :feature do
  before :each do
    @user = create(:user)
    @admin = create(:admin)

    @merchant_1 = create(:merchant)
    @merchant_2 = create(:merchant)

    @item_1 = create(:item, user: @merchant_1)
    @item_2 = create(:item, user: @merchant_2)
  end
  context 'as a registered user' do
    describe 'should show a message when user no orders' do
      scenario 'when logged in as user' do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(@user)
        visit profile_orders_path
      end
      scenario 'when logged in as admin' do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(@admin)
        visit admin_user_orders_path(@user)
      end
      after :each do
        expect(page).to have_content('You have no orders yet')
      end
    end

    describe 'should show information about each order when I do have orders' do
      before :each do
        yesterday = 1.day.ago
        @order = create(:order, user: @user, created_at: yesterday)
        @oi_1 = create(:order_item, order: @order, item: @item_1, price: 1, quantity: 1, created_at: yesterday, updated_at: yesterday)
        @oi_2 = create(:fulfilled_order_item, order: @order, item: @item_2, price: 2, quantity: 1, created_at: yesterday, updated_at: 2.hours.ago)
      end
      scenario 'when logged in as user' do
        @user.reload
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(@user)
        visit profile_orders_path
      end
      scenario 'when logged in as admin' do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(@admin)
        visit admin_user_orders_path(@user)
      end
      after :each do
        expect(page).to_not have_content('You have no orders yet')

        within "#order-#{@order.id}" do
          expect(page).to have_link("Order ID #{@order.id}")
          expect(page).to have_content("Created: #{@order.created_at}")
          expect(page).to have_content("Last Update: #{@order.last_update}")
          expect(page).to have_content("Status: #{@order.status}")
          expect(page).to have_content("Item Count: #{@order.total_item_count}")
          expect(page).to have_content("Total Cost: #{number_to_currency(@order.total_cost)}")
        end
      end
    end
    describe 'should show a single order show page' do
      before :each do
        yesterday = 1.day.ago
        @order = create(:order, user: @user, created_at: yesterday)
        @oi_1 = create(:order_item, order: @order, item: @item_1, price: 1, quantity: 3, created_at: yesterday, updated_at: yesterday)
        @oi_2 = create(:fulfilled_order_item, order: @order, item: @item_2, price: 2, quantity: 5, created_at: yesterday, updated_at: 2.hours.ago)
      end
      scenario 'when logged in as user' do
        @user.reload
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(@user)
        visit profile_order_path(@order)
      end
      scenario 'when logged in as admin' do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(@admin)
        visit admin_user_order_path(@user, @order)
      end
      after :each do
        expect(page).to have_content("Order ID #{@order.id}")
        expect(page).to have_content("Created: #{@order.created_at}")
        expect(page).to have_content("Last Update: #{@order.last_update}")
        expect(page).to have_content("Status: #{@order.status}")
        within "#oitem-#{@oi_1.id}" do
          expect(page).to have_content(@oi_1.item.name)
          expect(page).to have_content(@oi_1.item.description)
          expect(page.find("#item-#{@oi_1.item.id}-image")['src']).to have_content(@oi_1.item.image)
          expect(page).to have_content("Merchant: #{@oi_1.item.user.name}")
          expect(page).to have_content("Price: #{number_to_currency(@oi_1.price)}")
          expect(page).to have_content("Quantity: #{@oi_1.quantity}")
          expect(page).to have_content("Subtotal: #{number_to_currency(@oi_1.price*@oi_1.quantity)}")
          expect(page).to have_content("Subtotal: #{number_to_currency(@oi_1.price*@oi_1.quantity)}")
          expect(page).to have_content("Fulfilled: No")
        end
        within "#oitem-#{@oi_2.id}" do
          expect(page).to have_content(@oi_2.item.name)
          expect(page).to have_content(@oi_2.item.description)
          expect(page.find("#item-#{@oi_2.item.id}-image")['src']).to have_content(@oi_2.item.image)
          expect(page).to have_content("Merchant: #{@oi_2.item.user.name}")
          expect(page).to have_content("Price: #{number_to_currency(@oi_2.price)}")
          expect(page).to have_content("Quantity: #{@oi_2.quantity}")
          expect(page).to have_content("Subtotal: #{number_to_currency(@oi_2.price*@oi_2.quantity)}")
          expect(page).to have_content("Fulfilled: Yes")
        end
        expect(page).to have_content("Item Count: #{@order.total_item_count}")
        expect(page).to have_content("Total Cost: #{number_to_currency(@order.total_cost)}")
      end
    end
    describe 'allows me to cancel an order that is not yet complete' do
      before :each do
        @item = create(:item, user: @merchant_1, inventory: 100)

        @order_1 = create(:completed_order, user: @user)
        @oi_1 = create(:fulfilled_order_item, order: @order_1, item: @item, price: 1, quantity: 25)

        @order_2 = create(:order, user: @user)
        @oi_2 = create(:order_item, order: @order_2, item: @item, price: 1, quantity: 25)

        @order_3 = create(:order, user: @user)
        @oi_3 = create(:order_item, order: @order_3, item: @item, price: 1, quantity: 25)
        @oi_4 = create(:fulfilled_order_item, order: @order_3, item: @item, price: 1, quantity: 25)
      end
      scenario 'when logged in as user' do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(@user)
        @am_admin = false
        visit profile_order_path(@order_1)
      end
      scenario 'when logged in as admin' do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(@admin)
        @am_admin = true
        visit admin_user_order_path(@user, @order_1)
      end
      after :each do

        ## confirm order 1 is complete and cannot be cancelled
        expect(page).to have_content("Status: completed")
        expect(page).to_not have_button('Cancel Order')

        within "#oitem-#{@oi_1.id}" do
          expect(page).to have_content("Fulfilled: Yes")
        end

        visit item_path(@item)
        expect(page).to have_content("In stock: 100")


        ## confirm order 2 can be cancelled and inventory is not refunded to merchant since it wasn't fulfilled yet
        visit @am_admin ? admin_user_order_path(@user, @order_2) : profile_order_path(@order_2)

        within "#oitem-#{@oi_2.id}" do
          expect(page).to have_content("Fulfilled: No")
        end
        expect(page).to have_content("Status: pending")
        expect(page).to have_button('Cancel Order')
        click_button('Cancel Order')

        if @am_admin
          expect(current_path).to eq(admin_user_order_path(@user, @order_2))
        else
          expect(current_path).to eq(profile_order_path(@order_2))
        end
        expect(page).to have_content("Status: cancelled")

        visit item_path(@item)
        expect(page).to have_content("In stock: 100")


        ## confirm order 3 can be cancelled, but since one item wasn't fulfilled only one item should be refunded
        visit @am_admin ? admin_user_order_path(@user, @order_3) : profile_order_path(@order_3)
        within "#oitem-#{@oi_3.id}" do
          expect(page).to have_content("Fulfilled: No")
        end
        within "#oitem-#{@oi_4.id}" do
          expect(page).to have_content("Fulfilled: Yes")
        end
        expect(page).to have_content("Status: pending")
        expect(page).to have_button('Cancel Order')
        click_button('Cancel Order')

        if @am_admin
          expect(current_path).to eq(admin_user_order_path(@user, @order_3))
        else
          expect(current_path).to eq(profile_order_path(@order_3))
        end
        expect(page).to have_content("Status: cancelled")
        within "#oitem-#{@oi_3.id}" do
          expect(page).to have_content("Fulfilled: No")
        end
        within "#oitem-#{@oi_4.id}" do
          expect(page).to have_content("Fulfilled: No")
        end

        visit item_path(@item)
        expect(page).to have_content("In stock: 125")
      end
    end
  end
  
  describe 'should show information about coupons if applied to orders on orders page' do
    before :each do
      yesterday = 1.day.ago
      @order = create(:order, user: @user, created_at: yesterday)
      @order_2 = create(:order, user: @user)
      @order_3 = create(:order, user: @user)
      @coupon_1 = create(:dollar_coupon)
      @coupon_2 = create(:percent_coupon)
      @oi_1 = create(:order_item, order: @order, item: @item_1, price: 1, quantity: 1, created_at: yesterday, updated_at: yesterday)
      @oi_2 = create(:fulfilled_order_item, order: @order, item: @item_2, price: 2, quantity: 1, created_at: yesterday, updated_at: 2.hours.ago)
      
      create(:coupon_order_item, order: @order_2, coupon: @coupon_1)
      create(:coupon_order_item, order: @order_3, coupon: @coupon_2)
    end
    scenario 'when logged in as user' do
      @user.reload
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(@user)
      visit profile_orders_path
    end
    scenario 'when logged in as admin' do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(@admin)
      visit admin_user_orders_path(@user)
    end
    after :each do
      expect(page).to_not have_content('You have no orders yet')

      within "#order-#{@order.id}" do
        expect(page).to_not have_content('Coupon')
        expect(page).to have_content("Item Count: #{@order.total_item_count}")
        expect(page).to have_content("Total Cost: #{number_to_currency(@order.total_cost)}")
      end
      
      within "#order-#{@order_2.id}" do
        expect(page).to have_content("Coupon applied: #{@coupon_1.code} for merchant: #{@coupon_1.user.name}")
        expect(page).to have_content("Discount: #{number_to_currency(@coupon_1.amount)} from merchant #{@coupon_1.user.name}")
        expect(page).to have_content("#{number_to_currency(@coupon_1.cart_minimum)} cart minimum amount")
        expect(page).to have_content("Item Count: #{@order_2.total_item_count}")
        expect(page).to have_content("Total Cost: #{number_to_currency(@order_2.total_cost)}")
      end
      
      within "#order-#{@order_3.id}" do
        expect(page).to have_content("Coupon applied: #{@coupon_2.code} for merchant: #{@coupon_2.user.name}")
        expect(page).to have_content("Discount: #{@coupon_2.amount}% for items from merchant #{@coupon_2.user.name}")
        expect(page).to have_content("Item Count: #{@order_3.total_item_count}")
        expect(page).to have_content("Total Cost: #{number_to_currency(@order_3.total_cost)}")
      end
    end
  end
  
  describe 'should show information about coupon if applied on order show page' do
    before :each do
      yesterday = 1.day.ago
      @order = create(:order, user: @user, created_at: yesterday)
      @coupon = create(:percent_coupon)
      @oi_1 = create(:order_item, order: @order, item: @item_1, price: 1, quantity: 1, created_at: yesterday, updated_at: yesterday)
      @oi_2 = create(:fulfilled_order_item, order: @order, item: @item_2, price: 2, quantity: 1, created_at: yesterday, updated_at: 2.hours.ago)
      
      @oi_3 = create(:coupon_order_item, order: @order, coupon: @coupon)
    end
    scenario 'when logged in as user' do
      @user.reload
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(@user)
      visit profile_order_path(@order)
    end
    scenario 'when logged in as admin' do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(@admin)
      visit admin_user_order_path(@user, @order)
    end
    after :each do
      expect(page).to have_content("Coupon applied: #{@coupon.code} for merchant: #{@coupon.user.name}")
      expect(page).to have_content("Discount: #{@coupon.amount}%")
      expect(page).to have_content("Item Count: #{@order.total_item_count}")
      expect(page).to have_content("Total Cost: #{number_to_currency(@order.total_cost)}")

      within "#oitem-#{@oi_3.id}" do
        expect(page).to have_content("Discount: #{@coupon.amount}%")
        expect(page).to have_content("Discounted Subtotal: #{number_to_currency(@oi_3.discounted_subtotal(@coupon))}")
      end
      within "#oitem-#{@oi_1.id}" do
        expect(page).to_not have_content("Discount")
      end
      within "#oitem-#{@oi_2.id}" do
        expect(page).to_not have_content("Discount")
      end
    end
  end
end