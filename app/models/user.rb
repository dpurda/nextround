class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable, :omniauthable, :recoverable
  #
  # :registerable is intentionally omitted — there is no public signup route.
  # Every account is created via an invite (see #invite!) and activated via
  # the /claim flow. :recoverable is omitted too since there's no outbound
  # email to deliver a password reset link.
  devise :database_authenticatable, :rememberable, :validatable

  enum :role, { candidate: 0, interviewer: 1, admin: 2 }, default: :candidate

  INVITATION_CODE_LENGTH = 16
  INVITATION_EXPIRY = 7.days

  belongs_to :invited_by, class_name: "User", optional: true
  has_many :invited_users, class_name: "User", foreign_key: :invited_by_id, dependent: :nullify

  has_one :candidate_profile, dependent: :destroy
  has_one :interviewer_profile, dependent: :destroy

  has_many :interviews_as_candidate, class_name: "Interview", foreign_key: :candidate_id, dependent: :destroy
  has_many :interviews_as_interviewer, class_name: "Interview", foreign_key: :interviewer_id, dependent: :destroy

  validates :name, presence: true, unless: :pending_invitation?

  before_validation :generate_invitation_code, on: :create, if: :pending_invitation?

  # Invite creation never goes through a controller-submitted password, so
  # Devise's normal "password required on create" validation is skipped
  # while the account is still pending. Once claimed (password set), normal
  # Devise validation applies to any future password change.
  def password_required?
    return false if pending_invitation?

    super
  end

  def pending_invitation?
    claimed_at.nil?
  end

  def invitation_code_expired?
    invitation_code_generated_at.nil? || invitation_code_generated_at < INVITATION_EXPIRY.ago
  end

  def claim!(name:, password:, password_confirmation:)
    update(
      name: name,
      password: password,
      password_confirmation: password_confirmation,
      claimed_at: Time.current,
      invitation_code: nil,
      invitation_code_generated_at: nil
    )
  end

  def profile
    candidate? ? candidate_profile : (interviewer? ? interviewer_profile : nil)
  end

  def profile_complete?
    admin? || profile.present?
  end

  class << self
    def find_by_valid_invitation_code(code)
      user = find_by(invitation_code: code, claimed_at: nil)
      return nil if user.nil? || user.invitation_code_expired?

      user
    end
  end

  private

  def generate_invitation_code
    self.invitation_code_generated_at ||= Time.current
    loop do
      self.invitation_code = SecureRandom.random_number(10**INVITATION_CODE_LENGTH).to_s.rjust(INVITATION_CODE_LENGTH, "0")
      break unless User.exists?(invitation_code: invitation_code)
    end
  end
end
