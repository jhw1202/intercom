class AutoMessage < Message
  before_save :clean_auto_message_filters

  # see http://stackoverflow.com/questions/4507149/best-practices-to-handle-routes-for-sti-subclasses-in-rails
  def self.model_name
    Message.model_name
  end

  def send_message
    notify_those_concerned
  end

  def deliverable_immediately?
    !email? && !page_targeted?
  end

  def send_emails
    index = 0
    users_to_email.find_each do |user|
      priority = (index >= BULK_EMAIL_PRIORITY_LIMIT ? :throttle : :low)
      MessageSplitTest.log("#{user.class.to_s} #{user.to_json.to_s}", [user.log_tag, "SEND_AUTO_EMAIL"]) if has_split_test?
      send_auto_email_to_user(user, priority) if ok_to_send_if_split_tested?(user)
      index += 1
    end
  end

  def notify_online_users_immediately
    return unless deliverable_immediately?
    add_message_to_users_inboxes(users_matching_filters.where(:online => true))
    users_matching_filters.where(:online => true).find_each do |user|
      queue_websocket_notification(user)
    end
  end

  def clean_attributes
    unless use_page_targetting
      self.page_target_type = 0
      self.page_target_string = nil
    end
    super
  end

  def send_auto_email_to_user(user, priority=:low)
    messages_for_user = for_user(user, :skip_user_match_check => true)
    user.add_messages_to_inbox(messages_for_user)
    messages_for_user.each { |m| m.sidekiq_async :email_to, priority, user.to_param }
  end

  def init
    self.state ||= "draft"
  end

  def disable_page_targetting_if_target_string_blank
    self.page_target_type = 0 if page_target_string.blank?
  end

  def page_target_exact?
    self.page_target_type == 1
  end

  def page_target_contains?
    self.page_target_type == 2
  end

  def page_target_regex?
    self.page_target_type == 3
  end

  def users_to_email
    newly_matching_users.where(:unsubscribed_from_emails => false)
  end

  def newly_matching_users
    users_matching_filters.where(:message_ids => {:$not => {:$all => [id]}})
  end

end
