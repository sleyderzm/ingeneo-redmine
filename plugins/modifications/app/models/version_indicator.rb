class VersionIndicator

  attr_accessor :version, :issues, :maxdate, :mindate, :expected, :realized, :fulfillmen, :all_hours, :total_hours, :project_id

  def initialize(id, project_id)
    @version = Version.where(:id => id).first
    @issues = nil
    @maxdate = nil
    @mindate = nil
    @expected = 0
    @realized = 0
    @fulfillmen = 0
    @total_hours = 0
    @all_hours = 0
    @project_id = project_id
    self.issues_from_data(id)
    self.get_data
  end

  def get_data
    today = Date.today
    expected_value = 0

    self.total_hours = self.get_hours(self.version.id)
    self.issues.each do |issue|
      # Si la fecha inicial es mayor a la fecha actual devuevle 0
      expected_value = start_m_today if !issue['start_date'].nil?  && issue['start_date'].to_s > today.to_s
      # si hoy es mayor a la fecha fin.
      if (!issue['due_date'].nil?  && !issue['start_date'].nil?)  && issue['due_date'].to_s <= today.to_s
        expected_value = today_m_due_day
      elsif issue['start_date'].to_s <= today.to_s && today.to_s < issue['due_date'].to_s
        expected_value = star_mto_to_mto_due(issue, today)
      end
      if self.total_hours.to_f > 0
        self.expected += ((issue['estimated_hours'].to_f/self.total_hours.to_f) * expected_value.to_f).round(2)
        self.realized += ((issue['estimated_hours'].to_f/self.total_hours.to_f) * issue['done_ratio'].to_i).round(2)
      end
    end



    self.expected = 100 if self.expected> 100
    self.realized = 100 if self.realized> 100
    self.expected = self.expected_version(@mindate, @maxdate, today)

    #self.realized = @version.completed_percent
    self.realized = self.completed_percent
    #Modificado Ingeneo Sin esta validación se genera un internal error
    self.expected = 1 if self.expected.to_f.nan?
    self.realized = 0 if self.realized.to_f.nan?
    self.fulfillmen = ((self.realized/self.expected)*100).to_f.round(2) if self.expected > 0
    self.fulfillmen = 100 if self.fulfillmen > 100

    self.all_hours = TimeEntry.joins(:issue).where("#{Issue.table_name}.fixed_version_id = ? AND time_entries.project_id = ? AND non_billable_hours = 0", self.version.id, self.project_id).sum(:hours).to_f.round(2)


  end



  def get_hours(version_id)
    0 + Issue.where(:project_id => self.project_id, :fixed_version_id => version_id, :non_billable_hours => 0)
            .sum(:estimated_hours)
  end

  def issues_from_data(version_id)
    @issues = Issue.where(:fixed_version_id => version_id, :project_id => self.project_id, :non_billable_hours => 0)
    @maxdate = @issues.maximum(:due_date)
    @mindate = @issues.minimum(:start_date)
  end

  def business_days(from, to)
    return 0 if from.nil? || to.nil?
    value = 0
    non_working_week_days = Setting.non_working_week_days
    while from <= to
      day = from.to_date.strftime("%u")
      if ! non_working_week_days.include?(day)
        value += 1
      end
      from = from + 1.day
    end
    value
  end

  def expected_version(date_start, date_end, today)

    @planned_day = business_days(date_start, date_end)
    @today_days = business_days(date_start, today)
    @planned_day = @planned_day
    @today_days = @today_days.to_f
    @planned_day = @planned_day.to_f

    expected_value = ((@today_days/@planned_day)*100.0).round(2)
    if  expected_value > 100
      expected_value = 100
    end

    return expected_value

  end

  def star_mto_to_mto_due(issue, today)
    @planned_day = business_days(issue['start_date'],issue['due_date'])
    @today_days = business_days(issue['start_date'], today)
    @planned_day = @planned_day.to_s
    @planned_day = @planned_day.to_i
    @planned_day = @planned_day
    @today_days = @today_days.to_s
    @today_days = @today_days.to_i
    @today_days = @today_days
    expected_value = ((@today_days.to_f/@planned_day.to_f)*100).round(2)
    if  expected_value > 100
      expected_value = 100
    end

    return expected_value
  end

  def start_m_today
    return 0
  end

  def today_m_due_day
    return 100
  end

  def estimated_average
    average = self.version.fixed_issues.where("non_billable_hours = 0").average(:estimated_hours).to_f
    if average == 0
      average = 1
    end
    estimated_average = average
  end

  def issues_count
    Issue.where(:fixed_version_id => self.version.id, :non_billable_hours => 0).size
  end

  def issues_progress(open)
    progress = 0
    if issues_count > 0
      ratio = open ? 'done_ratio' : 100

      done = self.version.fixed_issues.where("non_billable_hours = 0").open(open).sum("COALESCE(estimated_hours, #{estimated_average}) * #{ratio}").to_f
      progress = done / (estimated_average * issues_count)
    end
  end

  def open_issues_count
    open_issues_count = 0
    self.version.fixed_issues.where("non_billable_hours = 0").group(:status).count.each do |status, count|
      if ! status.is_closed?
        open_issues_count += count
      end
    end
    open_issues_count
  end

  def completed_percent
    issues = Issue.where(:fixed_version_id => self.version.id, :non_billable_hours => 0)
    if issues.size == 0
      0
    elsif open_issues_count == 0
      100
    else
      issues_progress(false) + issues_progress(true)
    end
  end
end
