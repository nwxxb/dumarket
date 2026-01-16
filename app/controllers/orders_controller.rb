class OrdersController < ApplicationController
  before_action :authenticate_user!

  def index
    @orders = current_user.orders
  end

  def new
    @cart_items = CartItem.where(user: current_user)
      .joins(:product)
      .merge(Product.kept)
      .order(:created_at)

    redirect_to(cart_items_path, notice: "No items exist in cart") and return if @cart_items.blank?

    @cart_items_total_price = 0

    @cart_items.each do |cart_item|
      @cart_items_total_price += cart_item.product.price * cart_item.amount
    end
    @total = @cart_items_total_price

    @cart_items_count = @cart_items.size

    @order = current_user.orders.new
  end

  def create
    @cart_items = CartItem.where(user: current_user)
      .joins(:product)
      .merge(Product.kept)
      .order(:created_at)

    redirect_to(cart_items_path, notice: "No items exist in cart") and return if @cart_items.blank?

    @cart_items_total_price = 0

    @cart_items.each do |cart_item|
      @cart_items_total_price += cart_item.product.price * cart_item.amount
    end
    @total = @cart_items_total_price

    @cart_items_count = @cart_items.size

    @order = current_user.orders.new(
      status: "pending",
      items_count: @cart_items_count,
      total_amount: @cart_items_total_price,
      **customer_info_params
    )

    if @order.save
      @cart_items.each do |cart_item|
        order_item = @order.order_items.create(
          product: cart_item.product,
          amount: cart_item.amount,
          price_at_purchase: cart_item.product.price,
          product_name: cart_item.product.name,
          product_description: cart_item.product.description
        )

        if cart_item.product&.images&.attached?
          image = cart_item.product.images.last
          image.blob.open do |tempfile|
            order_item.images.attach(
              io: tempfile,
              filename: image.filename.to_s,
              content_type: image.content_type
            )
          end
        end
      end
      @cart_items.destroy_all
      session[:cart_items_count] = 0

      redirect_to orders_path, notice: "Order created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @order = Order.find(params[:id])
    @order_items = @order.order_items
  end

  private
  def customer_info_params
    params.require(:order).permit(:customer_name, :customer_address)
  end
end
