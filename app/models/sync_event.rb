class SyncEvent < ApplicationRecord
  validates :event_type, :status, presence: true
end
