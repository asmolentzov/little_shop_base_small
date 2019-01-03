FactoryBot.define do
  factory :percent_coupon do
    coupon_type { 'percentage' }
    sequence(:amount) { |n| n * 10 }
    sequence(:code) { |n| "COUPON#{n}"}
  end
  
  factory :dollar_coupon do
    coupon_type { 'dollars' }
    sequence(:amount) { |n| n * 10 }
    sequence(:code) { |n| "COUPON#{n}"}
  end
end