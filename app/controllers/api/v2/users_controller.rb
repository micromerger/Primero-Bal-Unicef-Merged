# frozen_string_literal: true

# Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

# Users CRUD API
class Api::V2::UsersController < ApplicationApiController
  include Api::V2::Concerns::Pagination
  include Api::V2::Concerns::JsonValidateParams

  before_action :load_user, only: %i[show update destroy]
  before_action :user_params, only: %i[create update]
  before_action :load_extended, only: %i[index show]
  after_action :welcome, only: %i[create]
  after_action :identity_sync, only: %i[create update]

  def index
    authorize! :index, User
    filters = params.permit(:user_name, :agency, :location, :services, :user_group_ids, :query, disabled: {}).to_h
    results = PermittedUsersService.new(current_user).find_permitted_users(
      filters.compact, pagination, order_params
    )

    @users = results[:users]
    @total = results[:total]
  end

  def show
    authorize! :show_user, @user
  end
  def current
  user_location_code = current_user.location
  parent_location_code = nil

  # Find the user's location using helper already in the model
  user_location = Location.get_by_location_code(user_location_code)

  if user_location.present? && user_location.hierarchy_path.present?
    # Reuse hierarchy method from Location model to split path
    parent_path_array = user_location.hierarchy.first(3)

    if parent_path_array.size == 3
      parent_path = parent_path_array.join('.')
      parent_location = Location.find_by(hierarchy_path: parent_path)
      parent_location_code = parent_location&.location_code
    end
  end

  render json: {
    id: current_user.id,
    full_name: current_user.full_name,
    email: current_user.email,
    role_name: current_user.role&.name,
    location: user_location_code,
    parent_location_code: parent_location_code
  }
end
  def create
    authorize!(:create, User) && validate_json!(User::USER_FIELDS_SCHEMA, user_params)
    @user = User.new(@user_params)
    @user.save!
    status = params[:data][:id].present? ? 204 : 200
    render :create, status:
  end

  def update
    authorize! :disable, @user if @user_params.include?('disabled')
    authorize! :edit_user, @user
    validate_json!(User::USER_FIELDS_SCHEMA, user_params)
    @user.update_with_properties(@user_params)
    @user.save!
    keep_user_signed_in
  end

  def destroy
    authorize! :enable_disable_record, User
    @user.destroy!
  end

  protected

  def order_params
    { order_by:, order:, locale: params[:locale] } if order_by.present?
  end

  def user_params
    @user_params ||= params.require(:data).permit(User.permitted_api_params(current_user, @user))
  end

  def load_user
    @user = User.includes(:role, :user_groups).joins(:role).find(params[:id])
  end

  def load_extended
    @extended = params[:extended].present? && params[:extended] == 'true'
  end

  def welcome
    @user.send_welcome_email
  end

  def identity_sync
    @user.identity_sync(current_user)
  end

  def keep_user_signed_in
    bypass_sign_in(@user) if @user.saved_change_to_encrypted_password? && current_user == @user
  end
end
