class ImportIssuesController < ApplicationController
  
  before_filter :find_project, :authorize, :valid_project
  before_filter :load_enumerations, :only => [:help, :import, :save]
  
  helper :import_issues
  include ImportIssuesHelper
  helper :custom_fields
  include CustomFieldsHelper

  def index
  end
  
  def import
	if params[:importing]
		if params[:attachment].nil?
			flash.now[:error] = l(:label_notice_no_csv_file)
		elsif valid_file(params[:attachment]) == false
			flash.now[:error] = l(:label_notice_no_valid_csv_file, :file => params[:attachment].original_filename);
		else
			@issues = load_data(params[:attachment])
			if @issues.size <= 0
				flash.now[:error] = l(:label_notice_zero_issues_loaded, :file => params[:attachment].original_filename);
			else
				@valid = true
			end
		end
	else
		#nada
	end
	render :action => :index
  end
  
  def help
  end
  
  def save
	@issues = []
	if params[:issue]
		all_valid = true
		params[:issue].each do |key, issue|
			new_issue = Issue.new
			
			new_issue.subject = issue["subject"]
			new_issue.description = issue["description"]
			new_issue.estimated_hours = issue["estimated_hours"]
			new_issue.done_ratio = issue["done_ratio"]
			new_issue.start_date = issue["start_date"]
			new_issue.due_date = issue["due_date"]
			new_issue.assigned_to_id = issue["assigned_to_id"]
			new_issue.tracker_id = issue["tracker_id"]
			new_issue.status_id = issue["status_id"]
			new_issue.priority_id = issue["priority_id"]
			new_issue.category_id = issue["category_id"]
			new_issue.fixed_version_id = issue["fixed_version_id"]
			new_issue.is_private = (issue["is_private"].nil? ? 0 : 1)
			new_issue.non_billable_hours = (issue["non_billable_hours"].nil? ? 0 : 1)
			new_issue.author_id = User.current.id
			new_issue.project_id = @project.id
			
			new_issue.instance_eval { class << self; self end }.send(:attr_accessor, :issue_number)
			new_issue.instance_eval { class << self; self end }.send(:attr_accessor, :issue_parent_number)

			new_issue.issue_number = issue["issue_number"]
			new_issue.issue_parent_number = issue["issue_parent_number"]
			
			new_issue.custom_field_values = issue["custom_field_values"]
		
			if ! new_issue.valid?
				all_valid = false
			end
			@issues << new_issue
		end
		numbers_ids = {}
		if all_valid
			cont = 0
			@issues.each do |i|
				
				if ! i.issue_parent_number.nil? && ! numbers_ids[i.issue_parent_number].nil?
					i.parent_issue_id = Issue.find(numbers_ids[i.issue_parent_number]).id if Issue.exists?(numbers_ids[i.issue_parent_number])
				end
				begin
					if i.save
						numbers_ids[i.issue_number] = i.id
					end
					cont += 1
				rescue; end
			end
			@issues = nil
			@valid = false
			flash.now[:notice] = l(:label_notice_total_issues_loaded, :number => cont)
		else
			@valid = true
		end
		
	end
	render :action => :index
  end
  
  private
  
  def load_enumerations
	@categories = @project.issue_categories
	@statuses = IssueStatus.sorted.all
	@users = @project.users.sort
	@priorities = IssuePriority.active
	@categories = @project.issue_categories
	@versions = @project.versions.sort
	@trackers = @project.trackers.sort
  end
  
  def valid_project
    if @project.parent.nil?
		render_403 :message => :notice_not_authorized_to_create_issue
	end
  end
  
  def valid_file(attachment)
	  case File.extname(attachment.original_filename)
	  when ".csv" then 
		true
	  else 
		false
	  end
  end
  
  def find_project
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
