class Order < ApplicationRecord
  belongs_to :user
  has_many :order_items
  has_many :items, through: :order_items

  validates_presence_of :status

  enum status: [:pending, :completed, :cancelled]

  def self.top_3_states
    Order.joins(:user, :order_items)
      .select('users.state, count(order_items.id) as order_count')
      .where("order_items.fulfilled = ?", true)
      .group('users.state')
      .order('order_count desc, users.state asc')
      .limit(3)
  end

  def self.top_3_cities
    Order.joins(:user, :order_items)
      .select('users.city, users.state, count(order_items.id) as order_count')
      .where("order_items.fulfilled = ?", true)
      .group('users.state, users.city')
      .order('order_count desc, users.city asc, users.state asc')
      .limit(3)
  end

  def self.top_3_quantity_orders
    Order.joins(:user, :order_items)
      .select('users.name as user_name, sum(order_items.quantity) as total_quantity')
      .where('order_items.fulfilled=?', true)
      .order('total_quantity desc, user_name asc')
      .group(:id, 'users.id')
      .limit(3)
  end

  def last_update
    order_items.maximum(:updated_at)
  end

  def total_item_count
    order_items.sum(:quantity)
  end
  
  def subtotal
    order_items.pluck("sum(quantity*price)").sum
  end

  def total_cost
    if coupon
      coupon_order_items_sum = order_items.where.not(coupon_id: nil)
                              .pluck("sum(quantity*price)").sum
      other_order_items_sum = order_items.where(coupon_id: nil)
                              .pluck("sum(quantity*price)").sum
      discount = discount(coupon_order_items_sum)
      discount_total = coupon_order_items_sum - discount 
      discount_total = 0 if discount_total < 0
      discount_total + other_order_items_sum
    else
      oi = order_items.pluck("sum(quantity*price)")
      oi.sum
    end
  end
  
  def discount(coupon_oi_sum)
    if coupon.percentage?
      discount = coupon_oi_sum * (coupon.amount / 100.0)
    elsif coupon.cart_minimum < coupon_oi_sum
      discount = coupon.amount
    else
      discount = 0
    end
  end

  def my_item_count(merchant_id)
    self.order_items
      .joins(:item)
      .where("items.merchant_id=?", merchant_id)
      .pluck("sum(order_items.quantity)")
      .first.to_i
  end

  def my_revenue_value(merchant_id)
    self.order_items
      .joins(:item)
      .where("items.merchant_id=?", merchant_id)
      .pluck("sum(order_items.quantity * order_items.price)")
      .first.to_i
  end

  def my_items(merchant_id)
    Item.joins(order_items: :order)
      .where(
        :merchant_id => merchant_id,
        :"orders.id" => self.id,
        :"orders.status" => :pending
      )
  end

  def item_price(item_id)
    order_items.where(item_id: item_id).pluck(:price).first
  end

  def item_quantity(item_id)
    order_items.where(item_id: item_id).pluck(:quantity).first
  end

  def item_fulfilled?(item_id)
    order_items.where(item_id: item_id).pluck(:fulfilled).first
  end
  
  def coupon
    oi = order_items.where.not(coupon_id: nil)
    oi.empty? ? nil : oi.first.coupon
  end
  
  def my_coupon(merchant)
    if coupon && coupon.user == merchant
      coupon
    else
      nil
    end
  end
  
  def discounted_item_price(item_id, coupon)
    price = item_price(item_id)
    price - (price * coupon.amount / 100.0)
  end
end