require "rails_helper"

RSpec.describe "db/seeds.rb" do
  def run_seeds
    load Rails.root.join("db/seeds.rb")
  end

  it "creates a claimed admin user that can log in" do
    run_seeds

    admin = User.find_by(email: "admin@nextround.test")
    expect(admin).to be_present
    expect(admin).to be_admin
    expect(admin).not_to be_pending_invitation
    expect(admin.valid_password?("password123")).to be(true)
  end

  it "is idempotent" do
    run_seeds
    run_seeds

    expect(User.where(email: "admin@nextround.test").count).to eq(1)
  end

  describe "demo data (normally skipped in test env)" do
    before { allow(Rails.env).to receive(:test?).and_return(false) }

    it "generates interviewers, candidates, and interviews with a sensible invite lineage" do
      expect { run_seeds }.to change(Interview, :count).by(100)

      expect(User.interviewer.count).to eq(5)
      expect(User.candidate.count).to eq(20)
      expect(CandidateProfile.count).to eq(20)
      expect(InterviewerProfile.count).to eq(5)
      expect(Feedback.count).to be > 0
      expect(Feedback.count).to eq(Interview.completed.count)

      admin = User.find_by(email: "admin@nextround.test")
      expect(User.interviewer.where(invited_by: admin).count).to eq(5)
      expect(User.candidate.where.not(invited_by: nil).count).to eq(20)
    end

    it "does not duplicate demo data on a second run" do
      run_seeds
      expect { run_seeds }.not_to change(Interview, :count)
    end
  end
end
