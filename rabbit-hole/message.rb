class Message < ActiveRecord::Base
  include MessageSender

  after_save :remember_if_we_went_live_during_this_save
  after_commit :start_sending, :if => :went_live_during_last_save

  def remember_if_we_went_live_during_this_save
    @went_live_during_last_save = changed_to_live?
  end

  def changed_to_live?
    state_changed? && state == 'live'
  end

  def auto_message_filter_description
    filters.to_s
  end

  def live?
    state == 'live'
  end

  def draft?
    state == 'draft'
  end

  # Report expired messages as 'stopped' instead of 'live
  def consolidated_state
    expired? ? 'stopped' : state
  end

  def manual?
    self.subclass_type == "ManualMessage"
  end

  def auto_message?
    self.subclass_type == "AutoMessage"
  end

  def expired?
    display_until.present? && display_until.end_of_day.past?
  end

end
