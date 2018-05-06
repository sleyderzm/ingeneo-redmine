RedmineApp::Application.routes.draw do
  match "/roadmaps", :controller => "roadmaps_main", :action => "index", :via => :get
end
