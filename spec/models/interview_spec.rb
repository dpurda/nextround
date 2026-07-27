require "rails_helper"

RSpec.describe Interview, type: :model do
  it "has a valid factory" do
    expect(build(:interview)).to be_valid
  end

  it "requires a title" do
    interview = build(:interview, title: nil)
    expect(interview).not_to be_valid
  end

  it "requires the interviewer to have the interviewer role" do
    candidate_as_interviewer = create(:user, :candidate)
    interview = build(:interview, interviewer: candidate_as_interviewer)
    expect(interview).not_to be_valid
    expect(interview.errors[:interviewer]).to be_present
  end

  it "requires the candidate to have the candidate role" do
    interviewer_as_candidate = create(:user, :interviewer)
    interview = build(:interview, candidate: interviewer_as_candidate)
    expect(interview).not_to be_valid
    expect(interview.errors[:candidate]).to be_present
  end

  describe "completing an interview" do
    it "cannot be completed without feedback" do
      interview = create(:interview, status: :scheduled)
      interview.status = :completed
      expect(interview).not_to be_valid
      expect(interview.errors[:status]).to be_present
    end

    it "can be completed once feedback exists" do
      interview = create(:interview, status: :scheduled)
      create(:feedback, interview: interview)
      interview.reload.status = :completed
      expect(interview).to be_valid
    end
  end

  describe "creating from a template" do
    it "copies the template's questions onto the interview" do
      template = create(:interview_template)
      create(:template_question, interview_template: template, prompt: "Q1")
      create(:template_question, interview_template: template, prompt: "Q2")

      interview = create(:interview, interview_template: template)

      expect(interview.interview_questions.pluck(:prompt)).to contain_exactly("Q1", "Q2")
    end

    it "leaves interview_questions empty when no template is used" do
      interview = create(:interview)
      expect(interview.interview_questions).to be_empty
    end
  end
end
