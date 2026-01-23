class Order < ApplicationRecord
  CUSTOMER_NAME_REGEX = /\A[\p{L}\p{N}()&!$#@%.,`"'?:=;_*\-\\\/ ]*\z/
  CUSTOMER_ADDR_REGEX = /\A[\p{L}\p{N}()&!$#@%.,`"'?:=;_*\-\\\/\s]*\z/

  validates :customer_name, presence: true, format: {
    with: CUSTOMER_NAME_REGEX, message: "only allow normal characters"
  }, length: {in: 3..100}
  validates :customer_address, allow_nil: false, format: {
    with: CUSTOMER_ADDR_REGEX, message: "only allow normal characters"
  }, length: {maximum: 1000}

  belongs_to :user
  monetize :total_amount_cents, numericality: {greater_than_or_equal_to: 0}

  enum :status, {pending: "pending", delivered: "delivered", completed: "completed"}

  def unselected_statuses
    Order.statuses.except(status)
  end

  has_many :order_items
end
