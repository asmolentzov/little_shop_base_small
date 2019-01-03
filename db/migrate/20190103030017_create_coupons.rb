class CreateCoupons < ActiveRecord::Migration[5.1]
  def change
    create_table :coupons do |t|
      t.integer :coupon_type
      t.integer :amount
      t.integer :cart_minimum, default: 0
      t.string :code
      t.boolean :used, default: false
      
      t.timestamps
    end
  end
end
