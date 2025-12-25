# frozen_string_literal: true

class InquiriesController < ApplicationController
  include Authorization

  layout 'admin'

  before_action :authenticate_user!
  before_action :set_body_classes

  def index
    @inquiries = inquiries
    @inquiry = Inquiry.new
  end

  def show
    render plain: 'OK'
  end

  def create
    @inquiry      = Inquiry.new(resource_params)
    @inquiry.user = current_user

    if @inquiry.save
      redirect_to inquiries_path
    else
      @inquiries = inquiries
      render :index
    end
  end

  private

  def inquiries
    if current_user.role.can?(:administrator)
      Inquiry.order(id: :desc).limit(100)
    else
      current_user.inquiries.order(id: :desc)
    end
  end

  def resource_params
    params.expect(inquiry: [:message, :action_type, :status])
  end

  def set_body_classes
    @body_classes = 'admin'
  end
end
