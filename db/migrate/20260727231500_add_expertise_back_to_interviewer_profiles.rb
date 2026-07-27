class AddExpertiseBackToInterviewerProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :interviewer_profiles, :expertise, :text
  end
end
