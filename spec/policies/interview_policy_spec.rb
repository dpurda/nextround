require "rails_helper"

RSpec.describe InterviewPolicy do
  describe "#index?" do
    it "is true for every role" do
      expect(described_class.new(build(:user, :admin), Interview).index?).to be(true)
      expect(described_class.new(build(:user, :interviewer), Interview).index?).to be(true)
      expect(described_class.new(build(:user, :candidate), Interview).index?).to be(true)
    end
  end

  describe "#show?" do
    it "allows the interviewer who owns it, the candidate on it, and any admin" do
      interview = create(:interview)

      expect(described_class.new(interview.interviewer, interview).show?).to be(true)
      expect(described_class.new(interview.candidate, interview).show?).to be(true)
      expect(described_class.new(build(:user, :admin), interview).show?).to be(true)
    end

    it "does not allow an unrelated interviewer or candidate" do
      interview = create(:interview)

      expect(described_class.new(build(:user, :interviewer), interview).show?).to be(false)
      expect(described_class.new(build(:user, :candidate), interview).show?).to be(false)
    end
  end

  describe "#create?" do
    it "allows admins and interviewers, not candidates" do
      expect(described_class.new(build(:user, :admin), Interview.new).create?).to be(true)
      expect(described_class.new(build(:user, :interviewer), Interview.new).create?).to be(true)
      expect(described_class.new(build(:user, :candidate), Interview.new).create?).to be(false)
    end
  end

  describe "#update?" do
    it "allows the owning interviewer and any admin, not a different interviewer or the candidate" do
      interview = create(:interview)

      expect(described_class.new(interview.interviewer, interview).update?).to be(true)
      expect(described_class.new(build(:user, :admin), interview).update?).to be(true)
      expect(described_class.new(build(:user, :interviewer), interview).update?).to be(false)
      expect(described_class.new(interview.candidate, interview).update?).to be(false)
    end
  end

  describe "Scope" do
    it "resolves to everything for an admin" do
      interview = create(:interview)
      resolved = described_class::Scope.new(build(:user, :admin), Interview).resolve
      expect(resolved).to include(interview)
    end

    it "resolves to only their own interviews for an interviewer" do
      mine = create(:interview)
      other = create(:interview)

      resolved = described_class::Scope.new(mine.interviewer, Interview).resolve

      expect(resolved).to include(mine)
      expect(resolved).not_to include(other)
    end

    it "resolves to only their own interviews for a candidate" do
      mine = create(:interview)
      other = create(:interview)

      resolved = described_class::Scope.new(mine.candidate, Interview).resolve

      expect(resolved).to include(mine)
      expect(resolved).not_to include(other)
    end
  end
end
