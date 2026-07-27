require "rails_helper"

RSpec.describe CandidateProfile, type: :model do
  it "has a valid factory" do
    expect(build(:candidate_profile)).to be_valid
  end

  %i[phone current_role target_role location].each do |attribute|
    it "requires #{attribute}" do
      profile = build(:candidate_profile, attribute => nil)
      expect(profile).not_to be_valid
      expect(profile.errors[attribute]).to be_present
    end
  end

  it "does not require a bio" do
    expect(build(:candidate_profile, bio: nil)).to be_valid
  end

  it "does not require any work experience or education entries" do
    profile = build(:candidate_profile)
    expect(profile.work_experiences).to be_empty
    expect(profile.educations).to be_empty
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

  describe "nested work experience/education attributes" do
    it "creates associated entries via nested attributes" do
      profile = create(:candidate_profile)

      profile.update!(
        work_experiences_attributes: [ { company: "Acme", title: "Engineer", start_date: 1.year.ago.to_date } ],
        educations_attributes: [ { institution: "MIT", degree: "BS", start_date: 5.years.ago.to_date } ]
      )

      expect(profile.work_experiences.reload.count).to eq(1)
      expect(profile.educations.reload.count).to eq(1)
    end

    it "discards entirely blank nested entries instead of raising validation errors" do
      profile = build(:candidate_profile)

      profile.assign_attributes(
        work_experiences_attributes: [ { company: "", title: "", start_date: "" } ],
        educations_attributes: [ { institution: "", degree: "", start_date: "" } ]
      )

      expect(profile).to be_valid
      expect(profile.work_experiences).to be_empty
      expect(profile.educations).to be_empty
    end

    it "destroys an entry when _destroy is set" do
      profile = create(:candidate_profile, :with_cv_entries)
      work_experience = profile.work_experiences.first

      profile.update!(work_experiences_attributes: [ { id: work_experience.id, _destroy: "1" } ])

      expect(profile.work_experiences.reload).not_to include(work_experience)
    end
  end
end
