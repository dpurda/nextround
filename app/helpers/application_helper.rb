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

  # Lucide "pencil" icon, used for every inline edit/add action so they all
  # look identical regardless of what they edit.
  PENCIL_ICON = <<~SVG.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none"
         stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z"/>
      <path d="m15 5 4 4"/>
    </svg>
  SVG

  def icon_edit_button(path, label:)
    link_to PENCIL_ICON, path,
      class: "inline-flex items-center justify-center rounded-md p-1.5 text-slate-500 hover:bg-slate-100 hover:text-indigo-600",
      aria: { label: label }, title: label
  end
end
