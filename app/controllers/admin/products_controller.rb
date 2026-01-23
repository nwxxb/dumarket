class Admin::ProductsController < Admin::BaseController
  def index
    @products = Product.all
  end

  def show
    @product = Product.find(params[:id])
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new(product_params)

    if @product.save
      redirect_to admin_product_path(@product)
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @product = Product.find(params[:id])
  end

  def update
    @product = Product.find(params[:id])

    if @product.update(product_params)
      redirect_to admin_product_path(@product)
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @product = Product.find(params[:id])
    @product.discard!

    redirect_to admin_products_path, notice: "product deleted"
  end

  private

  def product_params
    params.require(:product).permit(:name, :description, :price_cents, :images)
  end
end
