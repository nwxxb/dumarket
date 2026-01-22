class Admin::OrdersController < Admin::BaseController
  def index
    @orders = Order.all
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
      render :show, status: :unprocessable_entity
    end
  end

  private
  def change_status_params
    params.require(:order).permit(:status)
  end
end
