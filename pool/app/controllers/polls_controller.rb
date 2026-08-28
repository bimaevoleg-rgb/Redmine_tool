class PollsController < ApplicationController
  before_action :find_project, :authorize
  before_action :find_poll, only: [:show, :edit, :update, :destroy, :vote, :cancel_vote, :report]

  def index
    @polls = Poll.where(project_id: @project.id).includes(:options, :votes).order(created_at: :desc)
  end

  def show
    @user_vote = @poll.votes.find_by(user_id: User.current.id)
  end

  def new
    @poll = Poll.new
    @poll.options.build
  end

  def create
    @poll = Poll.new(poll_params)
    @poll.project_id = @project.id
    @poll.created_by_id = User.current.id
    if @poll.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to project_poll_path(@project, @poll)
    else
      @poll.options.build if @poll.options.empty?
      render :new
    end
  end

  def edit
    @poll.options.build if @poll.options.empty?
  end

  def update
    if @poll.update(poll_params)
      flash[:notice] = l(:notice_successful_update)
      redirect_to project_poll_path(@project, @poll)
    else
      @poll.options.build if @poll.options.empty?
      render :edit
    end
  end

  def destroy
    @poll.destroy
    flash[:notice] = l(:notice_successful_delete)
    redirect_to project_polls_path(@project)
  end

  def vote
    if !@poll.is_open?
      flash[:error] = l(:poll_closed_error)
    else
      custom = params[:custom_value].to_s.strip
      ids = Array(params[:poll_option_ids] || params[:poll_option_id]).map(&:to_i)
      custom_id = nil
      if custom.present? && @poll.allow_custom?
        opt = @poll.options.find_or_create_by!(value: custom) { |o| o.position = @poll.options.count }
        custom_id = opt.id
        ids << opt.id
      end
      valid = @poll.options.where(id: ids).pluck(:id)
      if valid.empty?
        flash[:error] = l(:poll_invalid_option)
      else
        @poll.votes.where(user_id: User.current.id).delete_all
        valid.each do |oid|
          @poll.votes.create!(
            poll_option_id: oid,
            user_id: User.current.id,
            custom_value: (oid == custom_id ? custom : nil)
          )
        end
        flash[:notice] = l(:poll_vote_saved)
      end
    end
    redirect_to project_poll_path(@project, @poll)
  end

  def cancel_vote
    @poll.votes.where(user_id: User.current.id).delete_all
    flash[:notice] = l(:poll_vote_cancelled)
    redirect_to project_poll_path(@project, @poll)
  end

  def report
    votes = @poll.votes.includes(:poll_option, :user).order(:poll_option_id, :id)
    rows = [[l(:poll_report_option), l(:poll_report_user), l(:poll_report_login), l(:poll_report_mail), l(:poll_report_date)]]
    votes.each do |v|
      rows << [
        v.poll_option&.value || '',
        v.user&.name || '',
        v.user&.login || '',
        v.user&.mail || '',
        v.created_at&.strftime('%Y-%m-%d %H:%M') || ''
      ]
    end
    csv = "\xEF\xBB\xBF" + rows.map do |r|
      r.map { |c| c.to_s.gsub(/[\r\n]+/, ' ').gsub(';', ',') }.join(';')
    end.join("\r\n")
    send_data csv, type: 'text/csv; charset=utf-8',
                   filename: "poll_#{@poll.id}_report_#{Date.today.iso8601}.csv"
  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_poll
    @poll = Poll.where(project_id: @project.id).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def poll_params
    params.require(:poll).permit(
      :title, :description, :is_open, :multiple, :allow_custom,
      options_attributes: [:id, :value, :_destroy]
    )
  end
end
