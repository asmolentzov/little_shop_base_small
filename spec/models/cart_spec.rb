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
    merchant = create(:merchant)
    item_1 = create(:item, user: merchant)
    item_2 = create(:item, user: merchant)
    cart = Cart.new({})
    cart.add_item(item_1.id, price: 20)
    cart.add_item(item_1.id)
    cart.add_item(item_2.id)
    cart.add_item(item_2.id)
    cart.add_item(item_2.id)
    
    total = cart.subtotal(item_1.id) + cart.subtotal(item_2.id)

    expect(cart.grand_total).to eq(total)
    
    coupon = create(:percent_coupon, user: merchant)
    
    expect(cart.grand_total(coupon)).to eq(total - ((coupon.amount / 100.0) * total))
    
    coupon_2 = create(:dollar_coupon, user: merchant)
    
    expect(cart.grand_total(coupon_2)).to eq(total - coupon.amount)
    
    coupon_3 = create(:dollar_coupon, amount: 10, cart_minimum: 20, user: merchant)
    
    expect(cart.grand_total(coupon_3)).to eq(total - coupon.amount)
    
    coupon_4 = create(:dollar_coupon, amount: 10, cart_minimum: 500, user: merchant)
    
    expect(cart.grand_total(coupon_4).to eq(total))
    
    coupon_5 = create(:percent_coupon)
    
    expect(cart.grand_total(coupon)).to eq(total)
  end
  
  it '.pre_discount_total' do
    item_1 = create(:item)
    item_2 = create(:item)
    cart = Cart.new({})
    cart.add_item(item_1.id)
    cart.add_item(item_1.id)
    cart.add_item(item_2.id)
      
    expect(cart.pre_discount_total).to eq(item_1.price + item_1.price + item_2.price)
  end
end