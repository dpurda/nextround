module ApplicationHelper
  def new_profile_path_for(user)
    if user.candidate?
      new_candidate_profile_path
    elsif user.interviewer?
      new_interviewer_profile_path
    end
  end

  def profile_path_for(user)
    if user.candidate?
      candidate_profile_path
    elsif user.interviewer?
      interviewer_profile_path
    end
  end
end
