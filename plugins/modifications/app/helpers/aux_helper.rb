module AuxHelper
	
	def link_to_element_user_report(element)
		val = ''
		if element.is_a?(User)
			val << link_to_user(element)
		elsif element.is_a?(Project)
			val << content_tag("span", '&nbsp;'.html_safe, :style => "margin-left: 15px;")
			val << link_to_project(element)
			val << ' - '
			val << link_to_project(element.root)
		else
			val << '&nbsp;'
		end
		val.html_safe
	end
	
	def link_to_element_user_report_csv(element)
		val = ''
		if element.is_a?(User)
			val << element.name
		elsif element.is_a?(Project)
			val << "   "
			val << element.name
			val << ' - '
			val << element.root.name
		else
			val << ''
		end
		val
	end
	
	
	def link_to_element_project_report(element)
		val = ''
		if element.is_a?(Project) && element.parent.nil?
			val << link_to_project(element)
		elsif element.is_a?(Project)
			val << content_tag("span", '&nbsp;'.html_safe, :style => "margin-left: 15px;")
			val << link_to_project(element)
		else
			val << '&nbsp;'
		end
		val.html_safe
	end
	
	def render_time_entry_errors(errors)
		val = []
		errors.full_messages.each do |m|
			val << content_tag("li", m)
		end
		content_tag("div",  content_tag("ul", val.join("").html_safe).html_safe, :id => "errorExplanation").html_safe
	end
	
	def render_time_entry_errors_alert(errors)
		val = []
		errors.full_messages.each do |m|
			val << " - #{m}"
		end
		"alert('#{val.join("")}');"
	end
	
	def valid_date(date)
		if date.nil?
		false
		else
			begin
			   Date.parse(date)
			rescue ArgumentError
			   false
			end
		end
	end
	
	def users_report_to_csv(data)
		encoding = l(:general_csv_encoding)
		columns = [ l(:field_user), l(:field_project), l(:field_center_costs), l(:label_report_estimated_hours), l(:label_report_hours), l(:label_report_billing_hours)] 
		labeled_columns = Array.new
		columns.each do |col|
			labeled_columns << Redmine::CodesetUtil.from_utf8(col, encoding)
		end
		FCSV.generate(:col_sep => l(:general_csv_separator)) do |csv|
			csv << labeled_columns
			data.each do |val|
				values = []
				next if val[:type] == :user
				values << Redmine::CodesetUtil.from_utf8(val[:user_name], encoding)
				values << Redmine::CodesetUtil.from_utf8(val[:link].name, encoding)
				values << Redmine::CodesetUtil.from_utf8(val[:link].root.name, encoding)
				values << Redmine::CodesetUtil.from_utf8(val[:total_estimated_hours].to_s, encoding)
				values << Redmine::CodesetUtil.from_utf8(val[:total_hours].to_s, encoding)
				values << Redmine::CodesetUtil.from_utf8(val[:total_billing_hours].to_s, encoding)
				csv << values
			end
		end
	end
	
	def projects_report_to_csv(data)
		encoding = l(:general_csv_encoding)
		columns = [l(:field_center_costs), l(:field_project), l(:label_report_estimated_hours), l(:label_report_hours), l(:label_report_billing_hours)] 
		labeled_columns = Array.new
		columns.each do |col|
			labeled_columns << Redmine::CodesetUtil.from_utf8(col, encoding)
		end
		FCSV.generate(:col_sep => l(:general_csv_separator)) do |csv|
			csv << labeled_columns
			data.each do |val|
				values = []
				next if val[:type] == :parent
				values << Redmine::CodesetUtil.from_utf8(val[:link].root.name, encoding)
				values << Redmine::CodesetUtil.from_utf8(val[:link].name, encoding)
				values << Redmine::CodesetUtil.from_utf8(val[:total_estimated_hours].to_s, encoding)
				values << Redmine::CodesetUtil.from_utf8(val[:total_hours].to_s, encoding)
				values << Redmine::CodesetUtil.from_utf8(val[:total_billing_hours].to_s, encoding)
				csv << values
			end
		end
	end

	def options_from_project_filter(projects, selected)
		data = ''
		project_tree(@projects) do |project, level|
			lft = '>' * level
			disabled = (project.descendants.size == 0) ? '' : 'disabled'
			if ! selected.nil? && selected.include?(project.id.to_s)
				data << "<option value='#{project.id}' selected #{disabled}>#{lft} #{project.name}</option>"
			else
				data << "<option value='#{project.id}' #{disabled}>#{lft} #{project.name}</option>"
			end
		end
		data.html_safe
	end
end
