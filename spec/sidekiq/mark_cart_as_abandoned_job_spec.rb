require 'rails_helper'

RSpec.describe MarkCartAsAbandonedJob, type: :job do
  describe '#perform' do
    it 'marks carts as abandoned after 3 hours of inactivity' do
      inactive_cart = create(:cart, last_interaction_at: 4.hours.ago, abandoned: false)
      active_cart = create(:cart, last_interaction_at: 1.hour.ago, abandoned: false)

      described_class.new.perform

      expect(inactive_cart.reload.abandoned?).to be true
      expect(active_cart.reload.abandoned?).to be false
    end

    it 'removes carts abandoned for more than 7 days' do
      old_abandoned_cart = create(:cart, last_interaction_at: 8.days.ago, abandoned: true)
      recent_abandoned_cart = create(:cart, last_interaction_at: 2.days.ago, abandoned: true)

      expect { described_class.new.perform }.to change(Cart, :count).by(-1)

      expect(Cart.find_by(id: old_abandoned_cart.id)).to be_nil
      expect(Cart.find_by(id: recent_abandoned_cart.id)).to be_present
    end

    it 'does not affect active carts' do
      active_cart = create(:cart, last_interaction_at: 30.minutes.ago, abandoned: false)

      described_class.new.perform

      expect(active_cart.reload.abandoned?).to be false
    end
  end
end
