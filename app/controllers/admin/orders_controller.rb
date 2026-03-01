class Admin::OrdersController < Admin::BaseController
  def index
    @pagy, @orders = pagy(Order.all)
    @orders_count = Order.count
    @total_revenue = Money.from_cents(Order.completed.sum(:total_amount_cents), "USD").format
    @status_grouped_count = Order.group(:status).count
    @status_grouped_count.default = 0
  end

  def show
    @order = Order.find(params[:id])
    @order_items = @order.order_items
  end

  def update
    @order = Order.find(params[:id])

    if @order.update(change_status_params)
      redirect_to admin_order_path(@order), notice: "Order status updated"
    else
      render :show, status: :unprocessable_content
    end
  end

  private

  def change_status_params
    params.require(:order).permit(:status)
  end
end
