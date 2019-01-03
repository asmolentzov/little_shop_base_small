class CouponsController < ApplicationController
  def new
    @coupon = Coupon.new
  end
end