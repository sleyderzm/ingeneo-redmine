module ImportIssuesHelper
  def import_help_tabs
    tabs = [
			{:name => 'trackers', :partial => 'import_issues/help/trackers', :label => :field_tracker},
            {:name => 'statuses', :partial => 'import_issues/help/statuses', :label => :field_status},
			{:name => 'users', :partial => 'import_issues/help/users', :label => :label_user_plural},
            {:name => 'priorities', :partial => 'import_issues/help/priorities', :label => :field_priority},
			{:name => 'categories', :partial => 'import_issues/help/categories', :label => :field_category},
			{:name => 'versions', :partial => 'import_issues/help/versions', :label => :field_fixed_version}
            ]
  end
  
  def load_data(attachment)
	@warning = Hash.new
	issues = []
	file = File.open(attachment.path)
	encoding = l(:general_csv_encoding)
	i = 0
	file.read.unpack("C*").pack("U*").split("\n").each do |line|	
		if i == 0
			i = i + 1
			next 
		end
		data = line.split(";")
		issue = Issue.new
		
		issue.subject = data[0]
		issue.description = data[10]
		issue.estimated_hours = data[2]
		issue.done_ratio = data[1]
		issue.project_id = @project.id
		
		begin
			issue.start_date =  data[3].to_date.strftime("%Y-%m-%d")
		rescue
			issue.start_date = Date.new
		end
		
		begin
			issue.due_date =  data[4].to_date.strftime("%Y-%m-%d")
		rescue
			issue.due_date = Date.new
		end
		
		if User.exists?(data[5]); issue.assigned_to_id = data[5];
		elsif User.count(:id, :conditions => ["login = ?", data[5]]) > 0; issue.assigned_to_id = User.find_by_login(data[5]).id;
		else issue.assigned_to_id = ""; end
		
		begin
		if Tracker.exists?(data[9]); issue.tracker_id = data[9];
		elsif @project.trackers.exists?(:name => data[9]); issue.tracker_id = @project.trackers.find_by_name(data[9]).id;
		else; issue.tracker_id = ""; end
		rescue; end
		
		begin
		if IssueStatus.exists?(data[8]); issue.status_id = data[8];
		elsif IssueStatus.exists?(:name => data[8]); issue.status_id = IssueStatus.find_by_name(data[8]).id;
		else; issue.status_id = ""; end
		rescue; end
		
		begin
		if IssuePriority.active.exists?(data[11]); issue.priority_id = data[11];
		elsif IssuePriority.exists?(:name => data[11]); issue.priority_id = IssuePriority.find_by_name(data[11]).id;
		else; issue.priority_id = ""; end
		rescue; end
				
		begin
		if IssueCategory.exists?(data[12]); issue.category_id = data[12];
		elsif @project.issue_categories.exists?(:name => data[12]); issue.category_id = @project.issue_categories.find_by_name(data[12]).id;
		else; issue.category_id = ""; end
		rescue; end
		
		begin
		if @project.versions.exists?(data[13]); issue.fixed_version_id = data[13];
		elsif @project.versions.exists?(:name => data[13]); issue.fixed_version_id = @project.versions.find_by_name(data[13]).id;
		else; issue.fixed_version_id = ""; end
		rescue; end
		
		begin
		
		issue.custom_field_values.each do |field|
		if field.custom_field.name == "Tipo de Servicio"
    		field.value = data[15]
    	end
		if field.custom_field.name == "Valor Hora"
    		field.value = data[16]
    	end
  		end
		end

		issue.instance_eval { class << self; self end }.send(:attr_accessor, :issue_number)
		issue.instance_eval { class << self; self end }.send(:attr_accessor, :issue_parent_number)
		
		issue.issue_number = data[7]
		issue.issue_parent_number = data[6]
		
		issue.non_billable_hours = data[14]

		issues << issue
	end
	
	
	
	issues
	
  end
end
