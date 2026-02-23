require 'rails_helper'

RSpec.describe "/carts", type: :request do
  describe "GET /cart" do
    context 'when there is no cart in session' do
      it 'returns not found' do
        get '/cart', as: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when there is a cart in session' do
      let(:product) { create(:product, name: "Test Product", price: 10.0) }

      it 'returns the cart with products' do
        post '/cart', params: { product_id: product.id, quantity: 2 }, as: :json
        get '/cart', as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['products'].length).to eq(1)
        expect(json['products'].first['name']).to eq('Test Product')
        expect(json['products'].first['quantity']).to eq(2)
        expect(json['products'].first['unit_price']).to eq(10.0)
        expect(json['products'].first['total_price']).to eq(20.0)
        expect(json['total_price']).to eq(20.0)
      end
    end
  end

  describe "POST /cart" do
    let(:product) { create(:product, name: "Test Product", price: 10.0) }

    context 'with a valid product' do
      it 'creates a cart and adds the product' do
        expect {
          post '/cart', params: { product_id: product.id, quantity: 1 }, as: :json
        }.to change(Cart, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['products'].first['name']).to eq('Test Product')
        expect(json['products'].first['quantity']).to eq(1)
      end

      it 'reuses the existing cart from session' do
        post '/cart', params: { product_id: product.id, quantity: 1 }, as: :json
        first_cart_id = JSON.parse(response.body)['id']

        other_product = create(:product, name: 'Another Product', price: 5.0)
        post '/cart', params: { product_id: other_product.id, quantity: 1 }, as: :json
        second_cart_id = JSON.parse(response.body)['id']

        expect(first_cart_id).to eq(second_cart_id)
      end
    end

    context 'with an invalid product_id' do
      it 'returns not found' do
        post '/cart', params: { product_id: 99999, quantity: 1 }, as: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with an invalid quantity' do
      it 'returns unprocessable entity for zero quantity' do
        post '/cart', params: { product_id: product.id, quantity: 0 }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns unprocessable entity for negative quantity' do
        post '/cart', params: { product_id: product.id, quantity: -1 }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "POST /cart/add_item" do
    let(:product) { create(:product, name: "Test Product", price: 10.0) }

    context 'when there is no cart in session' do
      it 'returns not found' do
        post '/cart/add_item', params: { product_id: product.id, quantity: 1 }, as: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when the product already is in the cart' do
      before do
        post '/cart', params: { product_id: product.id, quantity: 1 }, as: :json
      end

      it 'updates the quantity of the existing item in the cart' do
        post '/cart/add_item', params: { product_id: product.id, quantity: 2 }, as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['products'].first['quantity']).to eq(3)
        expect(json['products'].first['total_price']).to eq(30.0)
        expect(json['total_price']).to eq(30.0)
      end
    end

    context 'when the product is not in the cart yet' do
      let(:other_product) { create(:product, name: 'Other Product', price: 5.0) }

      before do
        post '/cart', params: { product_id: product.id, quantity: 1 }, as: :json
      end

      it 'adds a new item to the cart' do
        post '/cart/add_item', params: { product_id: other_product.id, quantity: 3 }, as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['products'].length).to eq(2)
        expect(json['total_price']).to eq(25.0)
      end
    end
  end

  describe "DELETE /cart/:product_id" do
    let(:product) { create(:product, name: "Test Product", price: 10.0) }
    let(:other_product) { create(:product, name: "Other Product", price: 5.0) }

    context 'when the product exists in the cart' do
      before do
        post '/cart', params: { product_id: product.id, quantity: 2 }, as: :json
        post '/cart/add_item', params: { product_id: other_product.id, quantity: 1 }, as: :json
      end

      it 'removes the product and returns updated cart' do
        delete "/cart/#{product.id}", as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['products'].length).to eq(1)
        expect(json['products'].first['id']).to eq(other_product.id)
        expect(json['total_price']).to eq(5.0)
      end
    end

    context 'when removing the last product leaves the cart empty' do
      before do
        post '/cart', params: { product_id: product.id, quantity: 1 }, as: :json
      end

      it 'returns an empty cart with total_price 0' do
        delete "/cart/#{product.id}", as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['products']).to eq([])
        expect(json['total_price']).to eq(0.0)
      end
    end

    context 'when the product does not exist in the cart' do
      before do
        post '/cart', params: { product_id: product.id, quantity: 1 }, as: :json
      end

      it 'returns not found' do
        delete "/cart/#{other_product.id}", as: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when the product does not exist at all' do
      before do
        post '/cart', params: { product_id: product.id, quantity: 1 }, as: :json
      end

      it 'returns not found' do
        delete "/cart/99999", as: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when there is no cart in session' do
      it 'returns not found' do
        delete "/cart/#{product.id}", as: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
