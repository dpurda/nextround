require "rails_helper"

RSpec.describe WorkExperience, type: :model do
  it "has a valid factory" do
    expect(build(:work_experience)).to be_valid
  end

  %i[company title start_date].each do |attribute|
    it "requires #{attribute}" do
      work_experience = build(:work_experience, attribute => nil)
      expect(work_experience).not_to be_valid
      expect(work_experience.errors[attribute]).to be_present
    end
  end

  it "does not require an end_date (still current)" do
    expect(build(:work_experience, end_date: nil)).to be_valid
  end

  it "is invalid when end_date is before start_date" do
    work_experience = build(:work_experience, start_date: Date.new(2020, 1, 1), end_date: Date.new(2019, 1, 1))
    expect(work_experience).not_to be_valid
    expect(work_experience.errors[:end_date]).to be_present
  end

  describe "#current?" do
    it "is true when there is no end_date" do
      expect(build(:work_experience, end_date: nil)).to be_current
    end

    it "is false once an end_date is set" do
      expect(build(:work_experience, end_date: Date.current)).not_to be_current
    end
  end

  describe ".ordered" do
    it "orders by start_date descending (most recent first)" do
      older = create(:work_experience, start_date: 5.years.ago.to_date)
      newer = create(:work_experience, candidate_profile: older.candidate_profile, start_date: 1.year.ago.to_date)

      expect(WorkExperience.ordered).to eq([ newer, older ])
    end
  end
end
