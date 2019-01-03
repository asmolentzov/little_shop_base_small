class Coupon < ApplicationRecord
  validates_presence_of :coupon_type, :amount, :code
  validates_uniqueness_of :code
  
end