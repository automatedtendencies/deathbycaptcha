require 'rest_client'
require 'json'
require 'digest/md5'

module DeathByCaptcha
  
  #
  # DeathByCaptcha HTTP API client
  #
  class HTTPClient < DeathByCaptcha::Client
    
    def get_user
      call('user', userpwd)
    end
    
    def get_captcha(cid)
      call("captcha/#{cid}")
    end

    def report(cid)
      call("captcha/#{cid}/report", userpwd)['is_correct']
    end
    
    def remove(cid)
      not call("captcha/#{cid}/remove", userpwd)['captcha']
    end
    
    def a(nome, test=false, valor="verdade")
      puts nome,test,valor
    end
    
    #
    # Protected methods.
    #
    protected
    
    def upload(captcha, options={})
      options = {:is_case_sensitive => false, :is_raw_content => false}.merge(options)
      data = userpwd
      data[:swid] = config.software_vendor_id
      data[:is_case_sensitive] = options[:is_case_sensitive] ? 1 : 0
      data[:captchafile] = load_file(captcha, options[:is_raw_content])
      response = call('captcha', data)
      return response if response['captcha']
    end
    
    #
    # Private methods.
    #
    private
    
    def call(cmd, payload={}, headers={})
      headers['Accept'] = config.http_response_type if headers['Accept'].nil?
      headers['User-Agent'] = config.api_version if headers['User-Agent'].nil?
      
      log('SEND', "#{cmd} #{payload}")
      
      begin
        url = "#{config.http_base_url}/#{cmd}"
        
        if payload.empty?
          response = RestClient.get(url, headers)
        else
          response = RestClient.post(url, payload, headers)
        end
        
        log('RECV', "#{response.size} #{response}")
        
        return JSON.load(response)
        
      rescue RestClient::Unauthorized => exc
        raise DeathByCaptcha::Errors::AccessDenied
      
      rescue RestClient::RequestFailed => exc
        raise DeathByCaptcha::Errors::AccessDenied
        
      else
        raise DeathByCaptcha::Errors::CallError
        
      end
      
      return {}
      
    end
    
  end
  
  
  def self.http_client(username, password, extra={})
    DeathByCaptcha::HTTPClient.new(username, password, extra)
  end
  
end