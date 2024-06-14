class RecurringTask < ApplicationRecord
  validates :name, presence: true
  validates :schedule, presence: true

  # Returns true if the task should be scheduled today
  def scheduled_today?
    schedule_array = schedule.split(',')
    today = Date.today
    (schedule_array.include?(today.strftime('%A').downcase) ||
      (schedule_array.include?('workday') && (1..5).include?(today.wday)) ||
      (schedule_array.include?('weekend') && [0, 6].include?(today.wday)))
  end

  # Initialize log if not present
  def initialize_log
    self.log ||= {}
  end

  # Mark the task as done for today
  def done_for_today!
    initialize_log
    log[Date.today.to_s] = true
    save
  end
  
  # Check if the task was done for today
  def done_for_today?
    initialize_log
    log[Date.today.to_s] == true
  end
end