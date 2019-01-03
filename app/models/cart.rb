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
    subtotal = item.price * count_of(item_id)
    if coupon && coupon.user == item.user
      if coupon.coupon_type == 'percentage'
        subtotal -= ((coupon.amount / 100.0) * subtotal)
      elsif coupon.cart_minimum < pre_discount_total
        difference = subtotal - coupon.amount
        if (difference) >= 0
          subtotal = difference
          coupon.amount = 0
        else
          subtotal = 0
          coupon.amount = abs(difference)
        end
      end
    end
    subtotal
  end

  def grand_total(coupon = nil)
    coupon = Coupon.find(coupon["id"]) if coupon
    @contents.keys.map do |item_id|
      subtotal(item_id, coupon)
    end.sum
  end
  
  def pre_discount_total
    @contents.keys.sum do |item_id|
      Item.find(item_id).price * count_of(item_id)
    end
  end
end