class MarkCartAsAbandonedJob
  include Sidekiq::Job

  def perform(*args)
    mark_abandoned_carts
    remove_old_abandoned_carts
  end

  private

  def mark_abandoned_carts
    Cart.abandoned_candidates.update_all(abandoned: true)
  end

  def remove_old_abandoned_carts
    Cart.removable_abandoned.find_each(&:destroy!)
  end
end
