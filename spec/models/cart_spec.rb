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
    item_1 = create(:item, price: 20, user: merchant)
    item_2 = create(:item, price: 10, user: merchant)
    cart = Cart.new({})
    cart.add_item(item_1.id)
    cart.add_item(item_1.id)
    cart.add_item(item_2.id)
    cart.add_item(item_2.id)
    cart.add_item(item_2.id)
    
    total = (item_1.price * 2) + (item_2.price * 3)

    expect(cart.grand_total).to eq(total)
    
    coupon = create(:percent_coupon, user: merchant)
    expect(cart.grand_total(coupon)).to eq(total - ((coupon.amount / 100.0) * total))
    
    coupon_2 = create(:dollar_coupon, user: merchant)
    expect(cart.grand_total(coupon_2)).to eq(total - coupon.amount)
    
    coupon_3 = create(:dollar_coupon, amount: 10, cart_minimum: 20, user: merchant)
    expect(cart.grand_total(coupon_3)).to eq(total - coupon.amount)
    
    coupon_4 = create(:dollar_coupon, amount: 10, cart_minimum: 500, user: merchant)
    expect(cart.grand_total(coupon_4)).to eq(total)
    
    coupon_5 = create(:percent_coupon)
    expect(cart.grand_total(coupon_5)).to eq(total)
    
    merchant_2 = create(:merchant)
    item_3 = create(:item, price: 200, user: merchant_2)
    coupon_6 = create(:percent_coupon, user: merchant_2)
    cart.add_item(item_3.id)
    new_total = total + item_3.price
    expect(cart.grand_total(coupon_6)).to eq(new_total - (item_3.price * (coupon_6.amount / 100.0)))
    
    coupon_7 = create(:dollar_coupon, code: 'HERE', user: merchant, amount: 10, cart_minimum: 200)
    expect(cart.grand_total(coupon_7)).to eq(new_total)
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
  
  it '.apply_coupon' do
    item = create(:item, price: 10)
    coupon = create(:percent_coupon, amount: 10)
    subtotal = 10
    cart = Cart.new({})
    cart.add_item(item.id)
    
    expect(cart.apply_coupon(item, coupon, subtotal)).to eq(item.price - (item.price * (coupon.amount / 100.0)))
    
    amount = 2
    coupon_2 = create(:dollar_coupon, amount: amount)
    expect(cart.apply_coupon(item, coupon_2, subtotal)).to eq(item.price - amount)
    
    coupon_3 = create(:dollar_coupon, amount: amount, cart_minimum: 5)
    expect(cart.apply_coupon(item, coupon_3, subtotal)).to eq(item.price - amount)
    expect(coupon_3.amount).to eq(0)
    
    coupon_4 = create(:dollar_coupon, amount: amount, cart_minimum: 20)
    expect(cart.apply_coupon(item, coupon_4, subtotal)).to eq(item.price)
    expect(coupon_4.amount).to eq(2)
  end
  
  it 'merchant_pre_discount_total' do
    merchant = create(:merchant)
    item_1 = create(:item, user: merchant)
    item_2 = create(:item)
    cart = Cart.new({})
    cart.add_item(item_1.id)
    cart.add_item(item_1.id)
    cart.add_item(item_2.id)
    
    expect(cart.merchant_pre_discount_total(merchant)).to eq(item_1.price * 2)
  end
end