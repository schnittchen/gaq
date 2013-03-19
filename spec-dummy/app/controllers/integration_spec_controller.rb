class IntegrationSpecController < ApplicationController
  before_filter do
    gaq.track_event 'controller', 'action', params[:action]
  end

  def snippet_presence
    render :view
  end

  def redirecting_action
    gaq.next_request.track_event('from', 'redirecting', 'action')
    redirect_to action: :target_action
  end

  def target_action
    render :view
  end

  def final_action
    render :view
  end
end
