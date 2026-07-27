require "rails_helper"

RSpec.describe InterviewerProfilePolicy do
  describe "#show?" do
    it "allows the owning interviewer and an admin, but not others" do
      profile = create(:interviewer_profile)
      expect(described_class.new(profile.user, profile).show?).to be(true)
      expect(described_class.new(build(:user, :admin), profile).show?).to be(true)
      expect(described_class.new(build(:user, :interviewer), profile).show?).to be(false)
    end
  end

  describe "#create? / #update?" do
    it "allows an interviewer to manage their own profile" do
      interviewer = build(:user, :interviewer)
      profile = interviewer.build_interviewer_profile
      expect(described_class.new(interviewer, profile).create?).to be(true)
      expect(described_class.new(interviewer, profile).update?).to be(true)
    end

    it "does not allow an interviewer to manage someone else's profile" do
      interviewer = build(:user, :interviewer)
      other_profile = create(:interviewer_profile)
      expect(described_class.new(interviewer, other_profile).create?).to be(false)
    end

    it "does not allow a candidate to manage an interviewer profile" do
      candidate = build(:user, :candidate)
      profile = build(:interviewer_profile)
      expect(described_class.new(candidate, profile).create?).to be(false)
    end

    it "allows an admin to manage any interviewer profile" do
      admin = build(:user, :admin)
      profile = create(:interviewer_profile)
      expect(described_class.new(admin, profile).create?).to be(true)
      expect(described_class.new(admin, profile).update?).to be(true)
    end
  end
end
