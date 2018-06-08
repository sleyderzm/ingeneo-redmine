Redmine::Plugin.register :import_issues do
  name 'Import Issues plugin'
  author 'AI Group SAS'
  description ''
  version '0.0.1'
  url ''

  menu :project_menu, :import_issues, {:controller => 'import_issues', :action => 'index'}, :caption => :label_import_issues, :if => Proc.new { |p| ! p.parent.nil? }

  project_module :issue_tracking do
    permission :import_issues_2, { :import_issues => [:index, :help, :import, :save] }
  end

end

