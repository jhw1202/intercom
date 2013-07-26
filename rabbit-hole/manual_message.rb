class ManualMessage < Message
  before_create :set_targeted_users_for_tests

  def set_targeted_users_for_tests
    if @users_to_target.present?
      params[:targeted_users] ||= @users_to_target.inject({}){|h, user| h[user.id.to_s] = 1; h}
    end
  end

  # see http://stackoverflow.com/questions/4507149/best-practices-to-handle-routes-for-sti-subclasses-in-rails
  def self.model_name
    Message.model_name
  end

  def send_message
    add_message_to_users_inboxes(users_to_target)
    notify_those_concerned
  end

  def send_emails
    users.each_with_index do |user, index|
      for_user(user).each do |message|
        message.email_to(user.to_param)
      end
    end
  end

  def notify_online_users_immediately
    users.where(:online => true).find_each do |user|
      queue_websocket_notification(user)
    end
  end

  def populate_targeted_users
    original_params = params.with_indifferent_access
    has_targeted_users = original_params[:targeted_users] && (original_params[:targeted_users].length > 0)
    is_bulk = original_params[:bulk] && (original_params[:bulk] != 'false')
    targeted_users = nil
    if is_bulk
      targeted_users = (original_params[:filters].present?) ? app.users_from_raw_filters(original_params[:filters]) : app.users
      targeted_users = targeted_users.where(Filter.search_query(original_params[:search]))

      if has_targeted_users
        user_ids = original_params[:targeted_users].keys
        targeted_users = targeted_users.where(:id => {:$nin => user_ids})
      end
    elsif has_targeted_users
      targeted_users = app.users.where(:id => original_params[:targeted_users].keys)
    end
    targeted_users
  end

  def users_to_target
    @users_to_target || populate_targeted_users
  end

  def intended_recipients
    users_to_target || app.users.where(:id => '-1')
  end

end
