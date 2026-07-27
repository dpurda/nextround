require "rails_helper"

RSpec.describe Education, type: :model do
  it "has a valid factory" do
    expect(build(:education)).to be_valid
  end

  %i[institution degree start_date].each do |attribute|
    it "requires #{attribute}" do
      education = build(:education, attribute => nil)
      expect(education).not_to be_valid
      expect(education.errors[attribute]).to be_present
    end
  end

  it "does not require field_of_study or end_date" do
    expect(build(:education, field_of_study: nil, end_date: nil)).to be_valid
  end

  it "is invalid when end_date is before start_date" do
    education = build(:education, start_date: Date.new(2020, 1, 1), end_date: Date.new(2019, 1, 1))
    expect(education).not_to be_valid
    expect(education.errors[:end_date]).to be_present
  end

  describe ".ordered" do
    it "orders by start_date descending (most recent first)" do
      older = create(:education, start_date: 10.years.ago.to_date)
      newer = create(:education, candidate_profile: older.candidate_profile, start_date: 4.years.ago.to_date)

      expect(Education.ordered).to eq([ newer, older ])
    end
  end
end
