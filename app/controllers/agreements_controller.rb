class AgreementsController < ApplicationController
  prepend_before_filter only: [ :signature_requested, :duly_authorized_representative_submit_signature, :signature_submitted ] { request.env["devise.skip_timeout"] = true }
  skip_before_action :verify_authenticity_token, only: [ :signature_requested, :duly_authorized_representative_submit_signature, :signature_submitted ]

  before_action :authenticate_user!,             except: [ :signature_requested, :duly_authorized_representative_submit_signature, :signature_submitted ]
  before_action :check_system_admin,             except: [ :signature_requested, :duly_authorized_representative_submit_signature, :signature_submitted, :renew, :daua, :dua, :create_step, :step, :update_step, :proof, :final_submission, :destroy_submission, :submissions, :welcome, :download_irb, :print, :complete, :new_step, :irb_assistance_template ]

  before_action :set_viewable_submission,        only: [ :renew, :complete ]
  before_action :set_editable_submission,        only: [ :step, :update_step, :proof, :final_submission, :destroy_submission ]
  before_action :redirect_without_submission,    only: [ :step, :update_step, :proof, :final_submission, :destroy_submission, :renew, :complete ]
  before_action :set_step,                       only: [ :create_step, :step, :update_step ]

  before_action :set_downloadable_irb_agreement, only: [ :download_irb, :print ]
  before_action :set_agreement,                  only: [ :show, :destroy, :download, :review, :update ]
  before_action :redirect_without_agreement,     only: [ :show, :destroy, :download, :review, :update, :download_irb, :print ]

  def signature_requested
    @agreement = Agreement.current.where(id: params[:id], status: [nil, '', 'started', 'resubmit']).find_by_duly_authorized_representative_token(params[:duly_authorized_representative_token]) unless params[:duly_authorized_representative_token].blank?
    @step = 6
    unless @agreement
      redirect_to root_path, alert: 'Agreement has been locked.'
    end
  end

  def duly_authorized_representative_submit_signature
    @agreement = Agreement.current.where(id: params[:id], status: [nil, '', 'started', 'resubmit']).find_by_duly_authorized_representative_token(params[:duly_authorized_representative_token]) unless params[:duly_authorized_representative_token].blank?
    @step = 6
    if @agreement
      if AgreementTransaction.save_agreement!(@agreement, duly_authorized_params, current_user, request.remote_ip, 'public_agreement_update')
        @agreement.update_column :current_step, 6
        @agreement.send_daua_signed_email!
        redirect_to signature_submitted_agreements_path
      else
        render 'signature_requested'
      end
    else
      redirect_to root_path, alert: 'Agreement has been locked.'
    end
  end

  def signature_submitted

  end

  def submissions
    @agreements = current_user.agreements.page(params[:page]).per( 40 )
    redirect_to submissions_welcome_path if @agreements.count == 0
  end

  def step
    if @step and @step > 0 and @step < 10
      render "agreements/wizard/step#{@step}"
    else
      redirect_to step_agreement_path(@agreement, step: 1)
    end
  end

  def new_step
    @step = 1
    @agreement = current_user.agreements.new( data_user: current_user.name )
    render "agreements/wizard/step#{@step}"
  end

  def renew
    @step = 1
    @agreement = current_user.agreements.create( @agreement.copyable_attributes )
    render "agreements/wizard/step#{@step}"
  end

  # POST /agreements
  def create_step
    @agreement = current_user.agreements.new(step_params)

    if AgreementTransaction.save_agreement!(@agreement, step_params, current_user, request.remote_ip, 'agreement_create')
      if @agreement.draft_mode?
        redirect_to submissions_path
      else
        redirect_to step_agreement_path(@agreement, step: 2)
      end
    else
      render "agreements/wizard/step#{@step}"
    end

  end

  def update_step
    if AgreementTransaction.save_agreement!(@agreement, step_params, current_user, request.remote_ip, 'agreement_update')
      if @agreement.draft_mode?
        redirect_to submissions_path
      elsif @agreement.fully_filled_out? or (@agreement.current_step == 7 and @agreement.has_irb_evidence?) or @agreement.current_step == 8
        redirect_to proof_agreement_path(@agreement)
      else
        redirect_to step_agreement_path(@agreement, step: @agreement.current_step + 1)
      end
    elsif @step
      render "agreements/wizard/step#{@step}"
    else
      redirect_to submissions_path
    end
  end

  def proof
  end

  def final_submission
    current_time = Time.now
    if @agreement.status == 'resubmit'
      hash = { status: 'submitted', resubmitted_at: current_time, last_submitted_at: current_time }
      msg = "Data Access and Use Agreement resubmitted."
      event_type = 'user_resubmitted'
    else
      hash = { status: 'submitted', submitted_at: current_time, last_submitted_at: current_time }
      msg = "Data Access and Use Agreement submitted."
      event_type = 'user_submitted'
    end

    if not @agreement.fully_filled_out?
      render 'proof'
    elsif AgreementTransaction.save_agreement!(@agreement, hash, current_user, request.remote_ip, 'agreement_update')
      @agreement.add_event!(msg, current_user, 'submitted')
      @agreement.agreement_events.create event_type: event_type, user_id: current_user.id, event_at: current_time
      @agreement.daua_submitted
      redirect_to complete_agreement_path(@agreement)
    else
      redirect_to submissions_path
    end
  end

  # GET /agreements
  # GET /agreements.json
  def index
    params[:order] = "agreements.last_submitted_at DESC" if params[:order].blank?
    @order = scrub_order(Agreement, params[:order], [:id])
    agreement_scope = Agreement.current.search(params[:search]).order(@order)
    agreement_scope = agreement_scope.with_tag(params[:tag_id]) if params[:tag_id].present?
    if params[:status] == 'started'
      agreement_scope = agreement_scope.where( status: nil )
    elsif params[:status].present?
      agreement_scope = agreement_scope.where( status: params[:status] )
    end
    if params[:user_type] == 'regular'
      regular_member_ids = User.current.where( aug_member: false, core_member: false ).pluck(:id)
      agreement_scope = agreement_scope.where( user_id: regular_member_ids )
    end
    @agreements = agreement_scope.page(params[:page]).per( 40 )
  end

  # GET /agreements/1
  # GET /agreements/1.json
  def show
  end

  # # GET /agreements/new
  # def new
  #   @agreement = Agreement.new
  # end

  # # GET /agreements/1/edit
  # def edit
  # end

  # This is the "edit action"
  # GET /agreements/1/review
  def review
  end

  # PATCH /agreements/1
  def update
    original_status = @agreement.status
    if AgreementTransaction.save_agreement!(@agreement, agreement_review_params, current_user, request.remote_ip, 'agreement_update')
      if original_status != 'approved' and @agreement.status == 'approved'
        @agreement.daua_approved_email(current_user)
      elsif original_status != 'resubmit' and @agreement.status == 'resubmit'
        @agreement.sent_back_for_resubmission_email(current_user)
      end
      redirect_to review_path(@agreement) + "#c#{@agreement.agreement_events.last.number}", notice: 'Agreement was successfully updated.'
    else
      render 'reviews/show'
    end
  end

  def download_irb
    send_file File.join(CarrierWave::Uploader::Base.root, @agreement.irb.url), disposition: 'inline'
  end

  def print
    @agreement.generate_printed_pdf!
    if @agreement.printed_file.size > 0
      send_file File.join( CarrierWave::Uploader::Base.root, @agreement.printed_file.url ), filename: "#{@agreement.user.last_name.gsub(/[^a-zA-Z\p{L}]/, '')}-#{@agreement.user.first_name.gsub(/[^a-zA-Z\p{L}]/, '')}-#{@agreement.agreement_number}-DAUA-#{(@agreement.submitted_at || @agreement.created_at).strftime("%Y-%m-%d")}.pdf", type: "application/pdf", disposition: "inline"
    else
      render layout: false
    end
  end

  def download
    send_file File.join( CarrierWave::Uploader::Base.root, (params[:executed] == '1' ? @agreement.executed_dua.url : @agreement.dua.url) ), disposition: 'inline'
  end

  def destroy_submission
    @agreement.destroy
    redirect_to submissions_path
  end

  # DELETE /agreements/1
  # DELETE /agreements/1.json
  def destroy
    @agreement.destroy

    respond_to do |format|
      format.html { redirect_to agreements_path }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_agreement
      @agreement = Agreement.current.find_by_id(params[:id])
    end

    def set_downloadable_irb_agreement
      @agreement = current_user.all_agreements.find_by_id(params[:id])
    end

    def set_viewable_submission
      @agreement = current_user.agreements.find_by_id(params[:id])
    end

    def set_editable_submission
      @agreement = current_user.agreements.where( status: [nil, '', 'started', 'resubmit'] ).find_by_id(params[:id])
    end

    def redirect_without_submission
      empty_response_or_root_path( submissions_path ) unless @agreement
    end

    def redirect_without_agreement
      empty_response_or_root_path( current_user && current_user.system_admin? ? agreements_path : submissions_path ) unless @agreement
    end

    def agreement_review_params
      params[:agreement] ||= {}
      [:approval_date, :expiration_date].each do |date|
        params[:agreement][date] = parse_date(params[:agreement][date]) if params[:agreement].key?(date)
      end

      params.require(:agreement).permit(:current_step, :status, :comments, :approval_date, :expiration_date, :reviewer_signature)
    end

    def daua_submission_params
      params[:agreement] ||= { dua: '', remove_dua: '1' }
      params.require(:agreement).permit(:dua, :remove_dua)
    end

    def set_step
      @step = params[:step].to_i if params[:step].to_i > 0 and params[:step].to_i < 9
    end

    def step_params
      params[:agreement] ||= {}
      params[:agreement][:signature_date] = parse_date(params[:agreement][:signature_date]) if params[:agreement].key?(:signature_date)

      params.require(:agreement).permit(
        :current_step, :draft_mode,
        # Step One
          :data_user, :data_user_type,
        #   Individual
          :individual_institution_name, :individual_title, :individual_telephone, :individual_fax, :individual_address,
        #   Organization
          :organization_business_name, :organization_contact_name, :organization_contact_title, :organization_contact_telephone, :organization_contact_fax, :organization_contact_email, :organization_address,
        # Step Two
          :specific_purpose, { dataset_ids: [] },
        # Step Three
          :has_read_step3,
        # Step Four
          :posting_permission,
        # Step Five
          :has_read_step5,
        # Step Six
          :unauthorized_to_sign,
          # Data User Authorized to Sign
          :signature, :signature_print, :signature_date,
          # Duly Authorized Representative to Sign
          :duly_authorized_representative_signature_print,
        # Step Seven
          :irb_evidence_type, :irb,
        # Step Eight
          :title_of_project, :intended_use_of_data, :data_secured_location, :secured_device, :human_subjects_protections_trained
      )
    end

    def duly_authorized_params
      params[:agreement] ||= {}
      params[:agreement][:duly_authorized_representative_signature_date] = parse_date(params[:agreement][:duly_authorized_representative_signature_date]) if params[:agreement].key?(:duly_authorized_representative_signature_date)

      params.require(:agreement).permit(
        :current_step,
        # Duly Authorized Representative to Sign
        :duly_authorized_representative_signature_print, :duly_authorized_representative_signature, :duly_authorized_representative_signature_date,
      )
    end

end
