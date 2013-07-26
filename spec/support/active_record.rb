require 'active_record'
# require 'rspec/rails/extensions/active_record/base'

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

ActiveRecord::Migration.create_table :messages do |t|
  t.boolean :allowed_to_send
  t.timestamps
end

ActiveRecord::Migration.create_table :users do |t|
  t.string :email, :default => "test@test.com" # added for test purpose
  t.boolean :unsubscribed, :default => false
  t.integer :group_id
  t.timestamps
end

ActiveRecord::Migration.create_table :groups do |t|
  t.string :name
  t.timestamps
end

ActiveRecord::Migration.create_table :emails do |t|
  t.text :body
  t.integer :user_id
  t.integer :message_id
  t.timestamps
end
