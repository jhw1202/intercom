require_relative 'spec/support/active_record.rb'
require 'pry'

class Message < ActiveRecord::Base

  attr_accessor :allowed_to_send

  def send_message_to_group(group_id)
    # guard clause: don't run any code if message isn't allowed to be sent at all
    return false if self.allowed_to_send == false

    group = Group.find(group_id)
    users = group.users

    # no need to check for existence of group since activerecord raises error if invalid group_id
    if users.any?
      users.each do |user|
        send_email_to_user(user)
      end
    end

  end

  # extract out user email/unsubscribed check and actual email creation
  def send_email_to_user(user)
    if user.email && user.unsubscribed == false
      Email.create(:user_id => user.id, :message_id => self.id).deliver
    end
  end
end

################################################################

class User < ActiveRecord::Base

  attr_accessor :email, :unsubscribed, :group_id

  belongs_to :group

end

################################################################

class Group < ActiveRecord::Base

  has_many :users

end

###############################################################

class Email < ActiveRecord::Base

  validates_presence_of :user_id, :message_id

  def deliver
    ### ... send the email ... ###
  end
end
