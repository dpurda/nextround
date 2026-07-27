class InterviewQuestionsController < ApplicationController
  before_action :set_interview
  before_action :set_interview_question

  def edit
    authorize @interview_question
  end

  def update
    authorize @interview_question

    if @interview_question.update(interview_question_params)
      respond_to do |format|
        format.html { redirect_to @interview }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            helpers.dom_id(@interview_question), partial: "interview_questions/question_row", locals: { question: @interview_question }
          )
        end
      end
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_interview
    @interview = Interview.find(params[:interview_id])
  end

  def set_interview_question
    @interview_question = @interview.interview_questions.find(params[:id])
  end

  def interview_question_params
    params.require(:interview_question).permit(:covered, :notes)
  end
end
