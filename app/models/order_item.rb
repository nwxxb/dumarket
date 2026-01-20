class OrderItem < ApplicationRecord
  TITLE_REGEX = /\A[\p{L}\p{N}()&!$#@%.,`"'?:=;_\*\-\\\/ ]*\z/
  DESCRIPTION_REGEX = /\A[\p{L}\p{N}()&!$#@%.,`"'?:=;_\*\-\\\/\s]*\z/

  belongs_to :order
  belongs_to :product, optional: true

  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 1 }
  validates :product_name, presence: true, format: {
    with: TITLE_REGEX, message: "only allow normal characters"
  }, length: { in: 3..100 }
  validates :product_description, allow_nil: false, format: {
    with: DESCRIPTION_REGEX, message: "only allow normal characters"
  }, length: { maximum: 1000 }
  monetize :price_at_purchase_cents, numericality: { greater_than_or_equal_to: 0 }

  has_many_attached :images
end
