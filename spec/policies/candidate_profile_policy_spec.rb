require "rails_helper"

RSpec.describe CandidateProfilePolicy do
  describe "#show?" do
    it "allows the owning candidate and an admin, but not others" do
      profile = create(:candidate_profile)
      expect(described_class.new(profile.user, profile).show?).to be(true)
      expect(described_class.new(build(:user, :admin), profile).show?).to be(true)
      expect(described_class.new(build(:user, :candidate), profile).show?).to be(false)
    end
  end

  describe "#create? / #update?" do
    it "allows a candidate to manage their own profile" do
      candidate = build(:user, :candidate)
      profile = candidate.build_candidate_profile
      expect(described_class.new(candidate, profile).create?).to be(true)
      expect(described_class.new(candidate, profile).update?).to be(true)
    end

    it "does not allow a candidate to manage someone else's profile" do
      candidate = build(:user, :candidate)
      other_profile = create(:candidate_profile)
      expect(described_class.new(candidate, other_profile).create?).to be(false)
    end

    it "does not allow an interviewer to manage a candidate profile" do
      interviewer = build(:user, :interviewer)
      profile = build(:candidate_profile)
      expect(described_class.new(interviewer, profile).create?).to be(false)
    end

    it "allows an admin to manage any candidate profile" do
      admin = build(:user, :admin)
      profile = create(:candidate_profile)
      expect(described_class.new(admin, profile).create?).to be(true)
      expect(described_class.new(admin, profile).update?).to be(true)
    end
  end
end
