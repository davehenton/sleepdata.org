# frozen_string_literal: true

# Allows admins to review user-submitted tools.
class Admin::ToolsController < ApplicationController
  before_action :authenticate_user!
  before_action :check_admin
  before_action :set_tool, only: [:show, :edit, :update, :destroy]

  # GET /admin/tools
  def index
    @order = scrub_order(Tool, params[:order], "tools.name")
    @tools = Tool.current.order(@order).page(params[:page]).per(40)
  end

  # # GET /admin/tools/1
  # def show
  # end

  # GET /admin/tools/new
  def new
    @tool = Tool.new
  end

  # # GET /admin/tools/1/edit
  # def edit
  # end

  # POST /admin/tools
  def create
    @tool = current_user.tools.new(tool_params)
    if @tool.save
      redirect_to admin_tool_path(@tool), notice: "Tool was successfully created."
    else
      render :new
    end
  end

  # PATCH /admin/tools/1
  def update
    if @tool.update(tool_params)
      redirect_to admin_tool_path(@tool), notice: "Tool was successfully updated."
    else
      render :edit
    end
  end

  # DELETE /admin/tools/1
  def destroy
    @tool.destroy
    redirect_to admin_tools_path, notice: "Tool was successfully deleted."
  end

  private

  def set_tool
    @tool = Tool.current.find_by_param(params[:id])
  end

  def tool_params
    params[:tool] ||= { blank: "1" }
    params[:tool].delete(:slug) if params[:tool][:slug].blank?
    parse_date_if_key_present(:tool, :publish_date)
    params.require(:tool).permit(
      :name, :url, :description, :slug, :published, :publish_date,
      :tag_program, :tag_script, :tag_tutorial, :series
    )
  end
end