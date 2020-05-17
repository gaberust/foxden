require 'sinatra'
require 'mongoid'
require 'bcrypt'
require 'json'
require 'jwt'

SECRET_KEYCODES = %w[abcdefg0 abcdefg1 abcdefg2 abcdefg4 abcdefg5 abcdefg6 abcdefg7 abcdefg8 abcdefg9]
JWT_SECRET = "MySuperSecretJWTKey1234"

RICK_ROLL = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"

ENCODED_PICKLE = "gASVaAAAAAAAAAB9lCiMB21lc3NhZ2WUjDFZb3UganVzdCBlYXJuZWQgYSBUZXN0ZXIncyBSZXdhcmQhIEhlcmUncyBhIGhpbnQhlIwEaGludJSMG2h0dHBzOi8vZm94ZGVuLmNvbS9oaW50LnBuZ5R1Lg=="

RESTRICTED = %w(; $ { } # ~ _ [ ])

# Manage Sessions

SESSION_LENGTH = 31536000 # One Year
TOKEN_ACCEPTED = 0
TOKEN_MISSING = 1
TOKEN_EXPIRED = 2
TOKEN_INVALID = 3
LOGGED_OUT = 4

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
  field :author, type: String
end

# Define Application Routes

helpers do

  def create_token(username)
    token = JWT.encode(
        { username: username, exp: Time.now.to_i + SESSION_LENGTH },
        JWT_SECRET,
        'HS256'
    )
    response.set_cookie(
        'token',
        value: token,
        expires: Time.now + SESSION_LENGTH * 2,
        httponly: true
    )
  end
  
  def validate_token
    token = request.cookies['token']
    if token.nil?
      return TOKEN_MISSING, nil
    else
      begin
        payload = JWT.decode(token, JWT_SECRET, true, { algorithm: 'HS256' })[0]
      rescue JWT::ExpiredSignature
        return TOKEN_EXPIRED, nil
      rescue JWT::DecodeError
        return TOKEN_INVALID, nil
      else
        return TOKEN_ACCEPTED, payload['username']
      end
    end
  end

  def invalid_parameters
    content_type :json
    {
        title: "Burp Not Allowed",
        message: "Sorry, but that won't work. It's okay though, you tried your best. Here's a gift to make you feel better. :)",
        gift: "https://raw.githubusercontent.com/gaberust/foxden-gift-payload/master/reverse_tcp_shell.py",
        PS: "print('I <3 Django!')"
    }.to_json
  end

  def unauthorized_post_request
    content_type :json
    {
        title: "Knock That Off",
        message: "Are you seriously trying to bypass my super secure authentication system? You didn't actually think it would work did you?"
    }.to_json
  end

  def block
    response.set_cookie(
        "gandalf",
        value: "YOU SHALL NOT PAASSSSSSS!!!",
        expires: Time.now + SESSION_LENGTH,
        httponly: true
    )
    redirect RICK_ROLL
  end

  def shenanigans desc, op1, op2
    temp = desc
    output = ""
    while true
      first, middle, last = temp.partition op1
      output << first
      temp = last
      if temp.include? op2
        first, middle, last = temp.partition op2
        RESTRICTED.each do |char|
          first.gsub! char, ""
        end
        #UNIX output << `python3 ./shenanigans.py #{first}`
        output << `python ./shenanigans.py #{first}` #WINDOWS
        temp = last
      else
        output << middle << last
        break
      end
    end
    output
  end

end

before do
  @token_status, @username = validate_token

  status 731
  headers 'Server' => ''

  unless request.cookies['gandalf'].nil?
    redirect RICK_ROLL
  end
end

# TODO
get '/' do
  @post_count = Post.count
  @posts = Post.where(:post_id.gte => @post_count - 40)

  erb :index
end

get '/posts' do
  if params['lower'].nil?
    lower = -1
  else
    lower = params['lower'].to_i
  end
  if params['upper'].nil?
    upper = Post.count
  else
    upper = params['upper'].to_i
  end
  @posts = Post.where(:post_id.gt => lower)
               .where(:post_id.lt => upper)
               .order_by(post_id: :desc)
  erb :posts, :layout => false
end

post '/post' do
  if @username.nil?
    unauthorized_post_request
  elsif params['content'].nil?
    invalid_parameters
  elsif params['content'].strip.empty?
    content_type :json
    {
        success: false,
        message: "Post content cannot be empty."
    }.to_json
  else
    content_type :json
    content = params['content']
    content.gsub!("&", "&amp;")
        .gsub!("<", "&lt;")
        .gsub!(">", "&gt;")
        .gsub!('"', "&quot;")
        .gsub!("'", "&#x27;")
        .gsub!("/", "&#x2F;")
    id = Post.count
    Post.create!(
        post_id: id,
        content: content,
        author: @username
    )
    {
        success: true
    }.to_json
  end
end

get '/login' do
  unless params['next'].nil?
    @next = params['next']
  end
  unless params['s'].nil?
    case params['s'].to_i
    when TOKEN_MISSING
      @info = "Log in to view this page."
    when TOKEN_EXPIRED
      @info = "Your session expired. Log back in to view this page."
    when LOGGED_OUT
      @info = "You have been logged out."
    end
  end
  if @username.nil?
    erb :login
  else
    redirect "/"
  end
end

post '/login' do
  if params['username'].nil? || params['password'].nil?
    invalid_parameters
  elsif @username.nil?
    passed = false
    if User.where(username: params['username']).exists?
      password = BCrypt::Password.new(User.where(username: params['username']).first.password)
      passed = password.is_password?(params['password'])
    end
    if passed
      create_token params['username']
      if params['next'].nil?
        redirect "/"
      else
        redirect params['next']
      end
    else
      @messages = ["Incorrect Login Credentials"]
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
  if params['username'].nil? || params['keycode'].nil? || params['password'].nil? || params['confirm_password'].nil?
    invalid_parameters
  elsif @username.nil?
    @messages = Array.new
    if params['username'].count("^a-zA-Z0-9") > 0
      @messages.push("Username can only contain numbers and letters.")
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
      puts `copy .\\public\\img\\fox.png .\\public\\img\\profile\\#{params['username']}.png`
      # UNIX puts `cp ./public/img/fox.png ./public/img/profile/#{params['username']}.png`
      create_token params['username']
      redirect "/welcome"
    end
  else
    redirect "/"
  end
end

get '/welcome' do
  if @username.nil?
    erb :error
  else
    erb :welcome
  end
end

get '/profile/:name' do
  @name = params['name']
  user = User.where(username: @name).first
  if user.nil?
    erb :error
  else
    description = user.description
    if description.include? "<script>"
      block
    elsif description.include? "{{"
      tpl_input = shenanigans(description, "{{", "}}")
    elsif description.include? "{%"
      tpl_input = shenanigans(description, "{%", "%}")
    elsif description.include? "${"
      tpl_input = shenanigans(description, "${", "}")
    elsif description.include? "a{*"
      tpl_input = shenanigans(description, "a{*", "*}b")
    elsif description.include? "{*"
      tpl_input = shenanigans(description, "{*", "*}")
    else
      tpl_input = description
    end
    profile_template = %{
      <div class="container">
        <br>
        <div class="row">
          <div class="col-3">
            <h1 class="text-center"><%= @name %></h1>
          </div>
          <% unless @username.nil? %>
            <% if @username == @name %>
              <div class="col-9">
                <a class="btn btn-primary" href="/profile/<%= @name %>/settings">Settings</a>
              </div>
            <% end %>
          <% end %>
        </div>
        <br>
        <div class="row">
          <div class="col-3">
            <img src="/img/profile/<%= @name %>.png" style="width:100%;" alt="<%= @name %>'s Profile Picture">
          </div>
          <div class="col-9">
            <p>#{tpl_input}</p>
          </div>
        </div>
      </div>
    }
    begin
      erb profile_template
    rescue
      ""
    end
  end
end

get '/profile' do
  if @username.nil?
    redirect "/login?s=" + @token_status.to_s + "&next=/profile"
  else
    redirect "/profile/" + @username
  end
end

get '/profile/:name/settings' do
  if @username.nil?
    redirect "/login?s=" + @token_status.to_s + "&next=/profile/#{params['name']}/settings"
  elsif @username == params['name']
    @description = User.where(username: @username).first.description
    @description.gsub!("&", "&amp;")
        .gsub!("<", "&lt;")
        .gsub!(">", "&gt;")
        .gsub!('"', "&quot;")
        .gsub!("'", "&#x27;")
        .gsub!("/", "&#x2F;")
    erb :settings
  else
    erb :error
  end
end

post '/profile/:name/settings' do
  if @username.nil? || @username != params['name']
    unauthorized_post_request
  elsif (not params['description_update'].nil?) && params['picture_update'].nil?
    user = User.where(username: @username).first
    if params['description'].nil?
      invalid_parameters
    else
      @description = params['description']
      @description.gsub!("&amp;", "&")
          .gsub!("&lt;", "<")
          .gsub!("&gt;", ">")
          .gsub!('&quot;', '"')
          .gsub!("&#x27;", "'")
          .gsub!("&#x2F;", "/")
      user.description = @description
      user.save!
      @description.gsub!("&", "&amp;")
          .gsub!("<", "&lt;")
          .gsub!(">", "&gt;")
          .gsub!('"', "&quot;")
          .gsub!("'", "&#x27;")
          .gsub!("/", "&#x2F;")
      @info = "Description updated successfully."
      erb :settings
    end
  elsif (not params['picture_update'].nil?) && params['description_update'].nil?
    if params['file'].nil?
      @messages = ["You've gotta actually pick a file for that to work my dude. Gosh, this is basic computering."]
    else
      begin
        file = params['file'][:tempfile]
        File.open("./public/img/profile/#{@username}.png", 'wb') do |f|
          f.write(file.read)
        end
        @info = "Profile picture updated successfully... I think."
      rescue
        @messages = ["I don't even know what you did, or how to mitigate it, but I sure am glad I used that try-catch block!"]
      end
    end
    @description = User.where(username: @username).first.description
    @description.gsub!("&", "&amp;")
        .gsub!("<", "&lt;")
        .gsub!(">", "&gt;")
        .gsub!('"', "&quot;")
        .gsub!("'", "&#x27;")
        .gsub!("/", "&#x2F;")
    erb :settings
  else
    invalid_parameters
  end
end

get '/profile/:name/password' do
  if @username.nil?
    redirect "/login?s=" + @token_status.to_s + "&next=/profile/#{params['name']}/password"
  elsif @username == params['name']
    erb :password
  else
    erb :error
  end
end

post '/profile/:name/password' do
  if @username.nil? or @username != params['name']
    unauthorized_post_request
  elsif params['old_password'].nil? || params['new_password'].nil? || params['confirm_password'].nil?
    invalid_parameters
  else
    user = User.where(username: @username).first
    @messages = Array.new
    current_password = BCrypt::Password.new(user.password)
    unless current_password.is_password?(params['old_password'])
      @messages.push("Incorrect Password.")
    end
    if current_password.is_password?(params['new_password']) && @messages.length == 0 && params['new_password'] == params['confirm_password']
      @messages.push("New password cannot be the same as your old password, dummy.")
    end
    if params['new_password'].length < 8
      @messages.push("New password must be at least 8 characters long.")
    end
    if params['new_password'] != params['confirm_password']
      @messages.push("Passwords do not match.")
    end
    if @messages.length > 0
      erb :password
    else
      user.password = BCrypt::Password.create(params['new_password'])
      user.save!
      @info = "Password updated successfully."
      @messages.push("&#x1F36A Keep your hands out of the cookie jar. They're hot! &#x1F36A")
      response.set_cookie(
          'rickpickle',
          value: ENCODED_PICKLE,
          path: "/",
          expires: Time.now + SESSION_LENGTH,
          httponly: true
      )
      erb :password
    end
  end
end

get '/hint.png' do
  if request.cookies['rickpickle'] == ENCODED_PICKLE
    content_type 'image/png'
    File.open('./hint.png', "rb").read
  else
    erb :error
  end
end

get '/logout' do
  response.set_cookie(
      'token',
      value: "logged out",
      expires: Time.now - SESSION_LENGTH,
      httponly: true
  )
  redirect "/login?s=" + LOGGED_OUT.to_s
end

get '/notadmin' do
  redirect RICK_ROLL
end

get '/admin' do
  erb :admin, :layout => false
end

post '/admin/login/' do
  unless params['username'].nil?
    @username = params["username"]
  end
  erb :adminmessage, :layout => false
end

not_found do
  erb :error
end