require 'factory_bot'

FactoryBot.define do
  factory :percent_coupon, class: Coupon do
    coupon_type { 'percentage' }
    sequence(:amount) { |n| n * 10 }
    sequence(:code) { |n| "COUPON#{n}"}
    association :user, factory: :merchant
  end
  
  factory :dollar_coupon, class: Coupon do
    coupon_type { 'dollars' }
    sequence(:amount) { |n| n * 10 }
    sequence(:code) { |n| "COUPONDOLLARS#{n}"}
    association :user, factory: :merchant
  end
end