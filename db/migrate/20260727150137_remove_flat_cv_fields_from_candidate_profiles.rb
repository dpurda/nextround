class RemoveFlatCvFieldsFromCandidateProfiles < ActiveRecord::Migration[8.0]
  def change
    remove_column :candidate_profiles, :education, :string
    remove_column :candidate_profiles, :work_experience, :text
  end
end
