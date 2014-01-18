class User < ActiveRecord::Base 

  devise :database_authenticatable, :registerable, :lockable, :timeoutable,
         :recoverable, :rememberable, :trackable, :secure_validatable, :session_limitable, :omniauthable, :omniauth_providers => [:facebook, :twitter]

  attr_accessible :email, :password, :password_confirmation, :username, :first_name, :last_name, :uid, :provider, :full_name
  
  has_many :lists, dependent: :destroy
  has_many :products, :through => :lists
  has_many :friendships, dependent: :destroy
  has_many :friends, :through => :friendships
  has_many :inverse_friendships, :class_name => "Friendship", :foreign_key => "friend_id"
  has_many :inverse_friends, :through => :inverse_friendships, :source => :user
  has_many :searches
  has_many :messages
  
  validates_uniqueness_of :username, allow_blank: :true
  validates_format_of :username, with: /\A([a-zA-Z0-9]{2,16}[-_]?[a-zA-Z0-9]{2,16})\z/ , allow_blank: :true
  validates_length_of :username, in: 3..30, allow_blank: true

  validates :email, :email => true

  validates_format_of :first_name, :last_name, with: /\A([^\d\W]+)\z/, allow_blank: :true
  validates_length_of :first_name, :last_name, in: 1..16, allow_blank: true

  after_create :send_confirmation_email, :send_sign_up_notification

  def full_name=(name)
    self.first_name, self.last_name = name.split(' ')
  end
  
  def full_name(name)
    name = "#{self.first_name} #{self.last_name}"
  end  
  
  def has_friend?(user)
    friends.all.include?(user) ? true : false
  end

  def display_user_as(title)
    if title == "username"
      username.presence || mask_email
    else
      mask_email
    end
  end
  
  def mask_email
    email.match(/(.*)@.*/)[1]
  end
  
  def self.find_for_facebook_oauth(auth, signed_in_resource=nil)
    user = User.where(:provider => auth.provider, :uid => auth.uid).first
    unless user
      pass = Devise.friendly_token[0,20]
      user = User.new(full_name: auth.info.name,
                      provider: auth.provider,
                      uid: auth.uid,
                      email: auth.info.email,
                      password: pass,
                      password_confirmation: pass
                      )
      user.save
    end
    user
  end
  
  def self.find_for_twitter_oauth(auth, signed_in_resource=nil)
    user = User.where(:provider => auth.provider, :uid => auth.uid).first
    unless user
      pass = Devise.friendly_token[0,20]
      user = User.new(full_name: auth.info.name,
                      provider: auth.provider,
                      uid: auth.uid,
                      email: auth.info.email,
                      password: pass,
                      password_confirmation: pass
                      )
      user.save
    end
    user
  end

  private

  def send_sign_up_notification
    SystemMailer.sign_up_notification.deliver
  end

  def send_confirmation_email
    UserMailer.signup_confirmation(self).deliver
  end
end
