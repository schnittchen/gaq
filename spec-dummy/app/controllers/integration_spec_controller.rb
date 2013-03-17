class IntegrationSpecController < ApplicationController
  before_filter do
    gaq.track_event 'controller', 'action', params[:action]
  end

  def snippet_presence
    render :view
  end
end
