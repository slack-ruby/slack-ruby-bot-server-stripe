require_relative 'activerecord'

ActiveRecord::Schema.define do
  self.verbose = false

  create_table :teams, force: true do |t|
    t.string :stripe_customer_id
    t.boolean :subscribed, default: false
  end
end
