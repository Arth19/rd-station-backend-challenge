class Cart < ApplicationRecord
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  validates :total_price, numericality: { greater_than_or_equal_to: 0 }

  scope :abandoned_candidates, -> { where(abandoned: false).where('last_interaction_at <= ?', 3.hours.ago) }
  scope :removable_abandoned, -> { where(abandoned: true).where('last_interaction_at <= ?', 7.days.ago) }

  def mark_as_abandoned
    update!(abandoned: true)
  end

  def remove_if_abandoned
    destroy! if abandoned? && last_interaction_at <= 7.days.ago
  end

  def touch_interaction
    update!(last_interaction_at: Time.current)
  end

  def add_item(product:, quantity:)
    cart_item = cart_items.find_by(product: product)

    if cart_item
      cart_item.update!(quantity: cart_item.quantity + quantity)
    else
      cart_items.create!(product: product, quantity: quantity)
    end

    recalculate_total!
  end

  def remove_item(product:)
    cart_item = cart_items.find_by(product: product)
    return nil unless cart_item

    cart_item.destroy!
    recalculate_total!
    cart_item
  end

  def as_json_response
    {
      id: id,
      products: cart_items.includes(:product).map do |item|
        {
          id: item.product.id,
          name: item.product.name,
          quantity: item.quantity,
          unit_price: item.unit_price.to_f,
          total_price: item.total_price.to_f
        }
      end,
      total_price: total_price.to_f
    }
  end

  private

  def recalculate_total!
    calculated_total = cart_items.joins(:product).sum('products.price * cart_items.quantity')
    update!(total_price: calculated_total)
  end
end
