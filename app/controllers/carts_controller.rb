class CartsController < ApplicationController
  before_action :set_cart, only: [:show, :add_item, :remove_item]

  # GET /cart
  def show
    if @cart
      render json: @cart.as_json_response
    else
      render json: { error: 'Cart not found' }, status: :not_found
    end
  end

  # POST /cart
  def create
    product = find_product
    return unless product

    validate_quantity or return

    @cart = current_or_create_cart
    @cart.add_item(product: product, quantity: params[:quantity].to_i)
    @cart.touch_interaction

    render json: @cart.as_json_response, status: :created
  end

  # POST /cart/add_item
  def add_item
    return render json: { error: 'Cart not found' }, status: :not_found unless @cart

    product = find_product
    return unless product

    validate_quantity or return

    @cart.add_item(product: product, quantity: params[:quantity].to_i)
    @cart.touch_interaction

    render json: @cart.as_json_response
  end

  # DELETE /cart/:product_id
  def remove_item
    return render json: { error: 'Cart not found' }, status: :not_found unless @cart

    product = Product.find_by(id: params[:product_id])
    return render json: { error: 'Product not found' }, status: :not_found unless product

    removed = @cart.remove_item(product: product)
    return render json: { error: 'Product not found in cart' }, status: :not_found unless removed

    @cart.touch_interaction

    render json: @cart.as_json_response
  end

  private

  def set_cart
    @cart = Cart.find_by(id: session[:cart_id])
  end

  def current_or_create_cart
    cart = Cart.find_by(id: session[:cart_id])
    return cart if cart

    cart = Cart.create!(total_price: 0)
    session[:cart_id] = cart.id
    cart
  end

  def find_product
    product = Product.find_by(id: params[:product_id])
    render json: { error: 'Product not found' }, status: :not_found unless product
    product
  end

  def validate_quantity
    quantity = params[:quantity].to_i
    if quantity <= 0
      render json: { error: 'Quantity must be greater than 0' }, status: :unprocessable_entity
      return false
    end
    true
  end
end
