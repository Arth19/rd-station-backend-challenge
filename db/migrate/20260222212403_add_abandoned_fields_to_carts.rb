class AddAbandonedFieldsToCarts < ActiveRecord::Migration[7.1]
  def change
    add_column :carts, :abandoned, :boolean, default: false, null: false
    add_column :carts, :last_interaction_at, :datetime, default: -> { 'CURRENT_TIMESTAMP' }, null: false
  end
end
