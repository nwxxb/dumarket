class ProductsController < ApplicationController
  def index
    @pagy, @products = pagy(Product.kept)
  end

  def show
    @product = Product.kept.find(params[:id])
  end
end
