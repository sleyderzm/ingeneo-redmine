# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

match '/aux/projects_report', :to => 'aux#projects_report', :via => [:get, :post, :put, :delete], :as => :projects_report
match '/aux/users_report', :to => 'aux#users_report', :via => [:get, :post, :put, :delete], :as => :users_report