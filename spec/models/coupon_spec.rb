require 'rails_helper'

describe Coupon, type: :model do
  describe 'Validations' do
    it { should validate_presence_of(:coupon_type) }
    it { should validate_presence_of(:amount) }
    it { should validate_numericality_of(:amount).only_integer.is_greater_than_or_equal_to(0) }
    it { should validate_presence_of(:code) }
    it { should validate_uniqueness_of(:code) }
  end
end