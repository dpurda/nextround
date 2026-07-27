require "rails_helper"

RSpec.describe InterviewerProfile, type: :model do
  it "has a valid factory" do
    expect(build(:interviewer_profile)).to be_valid
  end

  %i[expertise company title].each do |attribute|
    it "requires #{attribute}" do
      profile = build(:interviewer_profile, attribute => nil)
      expect(profile).not_to be_valid
      expect(profile.errors[attribute]).to be_present
    end
  end

  it "only allows one profile per user" do
    existing = create(:interviewer_profile)
    duplicate = build(:interviewer_profile, user: existing.user)
    expect(duplicate).not_to be_valid
  end

  it "requires the owning user to have the interviewer role" do
    candidate = create(:user, :candidate)
    profile = build(:interviewer_profile, user: candidate)
    expect(profile).not_to be_valid
    expect(profile.errors[:user]).to be_present
  end
end
