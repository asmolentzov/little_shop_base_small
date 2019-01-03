class Coupon < ApplicationRecord
  validates_presence_of :coupon_type, :amount, :code
  validates_uniqueness_of :code
  
  enum coupon_type: [:percentage, :dollars]
  
  belongs_to :user
  
  def self.merchant_coupons(merchant)
    where(user: merchant)
  end
  
end