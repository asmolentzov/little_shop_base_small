class CouponsController < ApplicationController
  def index
    @coupons = Coupon.merchant_coupons(current_user)
  end
  
  def new
    @coupon = Coupon.new
  end
  
  def create
    @coupon = Coupon.new(coupon_params)
    @coupon.user = current_user
    if @coupon.save
      flash[:success] = "Coupon #{@coupon.code} was successfully created!"
      redirect_to coupons_path
    else
      render :new
    end
  end
  
  def destroy
    coupon = Coupon.find(params[:id])
    coupon.destroy
    flash[:success] = "Coupon #{coupon.code} was successfully deleted"
    redirect_to coupons_path
  end
  
  private
  
  def coupon_params
    params.require(:coupon).permit(:coupon_type, :amount, :cart_minimum, :code)
  end
end