class InvitesController < ApplicationController
  before_action :set_invited_user, only: :show

  def index
    authorize User
    @q = policy_scope(User).ransack(params[:q])
    @q.sorts = "created_at desc" if @q.sorts.empty?

    @pagy, @invited_users = pagy(@q.result)
  end

  def new
    @invited_user = User.new
    authorize @invited_user
  end

  def create
    @invited_user = User.new(invite_params)
    authorize @invited_user

    if @invited_user.save
      @invited_user.update!(invited_by: current_user)
      redirect_to invite_path(@invited_user), notice: "Invitation created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def show
    authorize @invited_user
  end

  private

  def set_invited_user
    @invited_user = User.find(params[:id])
  end

  def invite_params
    params.require(:user).permit(:email, :role)
  end
end
