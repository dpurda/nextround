require "rails_helper"

RSpec.describe InterviewTemplatePolicy do
  describe "#index? / #show? / #create?" do
    it "allows any interviewer and any admin" do
      expect(described_class.new(build(:user, :interviewer), InterviewTemplate).index?).to be(true)
      expect(described_class.new(build(:user, :admin), InterviewTemplate).index?).to be(true)
    end

    it "does not allow a candidate" do
      expect(described_class.new(build(:user, :candidate), InterviewTemplate).index?).to be(false)
    end
  end

  describe "#update? / #destroy?" do
    it "allows the creator and any admin" do
      template = create(:interview_template)

      expect(described_class.new(template.created_by, template).update?).to be(true)
      expect(described_class.new(build(:user, :admin), template).update?).to be(true)
    end

    it "does not allow a different interviewer or a candidate" do
      template = create(:interview_template)

      expect(described_class.new(build(:user, :interviewer), template).update?).to be(false)
      expect(described_class.new(build(:user, :candidate), template).update?).to be(false)
    end
  end

  describe "Scope" do
    it "resolves to everything for admin and interviewer (shared question bank)" do
      template = create(:interview_template)

      expect(described_class::Scope.new(build(:user, :admin), InterviewTemplate).resolve).to include(template)
      expect(described_class::Scope.new(build(:user, :interviewer), InterviewTemplate).resolve).to include(template)
    end

    it "resolves to nothing for a candidate" do
      create(:interview_template)
      expect(described_class::Scope.new(build(:user, :candidate), InterviewTemplate).resolve).to be_empty
    end
  end
end
