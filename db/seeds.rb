# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

admin_email = ENV.fetch("NEXTROUND_ADMIN_EMAIL", "admin@nextround.test")
admin_password = ENV.fetch("NEXTROUND_ADMIN_PASSWORD", "password123")

admin = User.find_or_initialize_by(email: admin_email)
admin.assign_attributes(
  name: "NextRound Admin",
  role: :admin,
  claimed_at: admin.claimed_at || Time.current,
  password: admin_password,
  password_confirmation: admin_password
)
admin.save!

puts "Admin ready: #{admin_email} / #{admin_password}" unless Rails.env.test?
