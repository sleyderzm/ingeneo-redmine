Redmine::Plugin.register :modifications do
  name 'Modifications plugin'
  author 'AI Group SAS'
  description ''
  version '0.0.1'
  url ''

  project_module :time_tracking do |map|
    map.permission :check_time_entries, {}
  end
end

Rails.configuration.to_prepare do
  Issue.send(:include, IssuePatch)
end

Rails.configuration.to_prepare do
  IssueQuery.send(:include, IssueQueryPatch)
end

Rails.configuration.to_prepare do
  TimeEntryQuery.send(:include, TimeEntryQueryPatch)
end

Rails.configuration.to_prepare do
  TimeEntry.send(:include, TimeEntryPatch)
end