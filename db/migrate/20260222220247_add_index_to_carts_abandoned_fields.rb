class AddIndexToCartsAbandonedFields < ActiveRecord::Migration[7.1]
  def change
    add_index :carts, [:abandoned, :last_interaction_at], name: 'index_carts_on_abandoned_and_last_interaction'
  end
end
