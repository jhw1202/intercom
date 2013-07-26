class Message

  attr_accessor :allowed_to_send

  def send_message_to_group(group_id)
    group = Group.find group_id
    if !group.nil? && group.users.count > 0
      users = User.where(:group_id => group_id)
      users.each do |user|
        if user.email_address.present? && user.unsubscribed == false
          if self.allowed_to_send == true
            Email.create(:user_id => user.id, :message_id => self.id).deliver
          end
        end
      end
    end
  end

end

################################################################

class User

  attr_accessor :email_address, :unsubscribed, :group_id

  belongs_to :group

end

################################################################

class Group

  has_many :users

end

###############################################################

class Email

  validates_presence_of :user_id, :message_id

  def deliver
    ### ... send the email ... ###
  end
end