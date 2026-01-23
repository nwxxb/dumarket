class ProductsController < ApplicationController
  def index
    @products = Product.kept
  end

  def show
    @product = Product.kept.find(params[:id])
  end
end
