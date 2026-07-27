class InterviewsController < ApplicationController
  before_action :set_interview, only: %i[show edit update update_status]
  before_action :load_form_collections, only: %i[new create edit update]

  def index
    @interviews = policy_scope(Interview).includes(:interviewer, :candidate, :feedback).order(scheduled_at: :desc)
  end

  def show
    authorize @interview
  end

  def new
    @interview = Interview.new
    authorize @interview
  end

  def create
    @interview = Interview.new(interview_params)
    authorize @interview

    if @interview.save
      redirect_to @interview, notice: "Interview created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize @interview
  end

  def update
    authorize @interview

    if @interview.update(interview_params)
      redirect_to @interview, notice: "Interview updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def update_status
    authorize @interview, :update?

    if @interview.update(status: params.dig(:interview, :status))
      redirect_back fallback_location: interviews_path, notice: "Status updated."
    else
      redirect_back fallback_location: interviews_path, alert: @interview.errors.full_messages.to_sentence
    end
  end

  private

  def set_interview
    @interview = Interview.find(params[:id])
  end

  def load_form_collections
    @candidates = User.candidate.order(:email)
    @interviewers = current_user.admin? ? User.interviewer.order(:email) : []
  end

  def interview_params
    permitted = params.require(:interview).permit(
      :title, :interview_type, :status, :scheduled_at, :duration_minutes, :candidate_id, :interviewer_id
    )
    permitted[:interviewer_id] = current_user.id if current_user.interviewer?
    permitted
  end
end
