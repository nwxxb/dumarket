class Admin::ProductsController < Admin::BaseController
  def index
    @products = Product.all
  end

  def show
    @product = Product.find_by!(id: params[:id])
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new(product_params)

    if @product.save
      redirect_to admin_product_path(@product)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @product = Product.find_by!(id: params[:id])
  end

  def update
    @product = Product.find_by!(id: params[:id])

    if @product.update(product_params)
      redirect_to admin_product_path(@product)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @product = Product.find_by!(id: params[:id])
    @product.destroy!

    redirect_to admin_products_path, notice: "product deleted"
  end

  private
  def product_params
    params.require(:product).permit(:name, :description, :price_cents, :images)
  end
end
