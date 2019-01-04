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
  
  def edit
    @coupon = Coupon.find(params[:id])
  end
  
  def update
    @coupon = Coupon.find(params[:id])
    if @coupon.update(coupon_params)
      flash[:success] = "Coupon #{@coupon.code} was successfully updated!"
      redirect_to coupons_path
    else
      render :edit
    end
  end
  
  def apply
    coupon = Coupon.find_by(code: code_params[:code])
    if coupon && !(coupon.used)
      session[:coupon] = coupon
      flash[:success] = "Coupon #{coupon.code} was successfully applied!"
    else
      flash[:error] = "Coupon #{code_params[:code]} is not a valid coupon"
    end
    redirect_to cart_path
  end
  
  def remove
    code = session[:coupon]['code']
    session[:coupon] = nil
    flash[:success] = "Coupon #{code} was successfully removed"
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