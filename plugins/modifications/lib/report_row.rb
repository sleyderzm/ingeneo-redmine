class ReportRow 
	attr_accessor :centro_costos, :proyecto, :usuario, :total_horas_estimadas, :total_horas_ejecutadas, :total_horas_facturadas 
	def initialize(options)
		@centro_costos = options[:centro_costos]
		@proyecto = options[:proyecto]
		@usuario = options[:usuario]
		@total_horas_estimadas = options[:total_horas_estimadas]
		@total_horas_ejecutadas = options[:total_horas_ejecutadas]
		@total_horas_facturadas = options[:total_horas_facturadas]
	end
end