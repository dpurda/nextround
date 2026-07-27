class FeedbacksController < ApplicationController
  before_action :set_interview
  before_action :set_feedback, only: %i[edit update]

  def new
    @feedback = @interview.build_feedback
    authorize @feedback
  end

  def create
    @feedback = @interview.build_feedback(feedback_params)
    authorize @feedback

    if @feedback.save
      redirect_to @interview, notice: "Feedback saved."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize @feedback
  end

  def update
    authorize @feedback

    if @feedback.update(feedback_params)
      redirect_to @interview, notice: "Feedback updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_interview
    @interview = Interview.find(params[:interview_id])
  end

  def set_feedback
    @feedback = @interview.feedback
  end

  def feedback_params
    params.require(:feedback).permit(:strengths, :improvements, :recommendation, :overall_rating, :notes)
  end
end
