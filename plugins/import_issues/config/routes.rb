# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

match 'import_issues/index/:id', :to => 'import_issues#index', :via => [:get, :post, :put, :delete]
match 'import_issues/import/:id', :to => 'import_issues#import', :via => [:get, :post, :put, :delete]
match 'import_issues/help/:id', :to => 'import_issues#help', :via => [:get, :post, :put, :delete]
match 'import_issues/save/:id', :to => 'import_issues#save', :via => [:get, :post, :put, :delete]
