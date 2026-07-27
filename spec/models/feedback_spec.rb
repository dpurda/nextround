require "rails_helper"

RSpec.describe Feedback, type: :model do
  it "has a valid factory" do
    expect(build(:feedback)).to be_valid
  end

  %i[strengths improvements].each do |attribute|
    it "requires #{attribute}" do
      feedback = build(:feedback, attribute => nil)
      expect(feedback).not_to be_valid
      expect(feedback.errors[attribute]).to be_present
    end
  end

  it "requires a recommendation" do
    feedback = build(:feedback)
    feedback.recommendation = nil
    expect(feedback).not_to be_valid
  end

  it "requires overall_rating to be between 1 and 5" do
    expect(build(:feedback, overall_rating: 0)).not_to be_valid
    expect(build(:feedback, overall_rating: 6)).not_to be_valid
    expect(build(:feedback, overall_rating: 3)).to be_valid
  end

  it "only allows one feedback per interview" do
    interview = create(:interview)
    create(:feedback, interview: interview)
    duplicate = build(:feedback, interview: interview)
    expect(duplicate).not_to be_valid
  end
end
