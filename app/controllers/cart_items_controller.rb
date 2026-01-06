class CartItemsController < ApplicationController
  before_action :write_to_session

  def index
    @cart_items = CartItem.where(**user_or_session_params).order(:created_at)
    @cart_items_count = @cart_items&.size || 0
    session[:cart_items_count] = @cart_items_count
  end

  def create
    @cart_item = CartItem.find_by(
      product_id: params[:product_id], **user_or_session_params
    )
    new_item_flag = false

    if @cart_item.present?
      @cart_item.amount = @cart_item.amount + 1
    else
      @cart_item = CartItem.new(
        product_id: params[:product_id], amount: 1, **user_or_session_params
      )
      new_item_flag = true
    end

    if @cart_item.save
      session[:cart_items_count] = (session[:cart_items_count] || 0) + 1 if new_item_flag
      redirect_back fallback_location: products_path, notice: "Product added to cart"
    else
      redirect_back fallback_location: products_path, alert: "Can't add product to cart"
    end
  end

  def update
    @cart_item = CartItem.find_by!(id: params[:id], **user_or_session_params)

    if cart_item_amount_params[:subaction] == "increase" && @cart_item.amount < 10
      @cart_item.amount = @cart_item.amount + 1

      @cart_item.save
    elsif cart_item_amount_params[:subaction] == "decrease" && @cart_item.amount > 1
      @cart_item.amount = @cart_item.amount - 1

      @cart_item.save
    end

    redirect_back fallback_location: cart_items_path
  end

  def destroy
    @cart_item = CartItem.find_by!(id: params[:id], **user_or_session_params)
    @cart_item.destroy!

    redirect_to admin_products_path, notice: "Product removed from cart"
  end

  private

  def user_or_session_params
    user_or_session = {}

    if user_signed_in?
      user_or_session[:user] = current_user
    else
      user_or_session[:session_id] = session[:session_id]
    end

    user_or_session
  end

  def cart_item_amount_params
    params.require(:cart_item).permit(:subaction)
  end

  def write_to_session
    # session is not initiated if we don't store anything on it
    # so session will return {} and session_id won't exist
    # this line of code is an attempt to make sure that we actually have
    # session and it's session_id before we interact with cart feature
    session[:init] = true unless session[:session_id].present?
  end
end
