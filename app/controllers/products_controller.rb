class ProductsController < ApplicationController
  def index
    @pagy, @products = pagy(Product.kept.with_attached_images)
  end

  def show
    @product = Product.kept.find(params[:id])
  end
end
