RedmineApp::Application.routes.draw do
  match '/auth/saml' => 'saml#index'
  match '/auth/saml/consume' => 'saml#consume'
end
