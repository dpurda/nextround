require "rails_helper"

RSpec.describe "db/seeds.rb" do
  def run_seeds
    load Rails.root.join("db/seeds.rb")
  end

  it "creates a claimed admin user that can log in" do
    run_seeds

    admin = User.find_by(email: "admin@nextround.test")
    expect(admin).to be_present
    expect(admin).to be_admin
    expect(admin).not_to be_pending_invitation
    expect(admin.valid_password?("password123")).to be(true)
  end

  it "is idempotent" do
    run_seeds
    run_seeds

    expect(User.where(email: "admin@nextround.test").count).to eq(1)
  end
end
