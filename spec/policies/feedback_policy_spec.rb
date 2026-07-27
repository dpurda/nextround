require "rails_helper"

RSpec.describe FeedbackPolicy do
  describe "#create? / #update?" do
    it "allows the owning interviewer" do
      interview = create(:interview)
      feedback = Feedback.new(interview: interview)

      expect(described_class.new(interview.interviewer, feedback).create?).to be(true)
      expect(described_class.new(interview.interviewer, feedback).update?).to be(true)
    end

    it "allows an admin" do
      interview = create(:interview)
      feedback = Feedback.new(interview: interview)

      expect(described_class.new(build(:user, :admin), feedback).create?).to be(true)
    end

    it "does not allow a different interviewer" do
      interview = create(:interview)
      feedback = Feedback.new(interview: interview)

      expect(described_class.new(build(:user, :interviewer), feedback).create?).to be(false)
    end

    it "does not allow the candidate on the interview" do
      interview = create(:interview)
      feedback = Feedback.new(interview: interview)

      expect(described_class.new(interview.candidate, feedback).create?).to be(false)
    end
  end
end
