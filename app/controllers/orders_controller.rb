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

    @cart_signature = generate_cart_signature(@cart_items)
    @order = current_user.orders.new
  end

  def create
    @redirect_back_flag = false
    ActiveRecord::Base.transaction do
      @cart_items = CartItem.where(user: current_user)
        .joins(:product)
        .merge(Product.kept)
        .order(:product_id)
        .lock("FOR UPDATE OF cart_items, products")
        .includes(:product)

      if @cart_items.blank?
        flash[:alert] = "No items exist in cart"
        @redirect_back_flag = true
        raise ActiveRecord::RecordInvalid
      end

      if cart_signature_params != generate_cart_signature(@cart_items)
        flash[:alert] = "There are some changes happen in cart, please verify"
        @redirect_back_flag = true
        raise ActiveRecord::RecordInvalid
      end

      @cart_items_total_price = 0

      @cart_items.each do |cart_item|
        @cart_items_total_price += cart_item.product.price * cart_item.amount
      end
      @total = @cart_items_total_price

      @cart_items_count = @cart_items.size

      @order = current_user.orders.create!(
        status: "pending",
        items_count: @cart_items_count,
        total_amount: @cart_items_total_price,
        **customer_info_params
      )

      @cart_items.each do |cart_item|
        order_item = @order.order_items.new(
          product: cart_item.product,
          amount: cart_item.amount,
          price_at_purchase: cart_item.product.price,
          product_name: cart_item.product.name,
          product_description: cart_item.product.description
        )

        if order_item.save
          if cart_item.product.images&.attached?
            image = cart_item.product.images.last
            order_item.images.attach(
              io: StringIO.new(image.download),
              filename: image.filename.to_s,
              content_type: image.content_type
            )
          end
        else
          flash[:alert] = "We encountered a technical issue processing your items. Please try again or contact support."
          @redirect_back_flag = true
          raise ActiveRecord::RecordInvalid
        end
      end
      @cart_items.destroy_all
      session[:cart_items_count] = 0
    end

    redirect_to orders_path, notice: "Order created"
  rescue ActiveRecord::RecordInvalid
    if @redirect_back_flag
      redirect_to(cart_items_path) and return
    end

    render(:new, status: :unprocessable_entity) and return
  end

  def show
    @order = Order.find(params[:id])
    @order_items = @order.order_items
  end

  private
  def customer_info_params
    params.require(:order).permit(:customer_name, :customer_address)
  end

  def cart_signature_params
    params.require(:order).permit(:cart_signature)[:cart_signature]
  end

  def generate_cart_signature(cart_items)
    val = cart_items.map do |ci|
    [ ci.product_id, ci.amount, ci.product.price_cents, ci.product.price_currency, ci.product.discarded? ].join("-")
    end.sort.join("|")
    Rails.application.message_verifier(:cart_signature).generate(val)
  end
end
