class ProductsController < ApplicationController
  def index
    @products = Product.kept
  end

  def show
    @product = Product.kept.find_by!(id: params[:id])
  end
end
