require 'rails_helper'

RSpec.describe Cart do
  it '.total_count' do
    cart = Cart.new({
      '1' => 2,
      '2' => 3
    })
    expect(cart.total_count).to eq(5)
  end

  it '.count_of' do
    cart = Cart.new({})
    expect(cart.count_of(5)).to eq(0)

    cart = Cart.new({
      '2' => 3
    })
    expect(cart.count_of(2)).to eq(3)
  end

  it '.add_item' do
    cart = Cart.new({
      '1' => 2,
      '2' => 3
    })

    cart.add_item(1)
    cart.add_item(2)
    cart.add_item(3)

    expect(cart.contents).to eq({
      '1' => 3,
      '2' => 4,
      '3' => 1
      })
  end

  it '.subtract_item' do
    cart = Cart.new({
      '1' => 2,
      '2' => 3
    })

    cart.subtract_item(1)
    cart.subtract_item(1)
    cart.subtract_item(2)

    expect(cart.contents).to eq({
      '2' => 2
      })
  end

  it '.remove_all_of_item' do
    cart = Cart.new({
      '1' => 2,
      '2' => 3
    })

    cart.remove_all_of_item(1)

    expect(cart.contents).to eq({
      '2' => 3
    })
  end

  it '.items' do
    item_1, item_2 = create_list(:item, 2)
    cart = Cart.new({})
    cart.add_item(item_1.id)
    cart.add_item(item_2.id)

    expect(cart.items).to eq([item_1, item_2])
  end

  it '.subtotal' do
    item_1 = create(:item)
    cart = Cart.new({})
    cart.add_item(item_1.id)
    cart.add_item(item_1.id)
    cart.add_item(item_1.id)

    expect(cart.subtotal(item_1.id)).to eq(item_1.price * cart.total_count)
  end

  it '.grand_total' do
    item_1, item_2 = create_list(:item, 2)
    cart = Cart.new({})
    cart.add_item(item_1.id)
    cart.add_item(item_1.id)
    cart.add_item(item_2.id)
    cart.add_item(item_2.id)
    cart.add_item(item_2.id)

    expect(cart.grand_total).to eq(cart.subtotal(item_1.id) + cart.subtotal(item_2.id))
  end
  
  it '.add_coupon' do
    item_1 = create(:item)
    cart = Cart.new({})
    cart.add_item(item_1.id)
  
    coupon = create(:percent_coupon)
    cart.add_coupon(coupon)
    
    expect(cart.coupons).to eq([coupon])
    
    coupon_2 = create(:dollar_coupon)
    coupon_3 = create(:dollar_coupon)
    cart.add_coupon(coupon_2)
    cart.add_coupon(coupon_3)
    
    expect(cart.coupons).to eq([coupon, coupon_2, coupon_3])
  end
  
  it '.coupons' do
      item_1 = create(:item)
      cart = Cart.new({})
      cart.add_item(item_1.id)
    
      coupon = create(:percent_coupon)
      cart.add_coupon(coupon)
      
      expect(cart.coupons).to eq([coupon])
      
      coupon_2 = create(:dollar_coupon)
      coupon_3 = create(:dollar_coupon)
      cart.add_coupon(coupon_2)
      cart.add_coupon(coupon_3)
      
      expect(cart.coupons).to eq([coupon, coupon_2, coupon_3])
  end
end