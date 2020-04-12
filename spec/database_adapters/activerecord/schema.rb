require_relative 'activerecord'

ActiveRecord::Schema.define do
  self.verbose = false

  create_table :teams, force: true do |t|
    t.string :stripe_customer_id
    t.boolean :subscribed, default: false
    t.timestamp :subscribed_at
    t.timestamp :subscription_expired_at
    t.timestamp :trial_informed_at
  end
end
