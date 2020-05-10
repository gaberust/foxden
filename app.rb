require 'sinatra'
require 'mongoid'
require 'bcrypt'

SECRET_KEYCODES = %w[abcdefg0 abcdefg1 abcdefg2 abcdefg4 abcdefg5 abcdefg6 abcdefg7 abcdefg8 abcdefg9]

# Manage Sessions

SESSION_LENGTH = 31536000 # One Year
SESSION_ACCEPTED = 0
SESSION_MISSING = 1
SESSION_EXPIRED = 2
SESSION_INVALID = 3

Session = Struct.new(:username, :exp)
$sessions = Hash.new

# Connect to MongoDB

Mongoid.load!(File.join(File.dirname(__FILE__), 'config', 'mongoid.yml'))

# Define MongoDB Models

class User
  include Mongoid::Document

  field :keycode, type: String
  field :username, type: String
  field :password, type: String
  field :description, type: String
end

class Post
  include Mongoid::Document

  field :post_id, type: Integer
  field :content, type: String

  has_one :user
end

# Define Application Routes

helpers do

  def create_session(username)
    exp = Time.now + SESSION_LENGTH
    session_id = BCrypt::Password.create(username + ' ' + exp.to_s)
    $sessions[session_id] = Session.new(username, exp)
    response.set_cookie(
        'session',
        value: session_id,
        expires: exp,
        httponly: true
    )
  end

  def validate_session
    session_id = request.cookies['session']
    if session_id.nil?
      return SESSION_MISSING, nil
    else
      if $sessions.key?(session_id)
        if Time.now < $sessions[session_id].exp
          return SESSION_ACCEPTED, $sessions[session_id].username
        else
          return SESSION_EXPIRED, $sessions.delete(session_id).username
        end
      else
        return SESSION_INVALID, nil
      end
    end
  end

end

before do
  @session_status, @username = validate_session

  status 731
  headers 'Server' => ''
end

get '/' do
  @post_count = Post.count
  @posts = Post.where(:post_id.gte => @post_count - 40)

  erb :index
end

get '/login' do
  if @username.nil?
    erb :login
  else
    redirect "/"
  end
end

post '/login' do
  if @username.nil?
    @messages = Array.new
    passed = false
    if User.where(username: params['username']).exists?
      password = BCrypt::Password.new(User.where(username: params['username']).first.password)
      passed = password.is_password?(params['password'])
    end
    if passed
      create_session params['username']
      redirect "/"
    else
      @messages.push("Incorrect Login Credentials")
      erb :login
    end
  else
    redirect "/"
  end
end

get '/register' do
  if @username.nil?
    erb :register
  else
    redirect "/"
  end
end

post '/register' do
  if @username.nil?
    @messages = Array.new
    if params['username'].match(/\s/)
      @messages.push("Username cannot contain whitespace.")
    end
    if params['username'].length == 0
      @messages.push("Username cannot be blank.")
    end
    if User.where(username: params['username']).exists?
      @messages.push("Username '" + params['username'] + "' is already taken.")
    end
    if User.where(keycode: params['keycode']).exists?
      @messages.push("That keycode has already been used.")
    end
    unless SECRET_KEYCODES.include? params['keycode']
      @messages.push("Please use a valid keycode.")
    end
    if params['password'].length < 8
      @messages.push("Password must be at least 8 characters long.")
    end
    if params['password'] != params['confirm_password']
      @messages.push("Passwords do not match.")
    end
    if @messages.length > 0
      @username_entry = params['username']
      @keycode_entry = params['keycode']
      erb :register
    else
      User.create!(
          keycode: params['keycode'],
          username: params['username'],
          password: BCrypt::Password.create(params['password']),
          description: ""
      )
      create_session params['username']
      redirect "/"
    end
  else
    redirect "/"
  end
end

get '/notadmin' do
  redirect "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
end

get '/admin' do
  erb :admin, :layout => false
end

post '/admin/login/' do
  @username = params["username"]
  erb :adminmessage, :layout => false
end

not_found do
  erb :error
end