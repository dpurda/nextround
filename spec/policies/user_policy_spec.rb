require "rails_helper"

RSpec.describe UserPolicy do
  describe "#invitable_roles" do
    it "lets admins invite interviewers or candidates" do
      admin = build(:user, :admin)
      expect(described_class.new(admin, User.new).invitable_roles).to contain_exactly(:interviewer, :candidate)
    end

    it "lets interviewers invite only candidates" do
      interviewer = build(:user, :interviewer)
      expect(described_class.new(interviewer, User.new).invitable_roles).to contain_exactly(:candidate)
    end

    it "does not let candidates invite anyone" do
      candidate = build(:user, :candidate)
      expect(described_class.new(candidate, User.new).invitable_roles).to be_empty
    end
  end

  describe "#new?" do
    it "is true for admins and interviewers, false for candidates" do
      expect(described_class.new(build(:user, :admin), User.new).new?).to be(true)
      expect(described_class.new(build(:user, :interviewer), User.new).new?).to be(true)
      expect(described_class.new(build(:user, :candidate), User.new).new?).to be(false)
    end
  end

  describe "#create?" do
    it "allows an interviewer to invite a candidate but not an interviewer" do
      interviewer = build(:user, :interviewer)
      expect(described_class.new(interviewer, User.new(role: :candidate)).create?).to be(true)
      expect(described_class.new(interviewer, User.new(role: :interviewer)).create?).to be(false)
    end

    it "allows an admin to invite either role" do
      admin = build(:user, :admin)
      expect(described_class.new(admin, User.new(role: :candidate)).create?).to be(true)
      expect(described_class.new(admin, User.new(role: :interviewer)).create?).to be(true)
    end
  end

  describe "#index?" do
    it "is true for admin and interviewer, false for candidate" do
      expect(described_class.new(build(:user, :admin), User).index?).to be(true)
      expect(described_class.new(build(:user, :interviewer), User).index?).to be(true)
      expect(described_class.new(build(:user, :candidate), User).index?).to be(false)
    end
  end

  describe "Scope" do
    it "resolves to every invited user for an admin" do
      interviewer = create(:user, :interviewer)
      invited = create(:user, :pending_invitation, email: "invitee@example.com", invited_by: interviewer)

      resolved = described_class::Scope.new(build(:user, :admin), User).resolve

      expect(resolved).to include(invited)
    end

    it "resolves to only their own invites for an interviewer" do
      interviewer = create(:user, :interviewer)
      mine = create(:user, :pending_invitation, email: "mine@example.com", invited_by: interviewer)
      not_mine = create(:user, :pending_invitation, email: "notmine@example.com", invited_by: create(:user, :interviewer))

      resolved = described_class::Scope.new(interviewer, User).resolve

      expect(resolved).to include(mine)
      expect(resolved).not_to include(not_mine)
    end

    it "resolves to nothing for a candidate" do
      create(:user, :pending_invitation, email: "invitee@example.com", invited_by: create(:user, :interviewer))

      resolved = described_class::Scope.new(build(:user, :candidate), User).resolve

      expect(resolved).to be_empty
    end
  end

  describe "#show?" do
    it "allows the inviter to view their own invite" do
      interviewer = create(:user, :interviewer)
      invited = create(:user, :pending_invitation, email: "invitee@example.com", invited_by: interviewer)
      expect(described_class.new(interviewer, invited).show?).to be(true)
    end

    it "allows an admin to view any invite" do
      other_interviewer = create(:user, :interviewer)
      invited = create(:user, :pending_invitation, email: "invitee@example.com", invited_by: other_interviewer)
      expect(described_class.new(build(:user, :admin), invited).show?).to be(true)
    end

    it "does not allow a different interviewer to view someone else's invite" do
      inviter = create(:user, :interviewer)
      other = create(:user, :interviewer)
      invited = create(:user, :pending_invitation, email: "invitee@example.com", invited_by: inviter)
      expect(described_class.new(other, invited).show?).to be(false)
    end
  end
end
