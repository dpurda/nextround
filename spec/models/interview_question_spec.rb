require "rails_helper"

RSpec.describe InterviewQuestion, type: :model do
  it "has a valid factory" do
    expect(build(:interview_question)).to be_valid
  end

  it "requires a prompt" do
    question = build(:interview_question, prompt: nil)
    expect(question).not_to be_valid
    expect(question.errors[:prompt]).to be_present
  end

  describe "#start_interview_on_first_answer" do
    it "moves a scheduled interview to in_progress once an answer is submitted" do
      interview = create(:interview, status: :scheduled)
      question = create(:interview_question, interview: interview)

      question.update(answer: "My answer")

      expect(interview.reload.status).to eq("in_progress")
    end

    it "does not move a cancelled interview back to in_progress" do
      interview = create(:interview, status: :cancelled)
      question = create(:interview_question, interview: interview)

      question.update(answer: "My answer")

      expect(interview.reload.status).to eq("cancelled")
    end

    it "does not fire when a field other than answer changes" do
      interview = create(:interview, status: :scheduled)
      question = create(:interview_question, interview: interview)

      question.update(covered: true)

      expect(interview.reload.status).to eq("scheduled")
    end
  end
end
