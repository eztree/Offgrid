class TripsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :new, :create ]

  def index
    @trips = policy_scope(Trip)
    authorize @trips
  end

  def new
    @trail = Trail.find(params['trail'])

    @user = current_user.nil? ? create_tmp_user : current_user

    @trip = Trip.create!(
      user: @user,
      trail: @trail
    )

    authorize @trip
    redirect_to trip_steps_path(@trip)
  end

  private

  def create_tmp_user
    User.where(email: "placeholder@email.com").first
  end
end
