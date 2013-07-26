module MessageSender

  def start_sending
    # Does some other stuff...
    send_message
  end

  def add_to_message_ids(*user_ids)
    user_ids.each_slice(1000) do |chunk_of_user_ids|
      app.user_klass.add_to_set(*chunk_of_user_ids, {:message_ids => id}, {:safe => true})
    end
  end

  def add_message_to_users_inboxes(users)
    user_ids = []
    users.fields(:id).find_each {|u| user_ids << u.id }
    Metrics.increment("Conversation.message.add_message_to_users_inbox_new.count")
    Metrics.timing("Conversation.message.add_message_to_users_inbox_new.timing") do
      user_ids.each_slice(10000) do |user_ids_slice|
        inbox_messages = user_ids_slice.map do |uid|
          Conversation.new(:app_id => app_id, :message_id => id, :user_id => uid.to_s, :message_type => message_type)
        end
        Conversation.fast_safe_import(inbox_messages)
      end
    end
  end

  def notify_those_concerned
    notify_users
    split_test.set_initial_stats if has_split_test?
  end

  ###
  ## Notifying Users
  ###
  def notify_users
    if email?
      send_emails
    else
      notify_online_users_immediately
    end
  end

  def email_to(user_id)
    return if !(user = app.users.find(user_id)) || read_marks.where(:user_id => user.to_param).count != 0
    ob = OutboundEmail.create(:mailable => self, :app_id => app_id, :user_id => user.to_param)
    if ob.present? && ob.success
      Metrics.increment("Conversation.message.email_to.add_to_set.count")
      Metrics.timing("Conversation.message.email_to.add_to_set.timing") do
        add_to_message_ids(user.id)
      end
      add_message_to_users_inboxes_new([user_id])
    end
  end

  def queue_websocket_notification(user)
    MessageSplitTest.log("#{user.class.to_s} #{user.to_json.to_s}", [user.log_tag, "QUEUE_WEBSOCKET_NOTIFICATION"]) if has_split_test?
    WebsocketNotifierWorker.perform_async(self.class.to_s, id, user.to_param, app_id) if ok_to_send_if_split_tested?(user)
  end

  def notify_connected_user(user)
    Rails.logger.info("Pushing message to user: #{user.id} #{id}")
    user.websocket_channel.trigger_if_user_online('new_message', :message => API::MessagePresenter.js_api_hash(self, user))
  end

  ###
  ## Recording message sends
  ###
  def record_message_send_for_multiple_users(user_ids)
    user_ids.each { |user_id| record_message_sent_to_user(user_id) }
  end

  def record_message_sent_to_user(user_id)
    return unless ok_to_send_if_split_tested?(app.users.find(user_id))
    send_to_statsd_with_rails_env(parent.admin_message_metric_name)
    MessageEvent.create_if_not_exists 'sent', parent, user_id, Time.now
  end

end
