class DashboardController < ApplicationController
  def show
    @interviews = policy_scope(Interview)
    @total_count = @interviews.count
    @completed_count = @interviews.completed.count
    @completion_rate = @total_count.zero? ? 0 : ((@completed_count * 100.0) / @total_count).round

    @status_counts = ordered_counts(@interviews.group(:status).count, Interview.statuses.keys)

    feedback_scope = Feedback.joins(:interview).merge(@interviews)
    @recommendation_counts = ordered_counts(feedback_scope.group(:recommendation).count, Feedback.recommendations.keys)

    @weekly_interview_counts = @interviews.group_by_week(:scheduled_at, last: 8).count
    @weekly_average_rating = feedback_scope.group_by_week("feedbacks.created_at", last: 8).average(:overall_rating)
  end

  private

  # Re-orders a { label => count } hash (whose order depends on SQL/DB
  # internals) into a fixed, deterministic order matching the enum
  # definition — including zero-count keys — so a fixed `colors:` array in
  # the view always lines up with the same label at the same position,
  # instead of a color meant for one status silently landing on another
  # once some status has zero interviews and drops out of the hash.
  def ordered_counts(counts, ordered_keys)
    ordered_keys.index_with { |key| counts[key].to_i }.transform_keys(&:humanize)
  end
end
