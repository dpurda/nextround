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

  def status_badge_class(status)
    {
      "scheduled" => "bg-slate-100 text-slate-700",
      "in_progress" => "bg-amber-100 text-amber-800",
      "completed" => "bg-emerald-100 text-emerald-800",
      "cancelled" => "bg-red-100 text-red-800"
    }.fetch(status.to_s, "bg-slate-100 text-slate-700")
  end

  def user_display_name(user)
    user.name.presence || user.email
  end
end
