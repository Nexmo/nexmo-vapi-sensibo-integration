require 'json'
require 'pry'
class UnitController < ActionController::Base
  skip_before_action :verify_authenticity_token

  def answer
    render json:
    [
      { 
        :action => 'talk', 
        :text => welcome_text,
        :bargeIn => true
      },
      {
        :action => 'input',
        :eventUrl => ["#{ENV['BASE_URL']}/authenticate"],
        :submitOnHash => true,
        :maxDigits => 6,
      }
    ].to_json
  end

  def event
   puts params
  end

  def authenticate
    if params['dtmf'] == ENV['SECRET_PASSKEY']
      render json:
      [
        {
          :action => 'talk',
          :text => menu_options_text,
          :bargeIn => true
        },
        {
          :action => 'input',
          :eventUrl => ["#{ENV['BASE_URL']}/menu-choice"],
          :submitOnHash => true,
          :maxDigits => 1,
        }
      ]
    else
      render json:
      {
        :action => 'talk',
        :text => 'Sorry your passkey did not match. Please call back and try again.'
      }
    end
  end
      
  def menu
    case params['dtmf']
    when '1'
      response = get_sensibo_status("#{ENV['SENSIBO_ID']}")
      render json:
      [
        {
          :action => 'talk',
          :text => ac_info_text(response)
        }
      ]
    when '2'
      #action = update_sensibo_status('on')
    when '3'
      #action = update_sensibo_status('off')
    else
      render json: 
      [
        {
          :action => 'talk', 
          :text => "You entered an incorrect choice of #{params['dtmf']}. Expected 1, 2 or 3. Please try again."
        },
        {
          :action => 'connect',
          :eventUrl => "#{ENV['BASE_URL']}/authenticate"
        }
      ]
    end
  end

  private

  def get_sensibo_status(id)
    require 'net/https'
    begin
        uri = URI("#{ENV['SENSIBO_API_URL']}/#{ENV['SENSIBO_ID']}?fields=*&apiKey=#{ENV['SENSIBO_API_KEY']}")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        req = Net::HTTP::Get.new(uri, {'Content-Type' => 'application/json'})
        res = http.request(req)
        data = JSON.parse(res.body)
    rescue => e
        puts "failed #{e}"
    end
    data
  end

  def ac_info_text(data)
    <<~HEREDOC
    You requested the current info on your AC unit located at:
    #{data['result']['location']['address'][0]} in #{data['result']['location']['address'][1]}, #{data['result']['location']['address'][2]}.
    
    The AC unit is currently #{data['result']['acState']['on'] == 'true' ? 'on' : 'off'} and is 
    #{data['result']['connectionStatus']['isAlive'] == 'true' ? 'connected' : 'disconnected'}.

    It's target temperature is set to #{data['result']['acState']['targetTemperature']}.
    HEREDOC
  end

  def welcome_text
    <<~HEREDOC
    Hi! This is your air conditioner. 
    Please authenticate before continuing by entering your passkey. 
    When you are done please enter the hash key.
    HEREDOC
  end

  def menu_options_text
    <<~HEREDOC
    Thank you for authenticating. 
    Please choose from the following options: 
    Press 1 and the hash key for my current status
    Press 2 and the hash key to turn me on
    Press 3 and the hash key to turn me off
    Or hang up at anytime to end this call
    HEREDOC
  end
end