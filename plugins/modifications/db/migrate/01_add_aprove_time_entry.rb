class AddAproveTimeEntry < ActiveRecord::Migration
	def self.up
		# commented because the model have this fields
		#add_column  :time_entries, :revised,			:boolean,  :null => false, :default => 0
		#add_column 	:time_entries, :billing_hours,      :float,    :null => true
		#add_column  :time_entries, :billing_comment, 	:text,	   :null => true
		#add_column  :issues, 	   :non_billable_hours, :boolean,  :null => false, :default => 0
	end
end

