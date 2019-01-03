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
      @errors = @coupon.errors
      render :new
    end
  end
  
  def destroy
    coupon = Coupon.find(params[:id])
    coupon.destroy
    flash[:success] = "Coupon #{coupon.code} was successfully deleted"
    redirect_to coupons_path
  end
  
  def edit
    @coupon = Coupon.find(params[:id])
  end
  
  def update
    coupon = Coupon.find(params[:id])
    if coupon.update(coupon_params)
      flash[:success] = "Coupon #{coupon.code} was successfully updated!"
      redirect_to coupons_path
    else
      @coupon = Coupon.find(params[:id])
      @errors = coupon.errors
      render :edit
    end
  end
  
  def apply
    coupon = Coupon.find_by(code: code_params[:code])
    @cart.add_coupon(coupon)
    flash[:success] = "Coupon #{coupon.code} was successfully applied!"
    redirect_to cart_path
  end
  
  private
  
  def coupon_params
    params.require(:coupon).permit(:coupon_type, :amount, :cart_minimum, :code)
  end
  
  def code_params
    params.require(:coupon).permit(:code)
  end
end