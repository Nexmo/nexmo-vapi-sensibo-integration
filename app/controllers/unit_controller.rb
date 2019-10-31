require 'json'
require 'pry'
class UnitController < ActionController::Base
  skip_before_action :verify_authenticity_token
  AcUnit = Sensibo.new(ENV['SENSIBO_API_KEY'], ENV['SENSIBO_ID'])

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
          :text => AcUnit.menu_options_text,
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
      response = AcUnit.get_status
      render json:
      [
        {
          :action => 'talk',
          :text => AcUnit.ac_info_text(response)
        }
      ]
    when '2'
      response = AcUnit.update_status(true)
      if response['status'] == 'success'
        render json:
        [
          {
            :action => 'talk',
            :text => 'I am now on. Have a cool day!'
          }
        ]
      else
        render json:
        [
          {
            :action => 'talk',
            :text => 'Oops. Something went wrong. Please call back and try again.'
          }
        ]
      end
    when '3'
      response = AcUnit.update_status(false)
      if response['status'] == 'success'
        render json:
        [
          {
            :action => 'talk',
            :text => 'I am now off. Have a warm day!'
          }
        ]
      else
        render json:
        [
          {
            :action => 'talk',
            :text => 'Oops. Something went wrong. Please call back and try again.'
          }
        ]
      end
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

  def welcome_text
    <<~HEREDOC
    Hi! This is your air conditioner. 
    Please authenticate before continuing by entering your passkey. 
    When you are done please enter the hash key.
    HEREDOC
  end
end