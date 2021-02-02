require 'net/https'
require 'json'

class Sensibo
  attr_reader :api_key, :id

  def initialize(api_key, id)
    @api_key = api_key
    @id = id
  end

  def get_status
    begin
        uri = URI("#{ENV['SENSIBO_API_URL']}/#{self.id}?fields=*&apiKey=#{self.api_key}")
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

  def update_status(state)
    begin
      uri = URI("#{ENV['SENSIBO_API_URL']}/#{self.id}/acStates/on?apiKey=#{self.api_key}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      req = Net::HTTP::Patch.new(uri, {'Content-Type' => 'application/json'})
      req.body = {"newValue" => state}.to_json
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

  def menu_options_text
    <<~HEREDOC
    Thank you for authenticating. 
    Please choose from the following options: 
    Say 1 for my current status
    Say 2 to turn me on
    Say 3 to turn me off
    Or hang up at anytime to end this call
    HEREDOC
  end
end