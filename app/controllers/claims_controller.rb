class ClaimsController < ApplicationController
  skip_before_action :authenticate_user!

  def new
  end

  def create
    user = User.find_by_valid_invitation_code(params[:invitation_code])

    if user.nil?
      flash.now[:alert] = "That invitation code is invalid or has expired."
      render :new, status: :unprocessable_content
      return
    end

    if user.claim!(name: params[:name], password: params[:password], password_confirmation: params[:password_confirmation])
      sign_in(user)
      redirect_to post_claim_path_for(user), notice: "Welcome to NextRound! Let's finish setting up your profile."
    else
      @user = user
      render :new, status: :unprocessable_content
    end
  end

  private

  def post_claim_path_for(user)
    if user.candidate?
      new_candidate_profile_path
    elsif user.interviewer?
      new_interviewer_profile_path
    else
      root_path
    end
  end
end
