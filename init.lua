-- NeoPixel Controller and Weather Display
-- See video at https://www.youtube.com/watch?v=zxBsWhdXvhw 
-- Uses 12 Neopixel ring, so can emulate a clock...
-- Two modes of operation
-- 1. Standalone Wifi Station. Serves webpage via 192.168.4.1 and allows control of NeoPixel ring of Leds
--    User selects colour, 
--    Which LEDs to light, 
--    Direction(Clockwise or Anti-Clockwise) 
--    Speed - transition speed  (ms) 
--    and Mode:
--    Loop - spins leds round display
--    Fade = Leds fade in and out
--    Step - move one LED at a time. 
--    or IOT (Internet of Things)
-- 2. Select the IOT on the webpage. 
--    This opens a form to specify an internet connected Wifi
--    Form allows you to specify City and Country Code 
--    Forms allows choice of displaying local time or temperature
--    Time and Weather from location is displayed on NeoPixel Ring.
--    Uses the Weather Underground API so API key needs to be added to code. 
-- Runs on Nodemcu




-- Process the weather undergound data
function processIt (payload)
daycolours = {{66,65,63},{195,154,197},{135,86,232},{102,17,187}}      -- colours for each 6 hours
tempcolours ={{0,0,146},{0,12,146},{66,91,0},{0,135,0}}                -- temperatures for <0,0-10,10-20,20+ (G,R,B)
rec_count=rec_count+1    
if rec_count == 3 then                                                 -- did we receive enough data from wunderground
success = true 
clearbuf()                                                              -- clear the Leds
hh,mm = string.match(payload,"(%d+):(%d+):",string.find(payload,"local_time_rfc822")); -- extract local time 
tempC = string.match(payload,":(-?%d+.?%d+),",string.find(payload,"temp_c"));          -- extract temperature

if SHOW == "Time" then                                                  -- Display Time chosen on form 
    h1_24 = tonumber(hh)                                                -- Hours
    m1 = tonumber(mm)                                                   -- Minutes
    if h1_24 % 12 == 0 then h1_12 = 12 else h1_12 = h1_24%12 end        -- cater for 12 O'clock
    if (m1%5) == 0 then d1 = 5                                          -- position for 5 past 
    elseif (m1%5) <= 2 then d1 = math.floor(m1/5)                       -- deal with minutes close to 60
    elseif (m1%5) > 2 then d1 = math.ceil(m1/5) end 
    local colourindex = ((h1_24/6)> 0 and math.floor(h1_24/6) or 0)+1   -- Get Colour 
    clearbuf()                                                          -- clear the Leds
    buffer:set(h1_12, daycolours[colourindex]);                         -- Set hour LED
    buffer:set(d1, 0,25,0 ); ws2812.write(buffer);                      -- Set minute 
else
    t1=  tonumber(tempC)                                                -- Display Temp
    local numlights  = (math.abs(t1/5)> 0 and math.floor(t1/5) or 0)    -- How many lights to illuminate
    clearbuf()                                                          -- clear the lights
    local tempindex = math.min((math.abs(t1/10)> 0 and math.ceil(t1/10) or 0)+1,4) -- work our colour
    buffer:set(12,tempcolours[tempindex])                               -- set colour
     if t1 >= 0 then                                                    -- temperature > 0, start at 1 clock position
        for i =1,numlights do buffer:set(i,tempcolours[tempindex]) end 
    else                                                                -- temperature < 0, end at 12 clock position
        numlights = 12+numlights
        for i =numlights,11 do buffer:set(i,tempcolours[tempindex]) end 
    end 
    ws2812.write(buffer);                                               -- Display Leds
end 
else  
conn:send("OK\r\n");                                                    -- send HTML reposonse
end
end 
-- Get Wunderground data                                                
function getWeather(payload)                                            
    conn=net.createConnection(net.TCP, 0)                               -- create a connection
    conn:on("receive", function(conn,payload) processIt(payload) end  ) -- on receive, process the payload 
    conn:on("sent", function(conn, payload) end)                        -- send 
    conn:on("connection", function(sck, payload)                        -- once connected, send a get 
        success = false
        rec_count = 1 
        conn:send("GET "..CALL 
        .. " HTTP/1.1\r\n"
        .. "Host: " .. HOST .. "\r\n"
        .. "Connection: close \r\n"
        .. "Accept: */*\r\nUser-Agent: Mozilla/4.0 (compatible; esp8266 Lua; )\r\n\r\n") 
    end)
    conn:connect(80,HOST)  
end
-- Clear Neopixels
function clearbuf()
buffer:fill(0, 0, 0); ws2812.write(buffer); collectgarbage();
end 
-- Utility function to stop all timers
function stopallTimers()
if tmr.state(0) ~= nil then tmr.unregister(0) end
if tmr.state(1) ~= nil then tmr.unregister(1) end
if tmr.state(2) ~= nil then tmr.unregister(2) end

end 

wifi.setmode(wifi.STATIONAP);                                           -- Intial mode, esp12F launches its own WIFI 
cfg={};
-- ---------------------------------- 
-- Change ssid and pwd as required --
-- ----------------------------------
cfg.ssid="ESP12F";                                                      
cfg.pwd="########";
wifi.ap.config(cfg);                                                    -- Turn on SSID
ws2812.init();                                                          -- Initialise NeoPixels
i=0;
buffer = ws2812.newBuffer(12,3 );                                       
clearbuf()                                                              -- clear NeoPixels
local mytimer=tmr.create();
local httpRequest={};
httpRequest["/"]="index.htm";                                           -- display index.htm page if / specified
httpRequest["/index.htm"]="index.htm";                                  -- display index.htnm page if /index.htm
local getContentType={};
getContentType["/"]="text/html";
getContentType["/index.htm"]="text/html";
local filePos=0;
if srv~=nil then srv:close() end;
srv=net.createServer(net.TCP);                                              
srv:listen(80,function(conn)                                            -- Process the user submitted form
    conn:on ("receive", function(conn,request)
        if (string.find(request,"GET / HTTP/1.1",1,plain) ~=nil) then
           method, path = string.match(request,"([A-Z]+) (.+) HTTP")
        elseif (string.find(request,"POST / HTTP/1.1",1,plain) ~=nil) then
           method, path = string.match(request,"([A-Z]+) (.+) HTTP")
        elseif (string.find(request,"GET /favicon.ico HTTP/1.1",1,plain) ~=nil) then   
           method=""
        else 
        end  
        if method == "POST" then                                        -- Did they submit via the form
          local formDATA = {};  leds = {};
          for i=1,12,1 do leds[i]=0; end;                               -- turn off the Leds            
          for k, v in string.gmatch(request, "(%w+)=(%w+)&*") do         
             if k=="loc" then v = string.match(request,"loc=([^&]+)&") print(k,v)  end              -- get country
             if k=="ccode" then v = string.match(request,"ccode=([^&]+)") print(k,v)  end           -- get city code
             formDATA[k] = v;
             if string.match(k,"%d+") ~= nil  then leds[tonumber(string.match(k,"%d+"))] = 1; end;
          end  
          if formDATA["c"] == "Stop" then                               -- STOP option
             clearbuf()                                                 -- turn off Neopixels
             stopallTimers()                                            -- turn off all tmr
          elseif formDATA["c"] == "IOT" then                            -- IOT  option - connect to specified wifi and goto Wunderground.
            if (formDATA["ssid"] ~= nil and  formDATA["pwd"] ~= nil ) then -- simple validation
                stopallTimers()                                         -- stop any timers that might be running
                clearbuf()                                              -- clear Neopixels
                LOCATION    = formDATA["loc"];                          -- country code for wundergound
                COUNTRYCODE = formDATA["ccode"];                        -- city code for wundeground 
                HOST = "api.wunderground.com"
                -- --------------------------------------------------------------------------------------
                -- REPLACE THE XXXXXX with your Weather Underground developer key. Register to get one --
                -- --------------------------------------------------------------------------------------
                
                CALL = "/api/XXXXXXXXXXXXXX/conditions/q/"..COUNTRYCODE.."/"..LOCATION..".json";
                SHOW = formDATA["show"]                                 
                wifi.sta.config(formDATA["ssid"],formDATA["pwd"]);      -- connect to internet connected wifi
                tmr.alarm(1, 1000, tmr.ALARM_AUTO, function()           -- timr to wait for IP           
                    if wifi.sta.getip()=="0.0.0.0" or wifi.sta.getip() == nil then  -- Need an IP to connect
                    else
                        getWeather(payload)                             -- retrieve details from wunderground into payload
                        tmr.stop(1)                                     -- stop the timer
                        tmr.alarm(0, 300 * 1000, 1, function() getWeather() end )  -- every 5 minutes, get weather details
                    end 
                end)
            end
           end 
           -- display the Leds
           displayIt(tonumber(formDATA["r"]),tonumber(formDATA["g"]),tonumber(formDATA["b"]),tonumber(formDATA["s"]),tonumber(formDATA["d"]),formDATA["c"],leds)
        end 
        if method == "GET" then                                         -- request to serve page that doesn't exist
            if getContentType[path] then
                requestFile=httpRequest[path];
                print("[Sending file "..requestFile.."]");            
                filePos=0;
                conn:send("HTTP/1.1 200 OK\r\nContent-Type: "..getContentType[path].."\r\n\r\n");            
            else
                print("[File "..path.." not found]");
                conn:send("HTTP/1.1 404 Not Found\r\n\r\n")
                conn:close();
                collectgarbage();
            end
        end     

    end)            
    conn:on("sent",function(conn)                                         -- how the htm file is served: in 1024 byte blocks.
        if requestFile then
            if file.open(requestFile,r) then
                file.seek("set",filePos);
                local partial_data=file.read(1024)
                file.close();
                if partial_data then
                    filePos=filePos+#partial_data;
                    print("["..filePos.." bytes sent]");
                    conn:send(partial_data);
                    if (string.len(partial_data)==1024) then 
                        return;
                    end
                   
                end
            else
                print("[Error opening file"..requestFile.."]");
            end
        end
        print("[Connection closed]");
        conn:close();
        collectgarbage();
    end)
end) 

--  Display user specified colours and pattern.
function  displayIt(r,g,b,speed,direction,cmd,leds )
       if tmr.state(mytimer) ~= nil then tmr.unregister(mytimer) end;   -- Disable timer that might be running
       if cmd == "Loop" then                                            -- LOOP option moves lights clockwise or anticlockwise. 
          clearbuf()
          i=1;
          if direction == 1 then                                        -- Clockwise so move trail of lights 
            mytimer:alarm(speed, tmr.ALARM_AUTO, function(t) i=i-1 ;  buffer:fade(2); buffer:set(i%buffer:size()+1,g,r,b); ws2812.write(buffer) end);
          else 
             mytimer:alarm(speed, tmr.ALARM_AUTO, function(t) i=i+1;  buffer:fade(2); buffer:set(i%buffer:size()+1,g,r,b); ws2812.write(buffer) end);          
          end   
             
       elseif cmd== "Fade" then                                         -- FADE options, Fade Up or Down...
        clearbuf()                                                      -- Clear Neopixels
        base_r, base_g, base_b = r,g,b;                                 -- State position
        freq=math.ceil(4000/math.max(base_r,base_g,base_b));            -- work out frequency
        direction="DOWN"
        mytimer:alarm(freq,tmr.ALARM_AUTO, function(t)                  -- Set up a timer to fade in or out, timer stops when options changed...
                                    if direction == "DOWN" and g==0 and r==0 and b==0 then direction = "UP";
                                    elseif direction == "UP" and  r == base_r and g == base_g and b==base_b then direction = "DOWN";
                                    end
                                    for j = 1, 12 do
                                        if leds[j] ~= 0 then            -- which of the LEDs has been selected via the form.
                                            g, r, b = buffer:get(j);    -- set GRB    
                                            if direction ==  "DOWN" then -- Fade down
                                                g = math.max(g-1,0);
                                                r= math.max(r-1,0);
                                                b = math.max(b-1,0);
                                             else                       -- Fade UP
                                                g =math.min(g+1,base_g);
                                                r =math.min(r+1,base_r);
                                                b =math.min(b+1,base_b);
                                             end
                                             buffer:set(j, g,r,b)
                                         end    
                                     end          
                                     ws2812.write(buffer);              -- Write to the buffer
                                 end);
       elseif cmd== "Step" then                                         -- STEP option: move selected LEDs forward or backward at specified Speed
          clearbuf()                                                    -- Clear neopixels
          setUpBuffer(g,r,b);                                           -- configure LEDS based on choices 
          if direction == 1 then                                        -- Clockwise, change at specified interval (speed from form)
             mytimer:alarm(speed, tmr.ALARM_AUTO, function(t) buffer:shift(-1, ws2812.SHIFT_CIRCULAR); ws2812.write(buffer) end);          
          else                                                          -- Anti-clockwise, change at specified interval (speed from form)
             mytimer:alarm(speed, tmr.ALARM_AUTO, function(t)  buffer:shift(1, ws2812.SHIFT_CIRCULAR); ws2812.write(buffer) end);          
          end 
       elseif cmd== "Light" then                                        -- Light Option, Light selected LEDS with  chosen colours
          setUpBuffer(g,r,b);
          ws2812.write(buffer);
       end 
end 
-- Configure colours for selected LEDS
function setUpBuffer(r,g,b)                                             -- Array of 12 LEDs specifies Green, Red and Blue for each LED                                  
             local j; 
             for j=1,12,1 do                                            
                 if leds[j] ~= 0  then                                  -- Is LED selected on form?
                    buffer:set(j,r,g,b);                                -- Assign colour based on form values
                    print("setting LED ",j)
                 else
                    buffer:set(j,0,0,0);                                -- Otherwise turn it off
                 end; 
                 ws2812.write(buffer);                                  -- Light Leds 
             end
end              



