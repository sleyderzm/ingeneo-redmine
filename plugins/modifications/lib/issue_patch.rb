module IssuePatch
	def self.included(base)
		base.send(:include, InstanceMethods)
		base.class_eval do
			safe_attributes 'non_billable_hours',
											:if => lambda {|issue, user| issue.new_record? || user.allowed_to?(:edit_issues, issue.project) }
		end

		def spent_billing_hours
			@spent_billing_hours ||= time_entries.sum(:billing_hours) || 0
		end
	end
	module InstanceMethods
	end
end
