class Coupon < ApplicationRecord
  validates_presence_of :coupon_type, :amount, :code
  validates_uniqueness_of :code
  validates :amount, numericality: { only_integer: true, greater_than_or_equal_to: 0}
  
  enum coupon_type: [:percentage, :dollars]
  
  belongs_to :user
  
end