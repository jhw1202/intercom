require 'rspec'
require 'support/active_record'
require_relative '../3-refactor.rb'


describe Message do
  let(:valid_message) { Message.new(allowed_to_send: true)}
  let(:invalid_message) { Message.new(allowed_to_send: false)}
  let(:group) { Group.create }
  let(:user) { User.create }

  context "send_messages_to_group method" do

    it "should have send_message_to_group method" do
      Message.new.should respond_to :send_message_to_group
    end

    it "should not send message if allowed_to_send is false" do
      invalid_message.send_message_to_group(1).should eq false
    end

    it "should raise RecordNotFound if invalid group id is given" do
      expect {valid_message.send_message_to_group(10)}
                                               .to raise_error ActiveRecord::RecordNotFound
    end

  end

  context "sending messages" do

    it "should create and deliver email" do
      user.email = "test@test.com"
      user.unsubscribed = false
      valid_message.send_email_to_user(user)
    end

  end

end

