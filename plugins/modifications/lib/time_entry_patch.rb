module TimeEntryPatch
	def self.included(base) # :nodoc:
		base.send(:include, InstanceMethods)
		base.class_eval do
			validates_presence_of :comments # Comentarios Obligatorios
			validates_presence_of :issue_id # Numero de la peticion obligatorio
			validates_numericality_of :billing_hours, :allow_nil => true, :message => :invalid
			safe_attributes 'revised',
											'billing_hours',
											'billing_comment'
		end
	end

	module InstanceMethods
	end
end