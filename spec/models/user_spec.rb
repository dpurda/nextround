require "rails_helper"

RSpec.describe User, type: :model do
  it "defaults to the candidate role" do
    expect(User.new.role).to eq("candidate")
  end

  describe "invite creation" do
    subject(:invited_user) { create(:user, :pending_invitation, email: "invitee@example.com") }

    it "does not require a password" do
      expect(invited_user).to be_valid
    end

    it "generates a unique 16-digit invitation code" do
      expect(invited_user.invitation_code).to match(/\A\d{16}\z/)
    end

    it "is pending until claimed" do
      expect(invited_user).to be_pending_invitation
    end

    it "cannot authenticate before being claimed" do
      expect(invited_user.valid_password?("anything")).to be(false)
    end
  end

  describe ".find_by_valid_invitation_code" do
    let!(:invited_user) { create(:user, :pending_invitation, email: "invitee@example.com") }

    it "finds a pending user by their code" do
      expect(User.find_by_valid_invitation_code(invited_user.invitation_code)).to eq(invited_user)
    end

    it "returns nil for an unknown code" do
      expect(User.find_by_valid_invitation_code("0000000000000000")).to be_nil
    end

    it "returns nil for an expired code" do
      invited_user.update_column(:invitation_code_generated_at, 8.days.ago)
      expect(User.find_by_valid_invitation_code(invited_user.invitation_code)).to be_nil
    end

    it "returns nil once the code has already been claimed" do
      invited_user.claim!(name: "Claimed", password: "password123", password_confirmation: "password123")
      expect(User.find_by_valid_invitation_code(invited_user.invitation_code)).to be_nil
    end
  end

  describe "#claim!" do
    let(:invited_user) { create(:user, :pending_invitation, email: "invitee@example.com") }

    it "activates the account and clears the invitation code" do
      invited_user.claim!(name: "Jane Candidate", password: "password123", password_confirmation: "password123")

      expect(invited_user).not_to be_pending_invitation
      expect(invited_user.invitation_code).to be_nil
      expect(invited_user.valid_password?("password123")).to be(true)
    end

    it "requires a name and password once claiming" do
      expect(invited_user.claim!(name: "", password: "", password_confirmation: "")).to be(false)
    end
  end

  describe "#profile" do
    it "returns the candidate_profile for a candidate" do
      profile = create(:candidate_profile)
      expect(profile.user.profile).to eq(profile)
    end

    it "returns the interviewer_profile for an interviewer" do
      profile = create(:interviewer_profile)
      expect(profile.user.profile).to eq(profile)
    end
  end

  describe "#profile_complete?" do
    it "is true for admins regardless of profile" do
      expect(create(:user, :admin).profile_complete?).to be(true)
    end

    it "is false for a candidate with no profile yet" do
      expect(create(:user, :candidate).profile_complete?).to be(false)
    end

    it "is true once a candidate has a profile" do
      profile = create(:candidate_profile)
      expect(profile.user.profile_complete?).to be(true)
    end
  end
end
