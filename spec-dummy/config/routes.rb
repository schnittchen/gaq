Dummy::Application.routes.draw do
  scope controller: :integration_spec do
    get :snippet_presence
  end
end
