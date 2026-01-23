class Product < ApplicationRecord
  include Discard::Model

  TITLE_REGEX = /\A[\p{L}\p{N}()&!$#@%.,`"'?:=;_*\-\\\/ ]*\z/
  DESCRIPTION_REGEX = /\A[\p{L}\p{N}()&!$#@%.,`"'?:=;_*\-\\\/\s]*\z/

  has_many_attached :images
  validates :name, presence: true, format: {
    with: TITLE_REGEX, message: "only allow normal characters"
  }, length: {in: 3..100}
  validates :description, allow_nil: false, format: {
    with: DESCRIPTION_REGEX, message: "only allow normal characters"
  }, length: {maximum: 1000}
  monetize :price_cents, numericality: {greater_than_or_equal_to: 0}
end
