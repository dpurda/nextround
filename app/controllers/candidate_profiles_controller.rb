class CandidateProfilesController < ApplicationController
  before_action :set_candidate_profile

  def show
    authorize @candidate_profile
    redirect_to new_candidate_profile_path unless @candidate_profile.persisted?
  end

  def new
    authorize @candidate_profile
    redirect_to edit_candidate_profile_path if @candidate_profile.persisted?
  end

  def create
    authorize @candidate_profile
    @candidate_profile.assign_attributes(candidate_profile_params)

    if @candidate_profile.save
      redirect_to root_path, notice: "Profile saved."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize @candidate_profile
    render :new
  end

  def update
    authorize @candidate_profile

    if @candidate_profile.update(candidate_profile_params)
      redirect_to root_path, notice: "Profile updated."
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def set_candidate_profile
    @candidate_profile = current_user.candidate_profile || current_user.build_candidate_profile
  end

  def candidate_profile_params
    params.require(:candidate_profile).permit(
      :phone, :current_role, :target_role, :years_of_experience,
      :education, :location, :work_experience, :bio
    )
  end
end
