#coding:utf-8

require'base64'
require'openssl'
require'uri'
require'json'
require'net/http'

class RTwitter
	
	attr_reader :consumer_key,:consumer_key_secret,:access_token,:access_token_secret,:user_id,:screen_name
	
	def initialize(ck ,cks ,at = nil ,ats = nil)
		@ck = ck
		@cks = cks
		@at = at
		@ats = ats
	end
	
	def login(screen_name,password)

		request_token
		cookie = Hash.new
		response = get_request('https://api.twitter.com/oauth/authorize',"oauth_token=#{@request_token}",Hash.new)
		response.get_fields('Set-Cookie').each{|str|
			k,v = str[0...str.index(';')].split('=')
			cookie[k] = v
		}
		cookie = cookie.map{|k,v|
			"#{k}=#{v}"
		}.join(';')
		m = response.body.match(/<input name="authenticity_token" type="hidden" value="(.+?)" \/>/)
		authenticity_token = m[1]
		body = {
			'authenticity_token' => authenticity_token,
			'oauth_token' => @request_token,
			'session[username_or_email]' => screen_name,
			'session[password]' => password
		}
		body = join_body(body)
		response = post_request('https://api.twitter.com/oauth/authorize',body,{'Cookie' => cookie})
		m = response.body.match(/<kbd aria-labelledby="code-desc"><code>(.+?)<\/code><\/kbd>/)
		pin = m[1]
		access_token(pin)

	end

	def xauth(screen_name,password)

		additional_params = {
			'x_auth_mode' => 'client_auth',
			'x_auth_username' => screen_name,
			'x_auth_password' => password
		}
		oauth_params = oauth
		oauth_params.delete('oauth_token')
		base_params = oauth_params.merge(additional_params)
		base_params = Hash[base_params.sort]
		query = join_query(base_params)
		url = 'https://api.twitter.com/oauth/access_token'
		base = 'POST&' + escape(url) + '&' + escape(query)
		key = @consumer_key_secret + '&'
		oauth_params['oauth_signature'] = Base64.encode64(OpenSSL::HMAC.digest("sha1",key, base)).chomp
		header = {'Authorization' => 'OAuth ' + join_header(oauth_params)}
		body = join_body(additional_params)
		response = post_request(url,body,header)
		access_tokens = response.body.split('&')
		@access_token = access_tokens[0].split('=')[1]
		@access_token_secret = access_tokens[1].split('=')[1]
		@user_id = access_tokens[2].split('=')[1]
		@screen_name = access_tokens[3].split('=')[1]

	end

	def request_token

		oauth_params = oauth
		oauth_params.delete('oauth_token')
		oauth_params['oauth_callback'] = 'oob'
		base_params = Hash[oauth_params.sort]
		query = join_query(base_params)
		url = 'https://api.twitter.com/oauth/request_token'
		base = 'POST&' + escape(url) + '&' + escape(query)
		key = @cks + '&'
		oauth_params['oauth_signature'] = Base64.encode64(OpenSSL::HMAC.digest("sha1",key, base)).chomp
		header = {'Authorization' => 'OAuth ' + join_header(oauth_params)}
		body = ''
		response = post_request(url,body,header)

		request_tokens = response.body.split('&')
		@request_token = request_tokens[0].split('=')[1]
		@request_token_secret = request_tokens[1].split('=')[1]

		return "https://api.twitter.com/oauth/authenticate?oauth_token=#{@request_token}"

	end

	def access_token(pin)

		oauth_params = oauth
		oauth_params.delete('oauth_token')
		oauth_params['oauth_verifier'] = pin.chomp
		oauth_params['oauth_token'] = @request_token
		base_params = Hash[oauth_params.sort]
		query = join_query(base_params)
		url = 'https://api.twitter.com/oauth/access_token'
		base = 'POST&' + escape(url) + '&' + escape(query)
		key = @cks + '&' + @request_token_secret
		oauth_params['oauth_signature'] = Base64.encode64(OpenSSL::HMAC.digest("sha1",key, base)).chomp
		header = {'Authorization' => 'OAuth ' + join_header(oauth_params)}
		body = ''
		response = post_request(url,body,header)

		access_tokens = response.body.split('&')
		@at = access_tokens[0].split('=')[1]
		@ats = access_tokens[1].split('=')[1]
		@user_id = access_tokens[2].split('=')[1]
		@screen_name = access_tokens[3].split('=')[1]
	end


	def post(endpoint,additional_params = Hash.new)

		oauth_params = oauth
		base_params = oauth_params.merge(additional_params)
		base_params = Hash[base_params.sort]
		query = join_query(base_params)
		url = url(endpoint)
		base = 'POST&' + escape(url) + '&' + escape(query)
		key = @cks + '&' + @ats
		oauth_params['oauth_signature'] = Base64.encode64(OpenSSL::HMAC.digest("sha1",key, base)).chomp
		header = {'Authorization' => 'OAuth ' + join_header(oauth_params)}
		body = join_body(additional_params)
		response = post_request(url,body,header)
		return JSON.parse(response.body)

	end
	
	def get(endpoint,additional_params = Hash.new)

		oauth_params = oauth
		base_params = oauth_params.merge(additional_params)
		base_params = Hash[base_params.sort]
		query = join_query(base_params)
		url = url(endpoint)
		base = 'GET&' + escape(url) + '&' + escape(query)
		key = @cks + '&' + @ats
		oauth_params['oauth_signature'] = Base64.encode64(OpenSSL::HMAC.digest("sha1",key, base)).chomp
		header = {'Authorization' => 'OAuth ' + join_header(oauth_params)}
		body = join_body(additional_params)
		response = get_request(url,body,header)
		return JSON.parse(response.body)

	end
	
	def streaming(endpoint,additional_params = Hash.new)
		
		oauth_params = oauth
		base_params = oauth_params.merge(additional_params)
		base_params = Hash[base_params.sort]
		query = join_query(base_params)
		url = url(endpoint)
		base = 'GET&' + escape(url) + '&' + escape(query)
		key = @cks + '&' + @ats
		oauth_params['oauth_signature'] = Base64.encode64(OpenSSL::HMAC.digest("sha1",key, base)).chomp
		header = {'Authorization' => 'OAuth ' + join_header(oauth_params)}
		body = join_body(additional_params)
		buffer = ''
		streaming_request(url,body,header){|chunk|
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
		return response
	
	end

	def streaming_request(url,body,header)
		
		uri = URI.parse(url)
		https = Net::HTTP.new(uri.host, uri.port)
		https.use_ssl = true
		https.verify_mode = OpenSSL::SSL::VERIFY_NONE
		request = Net::HTTP::Get.new(uri.path + '?' + body,header)
		https.request(request){|response|
			response.read_body{|chunk|
				yield chunk
			}
		}
	
	end

	def oauth
		return {
			'oauth_consumer_key'     => @ck,
			'oauth_signature_method' => 'HMAC-SHA1',
			'oauth_timestamp'        => Time.now.to_i.to_s,
			'oauth_version'          => '1.0',
			'oauth_nonce'            => Random.new_seed.to_s,
			'oauth_token'            => @at
		}
	end

	def url(endpoint)
		
		list = {
			'media/upload'    => 'https://upload.twitter.com/1.1/media/upload.json',
			'statuses/filter' => 'https://stream.twitter.com/1.1/statuses/filter.json',
			'statuses/sample' => 'https://stream.twitter.com/1.1/statuses/sample.json',
			'user'            => 'https://userstream.twitter.com/1.1/user.json',
			'site'            => 'https://sitestream.twitter.com/1.1/site.json'
		}
		if list.include?(endpoint)
			return list[endpoint]
		else
			return "https://api.twitter.com/1.1/#{endpoint}.json"
		end

	end

	def join_query(params)
		
		query = params.map{|key,value|
			"#{escape(key)}=#{escape(value)}"
		}.join('&')
		return query
	
	end

	def join_header(params)
		
		header = params.map{|key,value|
			"#{escape(key)}=\"#{escape(value)}\""
		}.join(',')
		return header
	
	end

	def join_body(params)
		
		body = params.map{|key,value|
			"#{escape(key)}=#{escape(value)}"
		}.join('&')
		return body
	
	end

end

