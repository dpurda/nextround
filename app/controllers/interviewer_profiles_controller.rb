class InterviewerProfilesController < ApplicationController
  before_action :set_interviewer_profile

  def show
    authorize @interviewer_profile
    redirect_to new_interviewer_profile_path unless @interviewer_profile.persisted?
  end

  def new
    authorize @interviewer_profile
    redirect_to edit_interviewer_profile_path if @interviewer_profile.persisted?
  end

  def create
    authorize @interviewer_profile
    @interviewer_profile.assign_attributes(interviewer_profile_params)

    if @interviewer_profile.save
      redirect_to root_path, notice: "Profile saved."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize @interviewer_profile
    render :new
  end

  def update
    authorize @interviewer_profile

    if @interviewer_profile.update(interviewer_profile_params)
      redirect_to root_path, notice: "Profile updated."
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def set_interviewer_profile
    @interviewer_profile = current_user.interviewer_profile || current_user.build_interviewer_profile
  end

  def interviewer_profile_params
    params.require(:interviewer_profile).permit(:expertise, :years_of_experience, :company, :title, :bio)
  end
end
