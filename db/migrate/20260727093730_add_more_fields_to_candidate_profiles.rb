class AddMoreFieldsToCandidateProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :candidate_profiles, :education, :string
    add_column :candidate_profiles, :location, :string
    add_column :candidate_profiles, :work_experience, :text
  end
end
