#coding:utf-8

require'./RTwitter.rb'
require'pp'

rt = RTwitter.new(ck,cks,at,ats)

# Streaming
rt.streaming('statuses/sample'){|status|
	if status.include?('text')
		pp status
	end
}
