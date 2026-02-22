require 'rails_helper'

RSpec.describe CartItem, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:cart) }
    it { is_expected.to belong_to(:product) }
  end

  describe 'validations' do
    it { is_expected.to validate_numericality_of(:quantity).only_integer.is_greater_than(0) }

    it 'validates uniqueness of product_id scoped to cart_id' do
      cart = create(:cart)
      product = create(:product)
      create(:cart_item, cart: cart, product: product)

      duplicate = build(:cart_item, cart: cart, product: product)
      expect(duplicate).not_to be_valid
    end
  end

  describe '#unit_price' do
    it 'returns the product price' do
      product = create(:product, price: 25.50)
      item = create(:cart_item, product: product)
      expect(item.unit_price).to eq(25.50)
    end
  end

  describe '#total_price' do
    it 'calculates the product price times quantity' do
      product = create(:product, price: 10.0)
      item = create(:cart_item, product: product, quantity: 3)
      expect(item.total_price).to eq(30.0)
    end
  end
end
