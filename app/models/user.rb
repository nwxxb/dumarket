class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable

  has_one_attached :avatar

  has_many :cart_items
  has_many :orders

  def merge_cart_items_from_session(session_id)
    ActiveRecord::Base.transaction do
      session_cart_items = CartItem.where(session_id: session_id)

      session_cart_items.each do |cart_item|
        existing_cart_item = cart_items.lock.find_by(product_id: cart_item.product_id)

        if existing_cart_item
          existing_cart_item.update(
            amount: existing_cart_item.amount + cart_item.amount
          )
          cart_item.destroy
        else
          cart_item.update(user_id: id, session_id: nil)
        end
      end
    end
  end
end
