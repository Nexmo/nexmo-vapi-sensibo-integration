require "ibm_watson/authenticators"
require "ibm_watson/speech_to_text_v1"
require 'json'
class UnitController < ActionController::Base
  skip_before_action :verify_authenticity_token
  layout false

  def answer
    render json:
    [
      { 
        :action => 'talk', 
        :text => welcome_text
      },
      {
        :action => 'record',
        :eventUrl => ["#{ENV['BASE_URL']}/record"],
        :format => 'wav',
        :beepStart => true,
        :endOnKey => '#'
      },
      {
        :action => 'talk',
        :text => 'Please wait a moment as your passphrase is verified.'
      },
      {
        :action => 'conversation',
        :name => 'sensibo-conversation',
        :eventUrl => ["#{ENV['BASE_URL']}/event"]
      }
    ].to_json
  end

  def event
    if params['type'] == 'transfer'
      if is_authenticated?('passphrase.wav')
        render json:
        {
          :type => 'ncco',
          :ncco => [
          {
            :action => 'talk',
            :text => menu_options_text
          },
          {
            :action => 'input',
            :eventUrl => "#{ENV['BASE_URL']}/menu-choice",
            :bargeIn => true,
            :endOnKey => '#'
          }
        ]}.to_json
        puts "AUTHENTICATED!!!"
      else
        render json: 
        {
          :type => 'ncco',
          :ncco => [
          {
            :action => 'talk',
            :text => 'Sorry your passphrase did not match. Please call back and try again.'
          }
        ]}.to_json
        puts "NOT AUTHENTICATED!!!"
      end
    else
      puts "SKIPPED OVER IS_AUTHENTICATED? METHOD"
    end
  end

  def record
    if params['recording_url']
      file = Nexmo.files.save(params['recording_url'], 'passphrase.wav')
    end
  end
      
  def menu
    case params['dtmf']
    when '1'
      response = get_sensibo_status("#{ENV['SENSIBO_ID']}")
      byebug
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

  def is_authenticated?(audio_file)
    transcribed = ibm_speech_to_text(audio_file)
    ENV['SECRET_WORD'] == transcribed
  end

  def ibm_speech_to_text(file)
    speech_to_text = IBMWatson::SpeechToTextV1.new(
      authenticator: ibm_authenticator
    )
    speech_to_text.service_url = "#{ENV['WATSON_API_URL']}"
    recognition = ''
    File.open(Dir.getwd + "/#{file}") do |audio_file|
      recognition = speech_to_text.recognize(
        audio: audio_file,
        content_type: "audio/wav",
        model: 'en-US_BroadbandModel'
      ).result
    end
    recognition['results'][0]['alternatives'][0]['transcript'].strip
  end

  def ibm_authenticator
    authenticator = IBMWatson::Authenticators::IamAuthenticator.new(
      apikey: "#{ENV['WATSON_API_KEY']}"
    )
  end

  def get_sensibo_status(id)
    require 'net/https'

    begin
        uri = URI("#{ENV['SENSIBO_API_URL']}/#{id}")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        req = Net::HTTP::Get.new(uri.path, {'Content-Type' => 'application/json'})
        res = http.request(req)
        puts JSON.parse(res.body)
    rescue => e
        puts "failed #{e}"
    end
  end

  def welcome_text
    <<~HEREDOC
    Hi! This is your air conditioner. 
    Please authenticate before continuing by saying your password at the beep. 
    When you are done please enter the hash key.
    HEREDOC
  end

  def menu_options_text
    <<~HEREDOC
    Thank you for authenticating. 
    Please choose from the following options: 
    Press 1 and the hash symbol for my current status
    Press 2 and the hash symbol to turn me on
    Press 3 and the hash symbol to turn me off
    Or hang up at anytime to end this call
    HEREDOC
  end

end