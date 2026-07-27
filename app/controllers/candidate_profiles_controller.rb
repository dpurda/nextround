class CandidateProfilesController < ApplicationController
  before_action :set_candidate_profile

  def show
    authorize @candidate_profile
    redirect_to new_candidate_profile_path unless @candidate_profile.persisted?
  end

  def new
    authorize @candidate_profile
    return redirect_to edit_candidate_profile_path if @candidate_profile.persisted?

    build_blank_entries
  end

  def create
    authorize @candidate_profile
    @candidate_profile.assign_attributes(candidate_profile_params)

    if @candidate_profile.save
      redirect_to root_path, notice: "Profile saved."
    else
      build_blank_entries
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize @candidate_profile
    build_blank_entries
    render :new
  end

  def update
    authorize @candidate_profile

    if @candidate_profile.update(candidate_profile_params)
      redirect_to root_path, notice: "Profile updated."
    else
      build_blank_entries
      render :new, status: :unprocessable_content
    end
  end

  private

  def set_candidate_profile
    @candidate_profile = current_user.candidate_profile || current_user.build_candidate_profile
  end

  # Always keep one blank row available in the form so there's somewhere to
  # type a new entry, in addition to whatever's already been saved.
  def build_blank_entries
    @candidate_profile.work_experiences.build
    @candidate_profile.educations.build
  end

  def candidate_profile_params
    params.require(:candidate_profile).permit(
      :phone, :current_role, :target_role, :years_of_experience, :location, :bio,
      work_experiences_attributes: %i[id company title start_date end_date description _destroy],
      educations_attributes: %i[id institution degree field_of_study start_date end_date _destroy]
    )
  end
end
