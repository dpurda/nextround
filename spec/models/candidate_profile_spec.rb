require "rails_helper"

RSpec.describe CandidateProfile, type: :model do
  it "has a valid factory" do
    expect(build(:candidate_profile)).to be_valid
  end

  %i[phone current_role target_role education location].each do |attribute|
    it "requires #{attribute}" do
      profile = build(:candidate_profile, attribute => nil)
      expect(profile).not_to be_valid
      expect(profile.errors[attribute]).to be_present
    end
  end

  it "does not require work_experience" do
    profile = build(:candidate_profile, work_experience: nil)
    expect(profile).to be_valid
  end

  it "only allows one profile per user" do
    existing = create(:candidate_profile)
    duplicate = build(:candidate_profile, user: existing.user)
    expect(duplicate).not_to be_valid
  end

  it "requires the owning user to have the candidate role" do
    interviewer = create(:user, :interviewer)
    profile = build(:candidate_profile, user: interviewer)
    expect(profile).not_to be_valid
    expect(profile.errors[:user]).to be_present
  end
end
