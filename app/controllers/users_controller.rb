class UsersController < ApplicationController
  before_filter :authenticate_user!, except: [:new, :create]
  before_filter :check_system_admin, except: [:new, :create, :index, :show, :settings, :update_settings, :activate]
  before_filter :check_service_account, only: [:activate]

  def settings
  end

  def update_settings
    notifications = {}
    email_settings = ['send_email']
    email_settings.each do |email_setting|
      notifications[email_setting] = (not params[:email].blank? and params[:email][email_setting] == '1')
    end
    current_user.update_attribute :email_notifications, notifications
    redirect_to settings_path, notice: 'Email settings saved.'
  end

  def index
    params[:search] ||= params[:q]
    current_user.update_attribute :users_per_page, params[:users_per_page].to_i if params[:users_per_page].to_i >= 10 and params[:users_per_page].to_i <= 200
    @order = params[:order].blank? ? 'users.current_sign_in_at DESC' : params[:order]
    users_scope = User.current
    @search_terms = params[:search].to_s.gsub(/[^0-9a-zA-Z]/, ' ').split(' ')
    @search_terms.each{|search_term| users_scope = users_scope.search(search_term) }
    users_scope = users_scope.order(@order)
    @users = users_scope.page(params[:page]).per(current_user.users_per_page)
    respond_to do |format|
      format.html
      format.js
      format.json { render json: @users.collect{|u| {name: u.name_and_email, id: u.id}}}
    end
  end

  def show
    @user = User.find_by_id(params[:id])
  end

  # # GET /users/new
  # # GET /users/new.xml
  # def new
  #   @user = User.new
  #
  #   respond_to do |format|
  #     format.html # new.html.erb
  #     format.xml  { render xml: @user }
  #   end
  # end

  def edit
    @user = User.find_by_id(params[:id])
  end

  # # POST /users
  # # POST /users.xml
  # def create
  #   @user = User.new(params[:user])
  #
  #   respond_to do |format|
  #     if @user.save
  #       format.html { redirect_to(@user, notice: 'User was successfully created.') }
  #       format.xml  { render xml: @user, status: :created, location: @user }
  #     else
  #       format.html { render action: "new" }
  #       format.xml  { render xml: @user.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  # Post /users/activate.json
  def activate
    params[:user] ||= {}
    params[:user][:password] = params[:user][:password_confirmation] = Digest::SHA1.hexdigest(Time.now.usec.to_s)[0..19] if params[:user][:password].blank? and params[:user][:password_confirmation].blank?
    @user = User.new(params[:user])
    if @user.save
      @user.update_column :status, 'active'
      respond_to do |format|
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.json { render json: @user, only: [:id, :first_name, :last_name, :email, :status], status: :created, location: @user }
      end
    else
      respond_to do |format|
        format.html { render action: "new" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @user = User.find_by_id(params[:id])
    if @user.update_attributes(post_params)
      original_status = @user.status
      @user.update_column :system_admin, params[:user][:system_admin]
      @user.update_column :service_account, params[:user][:service_account]
      @user.update_column :status, params[:user][:status]
      UserMailer.status_activated(@user).deliver if Rails.env.production? and original_status != @user.status and @user.status = 'active'
      redirect_to(@user, notice: 'User was successfully updated.')
    elsif @user
      render action: "edit"
    else
      redirect_to users_path
    end
  end

  def destroy
    @user = User.find_by_id(params[:id])
    @user.destroy
    redirect_to users_path
  end

  private

  def post_params
    params[:user] ||= {}

    params[:user].slice(
      :first_name, :last_name, :email
    )
  end
end