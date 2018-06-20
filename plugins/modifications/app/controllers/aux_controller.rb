class AuxController < ApplicationController
  unloadable
  
  #require 'iconv'
  
  before_filter :require_admin, :only => [:set_default_status, :users_report, :projects_report]
  before_filter :find_time_entry, :only => [:check, :save_check]
  
  accept_api_auth :users_report, :projects_report
  
  menu_item :issues
  
  helper :sort
  include SortHelper
  helper :aux
  include AuxHelper
  helper :issues
  helper :timelog
  include TimelogHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :queries
  include QueriesHelper
  
  
  
  def users_report
	@data = []
	@report_rows = []
	@projects = Project.active.order(:lft)
	if valid_date(params[:filter_start_date]) && valid_date(params[:filter_due_date])	
		@centers_cost = Project.active.where(parent_id: nil)
		centers_cost_ids = @centers_cost.map(&:id).compact.uniq
		if params[:filter_projects]
			@time_entries = TimeEntry.select("issue_id, user_id, project_id, hours, billing_hours").where("spent_on >= ? AND spent_on <= ? AND project_id IN (?)", params[:filter_start_date], params[:filter_due_date], params[:filter_projects].map{|i| i.to_i})
		else
			@time_entries = TimeEntry.select("issue_id, user_id, project_id, hours, billing_hours").where("spent_on >= ? AND spent_on <= ?", params[:filter_start_date], params[:filter_due_date])
		end
		issues_ids = @time_entries.map(&:issue_id).compact.uniq
		@issues = Issue.select("id, estimated_hours, project_id, assigned_to_id").where("#{Issue.table_name}.id IN (?) AND project_id NOT IN(?)", issues_ids, centers_cost_ids)
		users_ids = @time_entries.map(&:user_id).compact.uniq
		projects_ids = @time_entries.map(&:project_id).compact.uniq
		User.active.sorted.where(id: users_ids).each do |user|
			line = {}
			line[:type] = :user
			line[:link] = user
			user_issues = @time_entries.map{|t| t.issue_id if t.user_id == user.id }.compact.uniq
			line[:total_estimated_hours] =  @issues.map{|i| i.estimated_hours if user_issues.include?(i.id)}.compact.sum.to_f.round(2)
			line[:total_hours] =  0
			line[:total_billing_hours] =  0
			@time_entries.each do |t|
				if ! t.hours.nil? && t.user_id == user.id
					line[:total_hours] += t.hours
				end
				if ! t.billing_hours.nil? && t.user_id == user.id
					line[:total_billing_hours] += t.billing_hours
				end
			end
			line[:total_hours] = line[:total_hours].to_f.round(2)
			line[:total_billing_hours] = line[:total_billing_hours].to_f.round(2)
			@data << line unless line[:total_estimated_hours] == 0 && line[:total_hours] == 0 && line[:total_estimated_hours]
      Project.joins(:time_entries).where(:time_entries => {:user_id => user.id, :project_id => projects_ids}).uniq.each do |project|
				line = {}
				line[:user_name] = user.name
				user_project_issues = @time_entries.map{|t| t.issue_id if t.user_id == user.id && t.project_id == project.id}.compact.uniq
				line[:type] = :project
				line[:link] = project
				line[:total_estimated_hours] =  @issues.map{|i| i.estimated_hours if user_project_issues.include?(i.id)}.compact.sum.to_f.round(2)
				
				line[:total_hours] = 0
				line[:total_billing_hours] = 0
				@time_entries.each do |t|
					if ! t.hours.nil? && t.user_id == user.id && t.project_id == project.id
						line[:total_hours] += t.hours
					end
					if ! t.billing_hours.nil? && t.user_id == user.id && t.project_id == project.id
						line[:total_billing_hours] += t.billing_hours
					end
				end
				line[:total_hours] = line[:total_hours].to_f.round(2)
				line[:total_billing_hours] = line[:total_billing_hours].to_f.round(2)				
				unless line[:total_estimated_hours] == 0 && line[:total_hours] == 0 && line[:total_estimated_hours]
					@data << line
					row = ReportRow.new({:usuario => line[:user_name], :centro_costos => line[:link].root.name, :proyecto => line[:link].name,
										:total_horas_estimadas => line[:total_estimated_hours], :total_horas_ejecutadas => line[:total_hours],
										:total_horas_facturadas => line[:total_billing_hours]})
					@report_rows << row					
				end
			end		
		end
	end
	
	respond_to do |format|
		format.html { 
			@data_count = @data.size
			@data_pages =  Redmine::Pagination::Paginator.new @data_count,
														  per_page_option,
														  params['page']
			@data = @data[@data_pages.offset, @data_pages.per_page]
			render "projects/users_report"
		}
        format.csv { 
			send_data(users_report_to_csv(@data), :type => 'text/csv; header=present', :filename => "#{l(:label_users_report)}_#{Time.now.to_date.strftime("%Y_%m_%d")}.csv")
		}
        format.api {
			render "projects/projects_report"
		}
	end
	
  end
  
  def projects_report
	@data = []
	@report_rows = []
	@projects = Project.active.order(:lft)
	if valid_date(params[:filter_start_date]) && valid_date(params[:filter_due_date])
		@centers_cost = Project.active.where(parent_id: nil)
		centers_cost_ids = @centers_cost.map(&:id).compact.uniq
		if params[:filter_projects]
			@time_entries = TimeEntry.select("issue_id, user_id, project_id, hours, billing_hours").where("spent_on >= ? AND spent_on <= ? AND project_id IN (?)", params[:filter_start_date], params[:filter_due_date], params[:filter_projects].map{|i| i.to_i})
		else
			@time_entries = TimeEntry.select("issue_id, user_id, project_id, hours, billing_hours").where("spent_on >= ? AND spent_on <= ?", params[:filter_start_date], params[:filter_due_date])
		end
		projects_ids = @time_entries.map(&:project_id).compact.uniq
		issues_ids = @time_entries.map(&:issue_id).compact.uniq
		@issues = Issue.select("id, estimated_hours, project_id, assigned_to_id").where("#{Issue.table_name}.id IN (?) AND project_id NOT IN(?)", issues_ids, centers_cost_ids)
		Project.visible.where(parent_id: nil, id: centers_cost_ids).order(:lft).each do |parent|
			line = {}
			line[:type] = :parent
			line[:link] = parent
			descendants_ids = parent.descendants.map{|p| p.id }.compact.uniq
			line[:total_estimated_hours] =  @issues.map{|i| i.estimated_hours if descendants_ids.include?(i.project_id)}.compact.sum.to_f.round(2)
			line[:total_hours] =  0
			line[:total_billing_hours] = 0
			@time_entries.each do |t|
				if ! t.hours.nil? && descendants_ids.include?(t.project_id)
					line[:total_hours] += t.hours
				end
				if ! t.billing_hours.nil? && descendants_ids.include?(t.project_id)
					line[:total_billing_hours] += t.billing_hours
				end
			end
			line[:total_hours] = line[:total_hours].to_f.round(2)
			line[:total_billing_hours] = line[:total_billing_hours].to_f.round(2)
			@data << line unless line[:total_estimated_hours] == 0 && line[:total_hours] == 0 && line[:total_estimated_hours]
			parent.descendants.visible.order(:lft).each do |project|
				line = {}
				line[:type] = :project
				line[:link] = project
				line[:total_estimated_hours] =  @issues.map{|i| i.estimated_hours if i.project_id == project.id}.compact.sum.to_f.round(2)
				line[:total_hours] = 0
				line[:total_billing_hours] = 0
				@time_entries.each do |t|
					if ! t.hours.nil? && t.project_id == project.id
						line[:total_hours] += t.hours
					end
					if ! t.billing_hours.nil? && t.project_id == project.id
						line[:total_billing_hours] += t.billing_hours
					end
				end
				line[:total_hours] = line[:total_hours].to_f.round(2)
				line[:total_billing_hours] = line[:total_billing_hours].to_f.round(2)
				unless line[:total_estimated_hours] == 0 && line[:total_hours] == 0 && line[:total_estimated_hours]
					@data << line
					row = ReportRow.new({:usuario => '', :centro_costos => line[:link].root.name, :proyecto => line[:link].name,
										:total_horas_estimadas => line[:total_estimated_hours], :total_horas_ejecutadas => line[:total_hours],
										:total_horas_facturadas => line[:total_billing_hours]})
					@report_rows << row	
				end
				
			end		
		end
	end
	respond_to do |format|
		format.html { 
			@data_count = @data.size
			@data_pages =  Redmine::Pagination::Paginator.new @data_count,
														  per_page_option,
														  params['page']
			@data = @data[@data_pages.offset, @data_pages.per_page]
			render "projects/projects_report"
		}
        format.csv { 
			send_data(projects_report_to_csv(@data), :type => 'text/csv; header=present', :filename => "#{l(:label_projects_report)}_#{Time.now.to_date.strftime("%Y_%m_%d")}.csv")
		}
		format.api {
			render "projects/projects_report"
		}
	end
  end
  
  def set_default_status
	params[:ids].each do |id|
		begin
			issue = Issue.find(id) if Issue.exists?(id)
			if issue.done_ratio.to_i == 100 && issue.status_id != Setting.issue_status_when_done_ratio_is_completed.to_i
				issue.init_journal(User.current)
				issue.update_attribute :status_id, Setting.issue_status_when_done_ratio_is_completed.to_i
			end
		rescue
			# Error Inesperado
		end
	end
	redirect_to params[:back_url]
	flash[:notice] = l(:notice_successful_update)
  end
  
  def save_check 
	if params[:form_query]
		begin
			params_data = Rack::Utils.parse_nested_query(params[:form_query])
			params[:f] = params_data["f"]
			params[:op] = params_data["op"]
			params[:v] = params_data["v"]
		rescue
			
		end
	end
	entries = params[:entries]
	validations = {}
	if entries
		entries.each do |key, entry|
			if entry.has_key?(:revised)
				time_entry = TimeEntry.find(key)
				time_entry.revised = true
				time_entry.billing_hours = entry[:billing_hours]
				time_entry.billing_comment = entry[:billing_comment]
				if time_entry.valid?
					time_entry.save
				else
					validations[key.to_sym] = time_entry
				end
			end
		end
	end
	@validations = validations
	
	@query = TimeEntryQuery.build_from_params(params, :project => @project, :name => '_')
	sort_init(@query.sort_criteria.empty? ? [['spent_on', 'desc']] : @query.sort_criteria)
	sort_update(@query.sortable_columns)
	scope = time_entry_scope(:order => sort_clause).
	  includes(:project, :user, :issue).
	  preload(:issue => [:project, :tracker, :status, :assigned_to, :priority])
	  
	respond_to do |format|
	  format.html {
		@entry_count = scope.count
		@entry_pages = Paginator.new @entry_count, per_page_option, params['page']
		@entries = scope.offset(@entry_pages.offset).limit(@entry_pages.per_page).all
		@total_hours = scope.sum(:hours).to_f
		@total_billing_hours = scope.sum(:billing_hours).to_f
    @issues_billing_hours=scope.group(:issue_id).sum(:billing_hours)
    Rails.logger.debug @issues_billing_hours.to_yaml
    @total_estimated_hours= 0
    scope.group(:issue_id).uniq.each do |issue|
      @total_estimated_hours=@total_estimated_hours+ issue.issue.estimated_hours.to_i
    end
		render 'timelog/check'
	  }
	end
  end
  
  
  def check
	@query = TimeEntryQuery.build_from_params(params, :project => @project, :name => '_')
	sort_init(@query.sort_criteria.empty? ? [['spent_on', 'desc']] : @query.sort_criteria)
	sort_update(@query.sortable_columns)
	scope = time_entry_scope(:order => sort_clause).
	  includes(:project, :user, :issue).
	  preload(:issue => [:project, :tracker, :status, :assigned_to, :priority])
  
	respond_to do |format|
	  format.html {
		@entry_count = scope.count
		@entry_pages = Paginator.new @entry_count, per_page_option, params['page']
		@entries = scope.offset(@entry_pages.offset).limit(@entry_pages.per_page).all
		@total_hours = scope.sum(:hours).to_f
		@total_billing_hours = scope.sum(:billing_hours).to_f
    @issues_billing_hours=scope.group(:issue_id).sum(:billing_hours)
    Rails.logger.debug @issues_billing_hours.to_yaml
    @total_estimated_hours= 0
    scope.group(:issue_id).uniq.each do |issue|
      @total_estimated_hours=@total_estimated_hours+ issue.issue.estimated_hours.to_i
    end
		render 'timelog/check'
	  }
	end
  end
  
  private
  
  def time_entry_scope(options={})
    scope = @query.results_scope(options)
    if @issue
      scope = scope.on_issue(@issue)
    end
    scope
  end
  
  def find_time_entry
	@cols = ["spent_on", "user", "activity", "issue", "comments", "hours","issue.estimated_hours", "revised", "billing_hours", "billing_comment"]
	if !params[:issue_id].blank?
      @issue = Issue.find(params[:issue_id])
      @project = @issue.project
    elsif !params[:project_id].blank?
      @project = Project.find(params[:project_id])
    end
  end
  
end
