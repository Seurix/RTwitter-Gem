# RTwitter

You can use REST and **Streaming** API.

## How to use ?

+ Require this File  
`require'path/to/RTwitter.rb'`

+ New Instance  
If you have access\_token and access\_token\_secret  
`rt = RTwitter.new(ck,cks,at,ats)`  
If you don't have...  
`rt = RTwitter.new(ck,cks)`  
`puts rt.request_token`  
`rt.access_token(STDIN.gets)`  
or para-xauth  
`rt = RTwitter.new(ck,cks)`  
`rt.login(screen_name,password)`  
or xauth(only official key)  
`rt = RTwitter(ck,cks)`  
`rt.xauth(screen_name,password)`  

+ POST request  
`result = rt.post(endpoint,{parameter => value})`  
example...  
`endpoint = 'statuses/update'`  
`parameter = 'status'`  
`value = 'Hello World!'`  

+ GET request  
`result = rt.get(endpoint,{parameter => value})`  
example...  
`endpoint = 'users/show'`  
`parameter = 'screen_name'`  
`value = 'CIA'`  

+ Streaming  
`rt.streaming(endpoint,{parameter => value}){|status| p status }`  
example...  
`endpoint = 'statuses/filter'`  
`parameter = 'track'`  
`value = 'Hello'`  
