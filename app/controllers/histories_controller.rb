class HistoriesController < ApplicationController
  def index
    @events = SyncEvent.order(created_at: :desc).limit(100)
  end
end
