
module TimeEntryQueryPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    # Same as typing in the class
    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development
      alias_method_chain :initialize_available_filters, :modifications
	  alias_method_chain :available_columns, :modifications
	  alias_method_chain :default_columns_names, :modifications
    end
	
  end
  
  module InstanceMethods

		def default_columns_names_with_modifications
			@default_columns_names ||= begin
				default_columns = [:spent_on, :user, :activity, :issue, :comments, :hours, :estimated_hours, :revised, :billing_hours, :billing_comment]

				project.present? ? default_columns : [:project] | default_columns
			end
		end

		def available_columns_with_modifications
			return @available_columns if @available_columns
			@available_columns = self.class.available_columns.dup
			@available_columns += TimeEntryCustomField.visible.
					map {|cf| QueryCustomFieldColumn.new(cf) }
			@available_columns += issue_custom_fields.visible.
					map {|cf| QueryAssociationCustomFieldColumn.new(:issue, cf, :totalable => false) }
			@available_columns += ProjectCustomField.visible.
					map {|cf| QueryAssociationCustomFieldColumn.new(:project, cf) }
			if ! project.nil?
				if User.current.allowed_to?(:check_time_entries, project)
					@available_columns = @available_columns + [
							QueryColumn.new(:revised, :sortable => "#{TimeEntry.table_name}.revised"),
							QueryColumn.new(:billing_hours, :sortable => "#{TimeEntry.table_name}.billing_hours"),
							QueryColumn.new(:billing_comment),
					]
				end
			elsif User.current.admin?
				@available_columns = @available_columns + [
						QueryColumn.new(:billing_comment),
						QueryColumn.new(:billing_hours, :sortable => "#{TimeEntry.table_name}.billing_hours"),
						QueryColumn.new(:revised, :sortable => "#{TimeEntry.table_name}.revised"),
				]
			end
			@available_columns
		end

		def initialize_available_filters_with_modifications
			if ! project.nil?
				if User.current.allowed_to?(:check_time_entries, project)
					add_available_filter "billing_hours", :type => :float
					add_available_filter "revised", :type => :list, :values => [[l(:general_text_Yes), "1"], [l(:general_text_No), "0"]]
				end
			elsif User.current.admin?
				add_available_filter "billing_hours", :type => :float
				add_available_filter "revised", :type => :list, :values => [[l(:general_text_Yes), "1"], [l(:general_text_No), "0"]]
			end
			add_available_filter "spent_on", :type => :date_past

			add_available_filter("project_id",
													 :type => :list, :values => lambda { project_values }
			) if project.nil?

			if project && !project.leaf?
				add_available_filter "subproject_id",
														 :type => :list_subprojects,
														 :values => lambda { subproject_values }
			end

			add_available_filter("issue_id", :type => :tree, :label => :label_issue)
			add_available_filter("issue.tracker_id",
													 :type => :list,
													 :name => l("label_attribute_of_issue", :name => l(:field_tracker)),
													 :values => lambda { trackers.map {|t| [t.name, t.id.to_s]} })
			add_available_filter("issue.status_id",
													 :type => :list,
													 :name => l("label_attribute_of_issue", :name => l(:field_status)),
													 :values => lambda { issue_statuses_values })
			add_available_filter("issue.fixed_version_id",
													 :type => :list,
													 :name => l("label_attribute_of_issue", :name => l(:field_fixed_version)),
													 :values => lambda { fixed_version_values })

			add_available_filter("user_id",
													 :type => :list_optional, :values => lambda { author_values }
			)

			activities = (project ? project.activities : TimeEntryActivity.shared)
			add_available_filter("activity_id",
													 :type => :list, :values => activities.map {|a| [a.name, a.id.to_s]}
			)

			add_available_filter "comments", :type => :text
			add_available_filter "hours", :type => :float

			add_custom_fields_filters(TimeEntryCustomField)
			add_associations_custom_fields_filters :project
			add_custom_fields_filters(issue_custom_fields, :issue)
			add_associations_custom_fields_filters :user
		end
  end    
end

# Add module to Query

