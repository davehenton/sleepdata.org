# frozen_string_literal: true

# This controller handles easy registration/sign in of users as part of a tool
# contribution or request.
class RequestController < ApplicationController
  before_action :authenticate_user!, only: [
    :contribute_tool_description, :contribute_tool_set_description
  ]

  def contribute_tool_start
    @tool = Tool.new
  end

  def contribute_tool_set_location
    @tool = Tool.new(tool_params)
    @tool.valid?
    if @tool.errors[:url].present?
      render :contribute_tool_start
    else
      if current_user
        save_tool_user
      else
        @user = User.new
        render :contribute_tool_about_me
      end
    end
  end

  def contribute_tool_register_user
    @tool = Tool.new(tool_params)
    unless current_user
      @user = User.new(user_params)
      if @user.save
        @user.send_welcome_email_in_background!
        save_tool_user(user: @user, redirect: false)
        render :contribute_tool_confirm_email
        return
      else
        render :contribute_tool_about_me
        return
      end
    end

    save_tool_user
  end

  def contribute_tool_sign_in_user
    @tool = Tool.new(tool_params)
    unless current_user
      user = User.find_by_email params[:email]
      if user && user.valid_password?(params[:password])
        sign_in(:user, user) # TODO, don't sign in unless confirmed?
      else
        @sign_in_errors = []
        @sign_in = true
        @user = User.new
        render :contribute_tool_about_me
        return
      end
    end

    save_tool_user
  end

  def contribute_tool_description
    @tool = current_user.tools.find_by_param(params[:id])
    redirect_to dashboard_path, alert: "This tool does not exist." unless @tool
  end

  def contribute_tool_set_description
    @tool = current_user.tools.find_by_param(params[:id])
    unless @tool
      redirect_to dashboard_path, alert: "This tool does not exist."
      return
    end

    already_published = @tool.published?
    published = \
      if already_published
        true
      else
        (params[:draft] == "1" ? false : true)
      end

    if @tool.update(name: params[:tool][:name], description: params[:tool][:description], published: published)
      if published
        @tool.update(publish_date: Time.zone.today) if @tool.publish_date.blank?
        redirect_to tool_path(@tool), notice: already_published ? "Tool updated successfully." : "Tool published successfully."
      else
        redirect_to tool_path(@tool), notice: "Draft saved successfully."
      end
    else
      render :contribute_tool_description
    end
  end

  # # Tool Requests
  # def tool_request
  # end

  private

  def tool_params
    params[:tool] ||= { blank: "1" }
    params[:tool][:description] = params[:tool][:url].to_s.strip if params[:tool].key?(:url)
    params.require(:tool).permit(:name, :description, :url)
  end

  def user_params
    params.require(:user).permit(:username, :email, :password)
  end

  def save_tool_user(user: current_user, redirect: true)
    @tool.user_id = user.id
    if @tool.save
      description = @tool.readme_content
      if description
        description = "```\n#{description}\n```" unless @tool.markdown?
        @tool.update description: description
      end
      redirect_to contribute_tool_description_path(@tool) if redirect
    else
      render :contribute_tool_start if redirect
    end
  end
end
