require 'digest/sha1'
class User < ActiveRecord::Base

  self.inheritance_column = 'accesslevel'
  belongs_to :groups
  has_many :projects
  has_many :commands
  has_many :track_stanzas, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :user_preferences, :dependent => :destroy
  has_many :email_messages, :foreign_key => :to_user_id, :dependent => :destroy

  # Getting preferences:
  # user.preferences["foo"] = "bar" -- set and save preference
  # puts user.preferences["foo"] -- print preference value
  # user.preferences("foo") -- return UserPreference object
  # user.preferences -- return all UserPreference objects
  def preferences(key = nil)
    if key then
      UserPreference.find_by_user_id_and_key(self.id, key)
    else
      # Convert preferences to a fancy-pants hash thing
      prefs = UserPreference.all
      prefs.instance_variable_set(:@prefs_user, self)
      def prefs.[](key)
        pref = UserPreference.find_by_user_id_and_key(@prefs_user.id, key)
        pref.nil? ? nil : pref.value
      end
      def prefs.[]=(key, value)
        pref = UserPreference.find_by_user_id_and_key(@prefs_user.id, key)
        if pref.nil? then
          pref = UserPreference.new(:user_id => @prefs_user.id, :key => key)
        end
        pref.value = value
        pref.save
      end
      prefs
    end
  end


  # Virtual attribute for the unencrypted password
  attr_accessor :password
  attr_accessor :host
  attr_accessor :port

  validates_presence_of     :login, :email, :name, :lab, :institution
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :login,    :within => 3..40
  validates_length_of       :email,    :within => 3..100
  validates_uniqueness_of   :login, :case_sensitive => false
  validates_format_of :email, :with => /(^([^@\s]+)@((?:[-_a-z0-9]+\.)+[a-z]{2,})$)|(^$)/i

  validates_length_of       :new_email, 
                            :within => 6..100, 
                            :if => :new_email_entered?
  validates_format_of       :new_email,
                :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/,
                :if => :new_email_entered?
  validates_inclusion_of    :accesslevel, :allow_blank => true, :allow_nil => true, :in => [ 
    Administrator.name, Moderator.name, Reviewer.name, User.name
  ]

  before_save :encrypt_password
  before_create :make_activation_code
  #after_save :update_ftp_password


  def pis
    pis = Hash.new
    if File.exists? "#{RAILS_ROOT}/config/PIs.yml" then
      pis = [ open("#{RAILS_ROOT}/config/PIs.yml") { |f| YAML.load(f.read) } ]
      pis = pis.first unless pis.nil?
    end
    pis = Hash.new if pis.nil?
    user_pis = pis[self.lab] ? [ self.lab ] : pis.find_all { |k, v| v.include?(self.lab) }.map { |k, v| k }
    return user_pis
  end


  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    # hide records with a nil activated_at
    u = find :first, :conditions => ['login = ? and activated_at IS NOT NULL', login]
    u && u.authenticated?(password) ? u : nil
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    self.remember_token_expires_at = 2.weeks.from_now.utc
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

    # Activates the user in the database.
  def activate
    @activated = true
    update_attributes(:activated_at => Time.now.utc, :activation_code => nil)
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end


  # password reset section
  def forgot_password
    @forgotten_password = true
    self.make_password_reset_code
  end

  def reset_password
    # First update the password_reset_code before setting the 
    # reset_password flag to avoid duplicate email notifications.
    update_attributes(:password_reset_code => nil)
    @reset_password = true
  end

  def recently_reset_password?
    @reset_password
  end

  def recently_forgot_password?
    @forgotten_password
  end


  # change email section
  def change_email_address(new_email_address)
    @change_email  = true
    self.new_email = new_email_address
    self.make_email_activation_code
  end

  def activate_new_email
    @activated_email = true
    update_attributes(:email=> self.new_email, :new_email => nil, :email_activation_code => nil)
  end

  def recently_changed_email?
    @change_email
  end

  # Assures that updated email addresses do not conflict with
  # existing email addresses. 
  def validate
    if User.find_by_email(new_email)
      errors.add(new_email, "is already being used")
    end
  end

  def create_upload_resources
    if ActiveRecord::Base.configurations[RAILS_ENV]['ftpServer'] then
      # Create FTP stuff
      update_ftp_password
    end
    if ActiveRecord::Base.configurations[RAILS_ENV]['upload'] then
      abs_upload_path = File.expand_path(ActiveRecord::Base.configurations[RAILS_ENV]['upload'])
      abs_upload_path = File.join(abs_upload_path, login)
      unless File.directory? abs_upload_path then
        Dir.mkdir(abs_upload_path)
      end
    end
  end
  def update_ftp_password
    return if password.blank?
    create_ftp_user  # if needed

    #logger.info "\n\nGALT! password=[#{password}]\n\n" #debug
    #logger.info "GALT! login=[#{login}]" #debug

    ftpMount = ActiveRecord::Base.configurations[RAILS_ENV]['ftpMount'] 

    #logger.info "GALT! ftpMount=[#{ftpMount}]" #debug

    cmd = "echo #{password} | ftpasswd --passwd --name=#{login} --change-password --stdin --file=#{ftpMount}/ftp_passwd"

    #logger.info "GALT! cmd=[#{cmd}]\n\n" #debug

    system(cmd)

    #logger.info "GALT! $?=[#{$?}]\n\n" #debug

    return  # don't want it to return any value
  end


  protected

    # before filter 

    def create_ftp_user
      ftpMount = ActiveRecord::Base.configurations[RAILS_ENV]['ftpMount']
      userFtpDir = File.join(ftpMount,login)
      return if File.exists?(userFtpDir)
      ftpLocal = ActiveRecord::Base.configurations[RAILS_ENV]['ftpLocal'] 
      ftpUserId = ActiveRecord::Base.configurations[RAILS_ENV]['ftpUserId'] 
      ftpGroupId = ActiveRecord::Base.configurations[RAILS_ENV]['ftpGroupId'] 
      Dir.mkdir(userFtpDir,0775)
      cmd = "echo password | ftpasswd --passwd --name=#{login} --stdin --uid=#{ftpUserId} --gid=#{ftpGroupId}" +
             " --home=#{ftpLocal}/#{login} --shell=/sbin/nologin  --file=#{ftpMount}/ftp_passwd"

      #logger.info "\n\nGALT! cmd=[#{cmd}]" #debug

      system(cmd) 

      #logger.info "GALT! $?=[#{$?}]\n\n" #debug

      return  # don't want it to return any value
    end

    #before_save    # I don't know why, but this gets called up to 4 or more times for one actual save?!
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
      self.crypted_password = encrypt(password)
    end
    
    def password_required?
      crypted_password.blank? || !password.blank?
    end

    # before_create
    def make_activation_code
      self.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
    end

    def make_password_reset_code
      self.password_reset_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
    end

    def make_email_activation_code
      self.email_activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
    end

    def new_email_entered?
      !self.new_email.blank?
    end

end
