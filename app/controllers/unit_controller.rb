require "ibm_watson/authenticators"
require "ibm_watson/speech_to_text_v1"
require 'json'
class UnitController < ActionController::Base
  skip_before_action :verify_authenticity_token

  def answer
    render json:
    [
      {
        :action => 'conversation',
        :name => 'sensibo-conversation'
      },
      { 
        :action => 'talk', 
        :text => welcome_text
      },
      {
        :action => 'record',
        :eventUrl => ["#{ENV['BASE_URL']}/authenticate"],
        :format => 'wav',
        :beepStart => true,
        :endOnKey => '#'
      }
    ].to_json
  end

  def event
    puts params
  end

  def authenticate
    Nexmo.files.save(params['recording_url'], 'passphrase.wav')
    @audio_file = 'passphrase.wav'
    if is_authenticated?(@audio_file)
      render json: 
      [
        {
          :action => 'talk',
          :text => menu_options_text
        },
        {
          :action => 'input',
          :eventUrl => "#{ENV['BASE_URL']}/menu-choice"
          :bargeIn => true,
          :endOnKey => '#'
        }
      ]
    else
      render json: 
      [
        {
          :action => 'talk',
          :text => 'Sorry your passphrase did not match. Please call back and try again.'
        }
      ]
    end
  end

  def menu
  end

  private

  def is_authenticated?(audio_file)
    transcribed = ibm_speech_to_text(@audio_file)
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
        timestamps: true,
        word_confidence: true,
        model: 'en-US_BroadbandModel'
      ).result
    end
    recognition['results']['transcript']
  end

  def ibm_authenticator
    authenticator = IBMWatson::Authenticators::IamAuthenticator.new(
      apikey: "#{ENV['WATSON_API_KEY']}"
    )
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