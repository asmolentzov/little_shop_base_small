require 'rails_helper'

describe Coupon, type: :model do
  describe 'Validations' do
    it { should validate_presence_of(:coupon_type) }
    it { should validate_presence_of(:amount) }
    it { should validate_numericality_of(:amount).only_integer.is_greater_than_or_equal_to(0) }
    it { should validate_presence_of(:code) }
    it { should validate_uniqueness_of(:code) }
  end
  
  describe 'Class Methods' do
    describe '#merchant_coupons' do
      it 'returns all coupons belonging to a merchant' do
        merchant_1 = create(:merchant)
        coupon_1 = Coupon.create(coupon_type: 0, amount: 10, code: 'COUPON1', user: merchant_1)
        coupon_2 = Coupon.create(coupon_type: 0, amount: 10, code: 'COUPON2', user: merchant_1)
        coupon_3 = Coupon.create(coupon_type: 0, amount: 10, code: 'COUPON3', user: merchant_1)
        
        merchant_2 = create(:merchant)
        coupon_4 = Coupon.create(coupon_type: 0, amount: 10, code: 'COUPON4', user: merchant_2)
        coupon_5 = Coupon.create(coupon_type: 0, amount: 10, code: 'COUPON5', user: merchant_2)
        
        coupons_1 = [coupon_1, coupon_2, coupon_3]
        expect(Coupon.merchant_coupons(merchant_1)).to eq(coupons_1)
      end
    end
  end
end