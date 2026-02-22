require 'rails_helper'

RSpec.describe Cart, type: :model do
  context 'when validating' do
    it 'validates numericality of total_price' do
      cart = described_class.new(total_price: -1)
      expect(cart.valid?).to be_falsey
      expect(cart.errors[:total_price]).to include("must be greater than or equal to 0")
    end
  end

  describe 'mark_as_abandoned' do
    let(:shopping_cart) { create(:shopping_cart) }

    it 'marks the shopping cart as abandoned if inactive for a certain time' do
      shopping_cart.update(last_interaction_at: 3.hours.ago)
      expect { shopping_cart.mark_as_abandoned }.to change { shopping_cart.abandoned? }.from(false).to(true)
    end
  end

  describe 'remove_if_abandoned' do
    let(:shopping_cart) { create(:shopping_cart, last_interaction_at: 7.days.ago) }

    it 'removes the shopping cart if abandoned for a certain time' do
      shopping_cart.mark_as_abandoned
      expect { shopping_cart.remove_if_abandoned }.to change { Cart.count }.by(-1)
    end
  end

  describe 'associations' do
    it { is_expected.to have_many(:cart_items).dependent(:destroy) }
    it { is_expected.to have_many(:products).through(:cart_items) }
  end

  describe '#add_item' do
    let(:cart) { create(:cart) }
    let(:product) { create(:product, price: 10.0) }

    it 'adds a new product to the cart' do
      expect { cart.add_item(product: product, quantity: 2) }
        .to change { cart.cart_items.count }.by(1)
    end

    it 'updates total_price after adding an item' do
      cart.add_item(product: product, quantity: 2)
      expect(cart.total_price.to_f).to eq(20.0)
    end

    it 'increments quantity when product already exists in cart' do
      cart.add_item(product: product, quantity: 1)
      cart.add_item(product: product, quantity: 3)
      expect(cart.cart_items.find_by(product: product).quantity).to eq(4)
    end
  end

  describe '#remove_item' do
    let(:cart) { create(:cart) }
    let(:product) { create(:product, price: 5.0) }

    before { cart.add_item(product: product, quantity: 2) }

    it 'removes the product from the cart' do
      expect { cart.remove_item(product: product) }
        .to change { cart.cart_items.count }.by(-1)
    end

    it 'returns nil when product is not in cart' do
      other_product = create(:product, name: 'Other')
      expect(cart.remove_item(product: other_product)).to be_nil
    end

    it 'updates total_price after removing an item' do
      cart.remove_item(product: product)
      expect(cart.total_price.to_f).to eq(0.0)
    end
  end

  describe '#touch_interaction' do
    let(:cart) { create(:cart, last_interaction_at: 1.day.ago) }

    it 'updates last_interaction_at to current time' do
      freeze_time do
        cart.touch_interaction
        expect(cart.last_interaction_at).to be_within(1.second).of(Time.current)
      end
    end
  end

  describe '#as_json_response' do
    let(:cart) { create(:cart) }
    let(:product) { create(:product, name: 'Test Product', price: 15.0) }

    before { cart.add_item(product: product, quantity: 3) }

    it 'returns the correct JSON structure' do
      json = cart.as_json_response
      expect(json[:id]).to eq(cart.id)
      expect(json[:products].length).to eq(1)
      expect(json[:products].first[:name]).to eq('Test Product')
      expect(json[:products].first[:quantity]).to eq(3)
      expect(json[:products].first[:unit_price]).to eq(15.0)
      expect(json[:products].first[:total_price]).to eq(45.0)
      expect(json[:total_price]).to eq(45.0)
    end
  end

  describe '.abandoned_candidates' do
    it 'returns carts inactive for more than 3 hours' do
      old_cart = create(:cart, last_interaction_at: 4.hours.ago, abandoned: false)
      recent_cart = create(:cart, last_interaction_at: 1.hour.ago, abandoned: false)

      expect(Cart.abandoned_candidates).to include(old_cart)
      expect(Cart.abandoned_candidates).not_to include(recent_cart)
    end
  end

  describe '.removable_abandoned' do
    it 'returns abandoned carts older than 7 days' do
      old_abandoned = create(:cart, last_interaction_at: 8.days.ago, abandoned: true)
      recent_abandoned = create(:cart, last_interaction_at: 1.day.ago, abandoned: true)

      expect(Cart.removable_abandoned).to include(old_abandoned)
      expect(Cart.removable_abandoned).not_to include(recent_abandoned)
    end
  end
end
