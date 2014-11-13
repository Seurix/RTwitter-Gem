# RTwitter

You can use REST and **Streaming** API.

## How to use ?  

+ POST request  
`require'./RTwitter.rb'`  
`rt = RTwitter.new(ck,cks,at,ats)`  
`result = rt.post(endpoint,{parameter => value})`  
example...  
`endpoint = 'statuses/update'`  
`parameter = 'status'`  
`value = 'Hello World!'`  

+ GET request  
`require'./RTwitter.rb'`  
`rt = RTwitter.new(ck,cks,at,ats)`  
`result = rt.get(endpoint,{parameter => value})`  
example...  
`endpoint = 'users/show'`  
`parameter = 'screen_name'`  
`value = 'CIA'`  

+ Streaming  
`require'./RTwitter.rb'`  
`rt = RTwitter.new(ck,cks,at,ats)`  
`rt.streaming(endpoint,{parameter => value}){|status| p status }`  
example...  
`endpoint = 'statuses/filter'`  
`parameter = 'track'`  
`value = 'Hello'`  
