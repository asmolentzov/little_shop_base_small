class Cart
  attr_reader :contents

  def initialize(initial_contents)
    @contents = initial_contents || Hash.new(0)
  end

  def total_count
    @contents.values.sum
  end

  def count_of(item_id)
    @contents[item_id.to_s].to_i
  end

  def add_item(item_id)
    @contents[item_id.to_s] ||= 0
    @contents[item_id.to_s] += 1
  end

  def subtract_item(item_id)
    @contents[item_id.to_s] -= 1
    @contents.delete(item_id.to_s) if @contents[item_id.to_s] == 0
  end

  def remove_all_of_item(item_id)
    @contents.delete(item_id.to_s)
  end

  def items
    @contents.keys.map do |item_id|
      Item.includes(:user).find(item_id)
    end
  end

  def subtotal(item_id, coupon = nil)
    item = Item.find(item_id)
    subtotal_amount = item.price * count_of(item_id)
    if coupon && coupon.user == item.user
      subtotal_amount = apply_coupon(item, coupon, subtotal_amount)
    end
    subtotal_amount
  end

  def grand_total(coupon = nil)
    if coupon && coupon.coupon_type == 'dollars' && coupon.cart_minimum > merchant_pre_discount_total(coupon.user)
      coupon = nil
    end
    @contents.keys.map do |item_id|
      subtotal(item_id, coupon)
    end.sum
  end
  
  def pre_discount_total
    @contents.keys.sum do |item_id|
      Item.find(item_id).price * count_of(item_id)
    end
  end
  
  def merchant_pre_discount_total(merchant)
    @contents.keys.sum do |item_id| 
      if Item.find(item_id).user == merchant
        Item.find(item_id).price * count_of(item_id)
      else
        0 
      end
    end
  end
  
  def apply_coupon(item, coupon, subtotal_amount)
    if coupon.coupon_type == 'percentage'
      subtotal_amount -= ((coupon.amount / 100.0) * subtotal_amount)
    else
      difference = subtotal_amount - coupon.amount
      if (difference) >= 0
        coupon.amount = 0
        subtotal_amount = difference
      else
        coupon.amount = difference.abs
        subtotal_amount = 0
      end
    end
    subtotal_amount
  end
end