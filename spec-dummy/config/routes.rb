Dummy::Application.routes.draw do
  scope controller: :integration_spec do
    get :snippet_presence
    get :redirecting_action
    get :target_action
    get :final_action
  end
end
