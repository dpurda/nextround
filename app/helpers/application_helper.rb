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
      "scheduled" => "win-badge-neutral",
      "in_progress" => "win-badge-warning",
      "completed" => "win-badge-success",
      "cancelled" => "win-badge-error"
    }.fetch(status.to_s, "win-badge-neutral")
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
    link_to PENCIL_ICON, path, class: "win-icon-btn", aria: { label: label }, title: label
  end

  # Lucide "plus" icon, used for every "create new X" action instead of a
  # text button, so they all look identical regardless of what's being created.
  PLUS_ICON = <<~SVG.html_safe
    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none"
         stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <line x1="12" y1="5" x2="12" y2="19"/>
      <line x1="5" y1="12" x2="19" y2="12"/>
    </svg>
  SVG

  def icon_add_button(path, label:)
    link_to PLUS_ICON, path, class: "win-icon-btn-primary", aria: { label: label }, title: label
  end
end
