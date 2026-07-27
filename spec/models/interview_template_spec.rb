require "rails_helper"

RSpec.describe InterviewTemplate, type: :model do
  it "has a valid factory" do
    expect(build(:interview_template)).to be_valid
  end

  it "requires a name" do
    template = build(:interview_template, name: nil)
    expect(template).not_to be_valid
    expect(template.errors[:name]).to be_present
  end

  describe "nested template_questions" do
    it "accepts nested question attributes" do
      template = create(:interview_template)
      template.update(template_questions_attributes: [ { prompt: "New question" } ])
      expect(template.template_questions.map(&:prompt)).to include("New question")
    end

    it "rejects a blank nested question row" do
      template = create(:interview_template)
      expect do
        template.update(template_questions_attributes: [ { prompt: "" } ])
      end.not_to change(template.template_questions, :count)
    end

    it "destroys its template_questions when the template is destroyed" do
      question = create(:template_question)
      template = question.interview_template

      template.destroy

      expect(TemplateQuestion.exists?(question.id)).to be(false)
    end
  end

  describe "when destroyed" do
    it "nullifies interview_template_id on interviews created from it, without touching their already-copied questions" do
      template = create(:interview_template)
      create(:template_question, interview_template: template)
      interview = create(:interview, interview_template: template)
      expect(interview.interview_questions.count).to eq(1)

      template.destroy
      interview.reload

      expect(interview.interview_template_id).to be_nil
      expect(interview.interview_questions.count).to eq(1)
    end
  end
end
