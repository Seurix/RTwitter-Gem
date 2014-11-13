#coding:utf-8

require'base64'
require'openssl'
require'uri'
require'json'
require'net/http'

class RTwitter
	
	def initialize(ck,cks,at,ats)
		@ck = ck
		@cks = cks
		@at = at
		@ats = ats
	end

	def post(endpoint,additional_params = Hash.new)
		
		oauth_params = oauth
		base_params = oauth_params.merge(additional_params)
		key_params = [@cks,@ats]
		base_params = Hash[base_params.sort]
		query = base_params.map{|key,value|
			"#{escape(key)}=#{escape(value)}"
		}.join('&')
		url = "https://api.twitter.com/1.1/#{endpoint}.json"
		base = 'POST&' + escape(url) + '&' + escape(query)
		key = key_params[0] + '&' + key_params[1]
		signature = Base64.encode64(OpenSSL::HMAC.digest("sha1",key, base)).chomp
		oauth_params['oauth_signature'] = signature
		header = oauth_params.map{|key,value|
			"#{escape(key)}=\"#{escape(value)}\""
		}.join(',')
		header = {'Authorization' => 'OAuth ' + header}
		body = additional_params.map{|key,value|
			"#{escape(key)}=#{escape(value)}"
		}.join('&')
		response = post_request(url,body,header)
		return response
	end
	
	def get(endpoint,additional_params = Hash.new)
		
		oauth_params = oauth
		base_params = oauth_params.merge(additional_params)
		key_params = [@cks,@ats]
		base_params = Hash[base_params.sort]
		query = base_params.map{|key,value|
			"#{escape(key)}=#{escape(value)}"
		}.join('&')
		url = "https://api.twitter.com/1.1/#{endpoint}.json"
		base = 'GET&' + escape(url) + '&' + escape(query)
		key = key_params[0] + '&' + key_params[1]
		signature = Base64.encode64(OpenSSL::HMAC.digest("sha1",key, base)).chomp
		oauth_params['oauth_signature'] = signature
		header = oauth_params.map{|key,value|
			"#{escape(key)}=\"#{escape(value)}\""
		}.join(',')
		header = {'Authorization' => 'OAuth ' + header}
		body = additional_params.map{|key,value|
			"#{escape(key)}=#{escape(value)}"
		}.join('&')
		response = get_request(url,body,header)
		return response
	end
	
	def post_media(image)
		
		endpoint = "https://upload.twitter.com/1.1/media/upload.json"
		additional_params = {'media'=> Base64.encode64(File.new(image).read).chomp }
		oauth_params = oauth
		base_params = oauth_params.merge(additional_params)
		key_params = [@cks,@ats]
		base_params = Hash[base_params.sort]
		query = base_params.map{|key,value|
			"#{escape(key)}=#{escape(value)}"
		}.join('&')
		url = "https://upload.twitter.com/1.1/media/upload.json"
		base = 'POST&' + escape(url) + '&' + escape(query)
		key = key_params[0] + '&' + key_params[1]
		signature = Base64.encode64(OpenSSL::HMAC.digest("sha1",key, base)).chomp
		oauth_params['oauth_signature'] = signature
		header = oauth_params.map{|key,value|
			"#{escape(key)}=\"#{escape(value)}\""
		}.join(',')
		header = {'Authorization' => 'OAuth ' + header}
		body = additional_params.map{|key,value|
			"#{escape(key)}=#{escape(value)}"
		}.join('&')
		response = post_request(url,body,header)
		return response
	end

	def streaming(endpoint,additional_params = Hash.new)
		endpoint = streaming_url(endpoint)
		oauth_params = oauth
		base_params = oauth_params.merge(additional_params)
		key_params = [@cks,@ats]
		base_params = Hash[base_params.sort]
		query = base_params.map{|key,value|
			"#{escape(key)}=#{escape(value)}"
		}.join('&')
		base = 'GET&' + escape(endpoint) + '&' + escape(query)
		key = key_params[0] + '&' + key_params[1]
		signature = Base64.encode64(OpenSSL::HMAC.digest("sha1",key, base)).chomp
		oauth_params['oauth_signature'] = signature
		header = oauth_params.map{|key,value|
			"#{escape(key)}=\"#{escape(value)}\""
		}.join(',')
		header = {'Authorization' => 'OAuth ' + header}
		body = additional_params.map{|key,value|
			"#{escape(key)}=#{escape(value)}"
		}.join('&')
		
		uri = URI.parse(endpoint)
		https = Net::HTTP.new(uri.host, uri.port)
		https.use_ssl = true
		https.verify_mode = OpenSSL::SSL::VERIFY_NONE
		request = Net::HTTP::Get.new(uri.path + '?' + body,header)
		buffer = ''
		https.request(request){|response|
			response.read_body{|chunk|
				if buffer != ''
				chunk = buffer + chunk
				buffer = ''
				end

				begin
					status = JSON.parse(chunk)
				rescue
					buffer << chunk
					next
				end
					
				yield status
			}
		}
	end

	private

	RESERVED_CHARACTERS = /[^a-zA-Z0-9\-\.\_\~]/

	def escape(value)
		URI.escape(value.to_s, RESERVED_CHARACTERS)
	end

	def post_request(url,body,header)
		uri = URI.parse(url)
		https = Net::HTTP.new(uri.host, uri.port)
		https.use_ssl = true
		https.verify_mode = OpenSSL::SSL::VERIFY_NONE
		response = https.start{|https|
			https.post(uri.path,body,header)
		}
		begin
			response = JSON.parse(response.body)
		rescue
			return response.body
		end
		return response
	end

	def get_request(url,body,header)
		uri = URI.parse(url)
		https = Net::HTTP.new(uri.host, uri.port)
		https.use_ssl = true
		https.verify_mode = OpenSSL::SSL::VERIFY_NONE
		response = https.start{|https|
			https.get(uri.path + '?' + body, header)
		}
		begin
			response = JSON.parse(response.body)
		rescue
			return response.body
		end
		return response
	end

	def oauth
		{
			'oauth_consumer_key'     => @ck,
			'oauth_signature_method' => 'HMAC-SHA1',
			'oauth_timestamp'        => Time.now.to_i.to_s,
			'oauth_version'          => '1.0',
			'oauth_nonce'            => Random.new_seed.to_s,
			'oauth_token'            => @at
		}
	end

	def streaming_url(endpoint)
		list = {
			'statuses/filter' => 'https://stream.twitter.com/1.1/statuses/filter.json',
			'statuses/sample' => 'https://stream.twitter.com/1.1/statuses/sample.json',
			'user' => 'https://userstream.twitter.com/1.1/user.json',
			'site' => 'https://sitestream.twitter.com/1.1/site.json'
		}
		if list.include?(endpoint)
			return list[endpoint]
		else
			return endpoint
		end
	end

end
