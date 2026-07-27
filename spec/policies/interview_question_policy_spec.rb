require "rails_helper"

RSpec.describe InterviewQuestionPolicy do
  describe "#update?" do
    it "allows the owning interviewer and any admin" do
      interview = create(:interview)
      question = create(:interview_question, interview: interview)

      expect(described_class.new(interview.interviewer, question).update?).to be(true)
      expect(described_class.new(build(:user, :admin), question).update?).to be(true)
    end

    it "allows the candidate being interviewed, to submit their answer" do
      interview = create(:interview)
      question = create(:interview_question, interview: interview)

      expect(described_class.new(interview.candidate, question).update?).to be(true)
    end

    it "does not allow an unrelated interviewer or an unrelated candidate" do
      interview = create(:interview)
      question = create(:interview_question, interview: interview)

      expect(described_class.new(build(:user, :interviewer), question).update?).to be(false)
      expect(described_class.new(build(:user, :candidate), question).update?).to be(false)
    end

    it "no longer allows the candidate once they've already answered" do
      interview = create(:interview)
      question = create(:interview_question, interview: interview, answer: "already answered")

      expect(described_class.new(interview.candidate, question).update?).to be(false)
    end

    it "still allows the owning interviewer and admin to edit covered/notes after the candidate has answered" do
      interview = create(:interview)
      question = create(:interview_question, interview: interview, answer: "already answered")

      expect(described_class.new(interview.interviewer, question).update?).to be(true)
      expect(described_class.new(build(:user, :admin), question).update?).to be(true)
    end
  end
end
