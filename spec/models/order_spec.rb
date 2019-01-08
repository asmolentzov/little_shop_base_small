require 'rails_helper'

RSpec.describe Order, type: :model do
  describe 'validations' do
    it { should validate_presence_of :status }
  end

  describe 'relationships' do
    it { should belong_to :user }
    it { should have_many :order_items }
    it { should have_many(:items).through(:order_items) }
  end

  describe 'class methods' do
    describe 'merchant stats' do
      before :each do
        @user_1 = create(:user, city: 'Denver', state: 'CO')
        @user_2 = create(:user, city: 'NYC', state: 'NY')
        @user_3 = create(:user, city: 'Seattle', state: 'WA')
        @user_4 = create(:user, city: 'Seattle', state: 'CO')

        @merchant_1 = create(:merchant, name: 'Merchant Name 1')
        @merchant_2 = create(:merchant, name: 'Merchant Name 2')
        @merchant_3 = create(:merchant, name: 'Merchant Name 3')

        @item_1 = create(:item, user: @merchant_1)
        @item_2 = create(:item, user: @merchant_2)
        @item_3 = create(:item, user: @merchant_3)

        @order_1 = create(:completed_order, user: @user_1)
        @oi_1 = create(:fulfilled_order_item, item: @item_1, order: @order_1, quantity: 100, price: 100, created_at: 10.minutes.ago, updated_at: 9.minute.ago)

        @order_2 = create(:completed_order, user: @user_2)
        @oi_2 = create(:fulfilled_order_item, item: @item_2, order: @order_2, quantity: 300, price: 300, created_at: 2.days.ago, updated_at: 1.minute.ago)

        @order_3 = create(:completed_order, user: @user_3)
        @oi_3 = create(:fulfilled_order_item, item: @item_3, order: @order_3, quantity: 200, price: 200, created_at: 10.minutes.ago, updated_at: 5.minute.ago)

        @order_4 = create(:completed_order, user: @user_4)
        @oi_4 = create(:fulfilled_order_item, item: @item_3, order: @order_4, quantity: 201, price: 200, created_at: 10.minutes.ago, updated_at: 5.minute.ago)
      end
      it '.top_3_states' do
        expect(Order.top_3_states[0].state).to eq('CO')
        expect(Order.top_3_states[0].order_count).to eq(2)
        expect(Order.top_3_states[1].state).to eq('NY')
        expect(Order.top_3_states[1].order_count).to eq(1)
        expect(Order.top_3_states[2].state).to eq('WA')
        expect(Order.top_3_states[2].order_count).to eq(1)
      end
      it '.top_3_cities' do
        expect(Order.top_3_cities[0].city).to eq('Denver')
        expect(Order.top_3_cities[0].state).to eq('CO')
        expect(Order.top_3_cities[0].order_count).to eq(1)

        expect(Order.top_3_cities[1].city).to eq('NYC')
        expect(Order.top_3_cities[1].state).to eq('NY')
        expect(Order.top_3_cities[1].order_count).to eq(1)

        expect(Order.top_3_cities[2].city).to eq('Seattle')
        expect(Order.top_3_cities[2].state).to eq('CO')
        expect(Order.top_3_cities[2].order_count).to eq(1)
      end
      it '.top_3_quantity_orders' do
        expect(Order.top_3_quantity_orders[0].user_name).to eq(@user_2.name)
        expect(Order.top_3_quantity_orders[0].total_quantity).to eq(300)
        expect(Order.top_3_quantity_orders[1].user_name).to eq(@user_4.name)
        expect(Order.top_3_quantity_orders[1].total_quantity).to eq(201)
        expect(Order.top_3_quantity_orders[2].user_name).to eq(@user_3.name)
        expect(Order.top_3_quantity_orders[2].total_quantity).to eq(200)
      end
    end
  end

  describe 'instance methods' do
    before :each do
      user = create(:user)
      @item_1 = create(:item)
      @item_2 = create(:item)
      yesterday = 1.day.ago

      @order = create(:order, user: user, created_at: yesterday)
      @oi_1 = create(:order_item, order: @order, item: @item_1, price: 1, quantity: 1, created_at: yesterday, updated_at: yesterday)
      @oi_2 = create(:fulfilled_order_item, order: @order, item: @item_2, price: 2, quantity: 1, created_at: yesterday, updated_at: 2.hours.ago)
    end

    it '.last_udpate' do
      expect(@order.last_update).to eq(@oi_2.updated_at)
    end

    it '.total_item_count' do
      expect(@order.total_item_count).to eq(@oi_1.quantity + @oi_2.quantity)
    end
    
    it '.subtotal' do
      expect(@order.subtotal).to eq((@oi_1.quantity*@oi_1.price) + (@oi_2.quantity*@oi_2.price))
    end
    
    it '.total_cost' do
      # No coupons
      expect(@order.total_cost).to eq((@oi_1.quantity*@oi_1.price) + (@oi_2.quantity*@oi_2.price))
      
      # Percentage coupon
      order = create(:order)
      coupon = create(:percent_coupon)
      oi = create(:coupon_order_item, coupon: coupon, order: order)
      expect(order.total_cost).to eq((oi.price * oi.quantity) - ((oi.price * oi.quantity) * (coupon.amount / 100.0)))
      
      # Dollars coupon
      order_2 = create(:order)
      coupon_2 = create(:dollar_coupon, amount: 2)
      oi_2 = create(:coupon_order_item, price: 10, coupon: coupon_2, order: order_2)
      expect(order_2.total_cost).to eq((oi_2.price * oi_2.quantity) - coupon_2.amount)
      
      # Dollars coupon with multiple items
      oi_3 = create(:coupon_order_item, coupon: coupon_2, order: order_2)
      expect(order_2.total_cost).to eq((oi_3.price * oi_3.quantity) + (oi_2.price * oi_2.quantity) - coupon_2.amount)
      
      # Dollars coupon with minimum cart amount met
      order_3 = create(:order)
      coupon_3 = create(:dollar_coupon, amount: 2, cart_minimum: 10)
      oi_4 = create(:coupon_order_item, price: 20, coupon: coupon_3, order: order_3)
      expect(order_3.total_cost).to eq((oi_4.price * oi_4.quantity) - coupon_3.amount)
      
      # Dollars coupon with minimum cart amount not met
      order_3 = create(:order)
      coupon_3 = create(:dollar_coupon, amount: 2, cart_minimum: 20)
      oi_4 = create(:coupon_order_item, price: 10, quantity: 1, coupon: coupon_3, order: order_3)
      expect(order_3.total_cost).to eq(oi_4.price * oi_4.quantity)
      
      # Dollars coupon where coupon amount exceeds merchant items amount
      order_4 = create(:order)
      coupon_4 = create(:dollar_coupon, amount: 10)
      oi_5 = create(:coupon_order_item, price: 5, quantity: 1, coupon: coupon_4, order: order_4)
      expect(order_4.total_cost).to eq(0)
    end

    it '.my_item_count' do
      merchants = create_list(:merchant, 2)
      item_1 = create(:item, user: merchants[0])
      item_3 = create(:item, user: merchants[0])
      item_2 = create(:item, user: merchants[1])
      orders = create_list(:order, 3)
      create(:order_item, order: orders[0], item: item_1, price: 1, quantity: 3)
      create(:order_item, order: orders[0], item: item_3, price: 1, quantity: 7)
      create(:order_item, order: orders[1], item: item_2, price: 1, quantity: 6)
      create(:order_item, order: orders[1], item: item_3, price: 1, quantity: 2)
      create(:order_item, order: orders[2], item: item_1, price: 1, quantity: 9)

      expect(orders[0].my_item_count(merchants[0].id)).to eq(10)
      expect(orders[0].my_item_count(merchants[1].id)).to eq(0)

      expect(orders[1].my_item_count(merchants[0].id)).to eq(2)
      expect(orders[1].my_item_count(merchants[1].id)).to eq(6)

      expect(orders[2].my_item_count(merchants[0].id)).to eq(9)
      expect(orders[2].my_item_count(merchants[1].id)).to eq(0)
    end

    it '.my_revenue_value' do
      merchants = create_list(:merchant, 2)
      item_1 = create(:item, user: merchants[0])
      item_3 = create(:item, user: merchants[0])
      item_2 = create(:item, user: merchants[1])
      orders = create_list(:order, 3)
      create(:order_item, order: orders[0], item: item_1, price: 1, quantity: 3)
      create(:order_item, order: orders[0], item: item_3, price: 2, quantity: 7)
      create(:order_item, order: orders[1], item: item_2, price: 3, quantity: 6)
      create(:order_item, order: orders[1], item: item_3, price: 4, quantity: 2)
      create(:order_item, order: orders[2], item: item_1, price: 5, quantity: 9)

      expect(orders[0].my_revenue_value(merchants[0].id)).to eq(17)
      expect(orders[0].my_revenue_value(merchants[1].id)).to eq(0)

      expect(orders[1].my_revenue_value(merchants[0].id)).to eq(8)
      expect(orders[1].my_revenue_value(merchants[1].id)).to eq(18)

      expect(orders[2].my_revenue_value(merchants[0].id)).to eq(45)
      expect(orders[2].my_revenue_value(merchants[1].id)).to eq(0)
    end

    it '.my_items' do
      merchants = create_list(:merchant, 2)
      item_1 = create(:item, user: merchants[0])
      item_2 = create(:item, user: merchants[1])
      item_3 = create(:item, user: merchants[0])
      order = create(:order)
      create(:order_item, order: order, item: item_1, price: 1, quantity: 3)
      create(:order_item, order: order, item: item_2, price: 2, quantity: 7)
      create(:fulfilled_order_item, order: order, item: item_3, price: 1.50, quantity: 4)

      expect(order.my_items(merchants[0])).to eq([item_1, item_3])
      expect(order.my_items(merchants[1])).to eq([item_2])
    end

    it '.item_price' do
      merchant = create(:merchant)
      item_1 = create(:item, user: merchant)
      order = create(:order)
      oi = create(:order_item, order: order, item: item_1, price: 345.67, quantity: 3)

      expect(order.item_price(item_1.id)).to eq(oi.price)
    end

    it '.item_quantity' do
      merchant = create(:merchant)
      item_1 = create(:item, user: merchant)
      order = create(:order)
      oi = create(:order_item, order: order, item: item_1, price: 345.67, quantity: 397)

      expect(order.item_quantity(item_1.id)).to eq(oi.quantity)
    end

    it '.item_fulfilled?' do
      merchant = create(:merchant)
      item_1 = create(:item, user: merchant)
      item_2 = create(:item, user: merchant)
      order = create(:order)
      oi = create(:order_item, order: order, item: item_1, price: 345.67, quantity: 397)
      oi = create(:fulfilled_order_item, order: order, item: item_2, price: 345.67, quantity: 397)

      expect(order.item_fulfilled?(item_1.id)).to eq(false)
      expect(order.item_fulfilled?(item_2.id)).to eq(true)
    end
    
    it '.coupon' do
      expect(@order.coupon).to eq(nil)
      
      coupon = create(:percent_coupon)
      
      order = create(:order)
      create(:fulfilled_order_item, order: order, coupon: coupon)
      expect(order.coupon).to eq(coupon)
      
      order = create(:order)
      create(:order_item, order: order, coupon: coupon)
      expect(order.coupon).to eq(coupon)
      
      order = create(:order)
      create(:order_item, order: order)
      expect(order.coupon).to eq(nil)
    end
    
    it '.my_coupon' do
      merchant = create(:user)
      expect(@order.my_coupon(merchant)).to eq(nil)
      
      item = create(:item, user: merchant)
      coupon = create(:percent_coupon, user: merchant)
      
      order = create(:order)
      create(:fulfilled_order_item, order: order, item: item, coupon: coupon)
      expect(order.my_coupon(merchant)).to eq(coupon)
      
      order = create(:order)
      create(:order_item, order: order, item: item, coupon: coupon)
      expect(order.my_coupon(merchant)).to eq(coupon)
      
      order = create(:order)
      create(:order_item, order: order)
      expect(order.my_coupon(merchant)).to eq(nil)
      
      coupon_1 = create(:percent_coupon)
      order = create(:order)
      create(:order_item, coupon: coupon_1)
      expect(order.my_coupon(merchant)).to eq(nil)
    end
    
    it '.discounted_item_price' do
      merchant = create(:merchant)
      item_1 = create(:item, user: merchant)
      order = create(:order)
      coupon = create(:percent_coupon)
      
      oi = create(:coupon_order_item, order: order, item: item_1, coupon: coupon)

      expect(order.discounted_item_price(item_1.id, coupon)).to eq(oi.price - (oi.price * (coupon.amount / 100.0)))
    end
    
    it '.discount' do
      # Percentage coupon
      order = create(:order)
      coupon = create(:percent_coupon)
      oi = create(:coupon_order_item, coupon: coupon, order: order)
      coupon_oi_sum = oi.quantity * oi.price
      expect(order.discount(coupon_oi_sum)).to eq((oi.price * oi.quantity) * (coupon.amount / 100.0))
      
      # Dollars coupon
      order_2 = create(:order)
      coupon_2 = create(:dollar_coupon, amount: 2)
      oi_2 = create(:coupon_order_item, price: 10, coupon: coupon_2, order: order_2)
      coupon_oi_sum = oi_2.quantity * oi_2.price
      expect(order_2.discount(coupon_oi_sum)).to eq(coupon_2.amount)
      
      # Dollars coupon with multiple items
      oi_3 = create(:coupon_order_item, coupon: coupon_2, order: order_2)
      coupon_oi_sum = oi_2.quantity * oi_2.price + oi_3.quantity * oi_3.price
      expect(order_2.discount(coupon_oi_sum)).to eq(coupon_2.amount)
      
      # Dollars coupon with minimum cart amount met
      order_3 = create(:order)
      coupon_3 = create(:dollar_coupon, amount: 2, cart_minimum: 10)
      oi_4 = create(:coupon_order_item, price: 20, coupon: coupon_3, order: order_3)
      coupon_oi_sum = oi_4.quantity * oi_4.price
      expect(order_3.discount(coupon_oi_sum)).to eq(coupon_3.amount)
      
      # Dollars coupon with minimum cart amount not met
      order_4 = create(:order)
      coupon_4 = create(:dollar_coupon, amount: 2, cart_minimum: 20)
      oi_5 = create(:coupon_order_item, price: 10, quantity: 1, coupon: coupon_4, order: order_4)
      coupon_oi_sum = oi_5.quantity * oi_5.price
      expect(order_4.discount(coupon_oi_sum)).to eq(0)
      
      # Dollars coupon where coupon amount exceeds merchant items amount
      order_5 = create(:order)
      coupon_5 = create(:dollar_coupon, amount: 10)
      oi_6 = create(:coupon_order_item, price: 5, quantity: 1, coupon: coupon_5, order: order_5)
      coupon_oi_sum = oi_6.quantity * oi_6.price
      expect(order_5.discount(coupon_oi_sum)).to eq(coupon_5.amount)
    end
  end
end