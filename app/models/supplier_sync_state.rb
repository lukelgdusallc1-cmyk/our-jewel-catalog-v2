class SupplierSyncState < ApplicationRecord
  COOLDOWN = 15.minutes
  def self.current
    first || create!
  end
  def eligible_at
    last_attempt_at && last_attempt_at + COOLDOWN
  end
  def can_fetch?
    eligible_at.nil? || Time.current >= eligible_at
  end
end
