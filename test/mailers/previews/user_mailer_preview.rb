# frozen_string_literal: true

# Allows emails to be viewed at /rails/mailers
class UserMailerPreview < ActionMailer::Preview
  def reviewer_digest
    user = User.first
    UserMailer.reviewer_digest(user)
  end

  def daua_approved
    agreement = Agreement.first
    admin = User.first
    UserMailer.daua_approved(agreement, admin)
  end

  def daua_progress_notification
    agreement = Agreement.first
    agreement_event = agreement.agreement_events.last
    admin = User.first
    UserMailer.daua_progress_notification(agreement, admin, agreement_event)
  end

  def daua_submitted
    agreement = Agreement.first
    admin = User.first
    UserMailer.daua_submitted(admin, agreement)
  end

  def sent_back_for_resubmission
    agreement = Agreement.first
    admin = User.first
    UserMailer.sent_back_for_resubmission(agreement, admin)
  end

  def mentioned_in_agreement_comment
    user = User.first
    agreement_event = AgreementEvent.find_by(event_type: "commented")
    UserMailer.mentioned_in_agreement_comment(agreement_event, user)
  end
end
