class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :trips, dependent: :destroy
  has_many :emergency_contacts, dependent: :destroy
  has_many :checklists, through: :trips
  has_many :safety_records, through: :emergency_contacts

  def active?
    active == true
  end
end
