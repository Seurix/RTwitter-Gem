#coding:utf-8

require'./RTwitter.rb'
require'pp'

rt = RTwitter.new(ck,cks,at,ats)

# Streaming
rt.streaming('statuses/sample'){|status|
	if.include?('text')
		pp status
	end
}

# image uploading(You can upload 4 images)
text = 'What you want to tweet'
image1 = 'filename'
image2 = 'filename'
rt.post('statuses/update',{'status' => text,'media_ids' => [image1,image2].map{|value| rt.post_media(value)['media_id'] }.join(',')})
