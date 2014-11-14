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
