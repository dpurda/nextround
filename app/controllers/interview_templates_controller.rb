class InterviewTemplatesController < ApplicationController
  before_action :set_interview_template, only: %i[show edit update destroy]

  def index
    authorize InterviewTemplate
    @q = policy_scope(InterviewTemplate).ransack(params[:q])
    @q.sorts = "name asc" if @q.sorts.empty?

    @pagy, @interview_templates = pagy(@q.result.includes(:created_by, :template_questions))
  end

  def show
    authorize @interview_template
  end

  def new
    @interview_template = InterviewTemplate.new
    @interview_template.template_questions.build
    authorize @interview_template
  end

  def create
    @interview_template = InterviewTemplate.new(interview_template_params)
    @interview_template.created_by = current_user
    authorize @interview_template

    if @interview_template.save
      redirect_to @interview_template, notice: "Template created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize @interview_template
  end

  def update
    authorize @interview_template

    if @interview_template.update(interview_template_params)
      redirect_to @interview_template, notice: "Template updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @interview_template
    @interview_template.destroy
    redirect_to interview_templates_path, notice: "Template deleted."
  end

  private

  def set_interview_template
    @interview_template = InterviewTemplate.find(params[:id])
  end

  def interview_template_params
    params.require(:interview_template).permit(
      :name, :description, :interview_type,
      template_questions_attributes: %i[id prompt _destroy]
    )
  end
end
