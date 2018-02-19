--[[ SYSTEM FUNCTIONS ]]
--[[ 
  || crucial for basic system functions, e.g.
  || * loading the bot configuration  (config)
  || * loading the bot's commands     (commands)
  || * activity logging               (log)
  || * deserializing quotes           (quotes)
  || * serializing quotes             (serialize)
--]] 


LOG           = nil
LOGFILE       = nil
LOGFILETEMP   = ""
LOGFILEOPENED = false

function config( data )
  for k,v in pairs( data ) do
    _G[k] = v
  end
  
  
  if not _G.LOGFILE then 
    _G.LOGFILE      = "bot.log" end
    
  if not _G.QUOTEFILE then 
    _G.QUOTEFILE    = "quotes.cfg" end
    
  if not _G.COMMANDSFILE then 
    _G.COMMANDSFILE = "commands.cfg" end
   
  if not _G._sizeFILES then
    _G._sizeFILES   = {
      "StinkerBot.lua",
      "bot.cfg",
      "quotes.cfg",
      "commands.cfg",
    } end
   
   
  LOG           = io.open( LOGFILE, "a" )
  LOGFILEOPENED = true
end

function commands( commandsData )
  for k,v in pairs( commandsData ) do
    COMMANDS[k] = v
  end
end

function log( message, level )
  if ((level == "debug") and (DEBUG ~= true)) then return end
  local levels     = {
    info  = "INFO",
    warn  = "WARNING",
    debug = "DEBUG",
    err   = "ERROR",
  }
  
  local sLevel = levels[level]
  if not sLevel then
    log(  "Attempted to use unknown logging level "
          .. tostring(level)
          .. "! Defaulting to WARNING…", "warn" )
    print(debug.traceback())
    sLevel = levels["warn"]
  end
  
	local newMessage = 
    os.date("%c")
    .. " ["
    .. os.clock()
    .. "] \t"
    .. "|" .. sLevel .. "|\t"
    .. tostring(message)
	print( newMessage )
  
  if not LOGFILEOPENED then
    LOGFILETEMP = LOGFILETEMP .. newMessage
  elseif #LOGFILETEMP ~= 0 then
    LOG:write( LOGFILETEMP )
    LOGFILETEMP = ""
  else
    LOG:write( newMessage .. "\n" )
    LOG:flush()
  end
end

function quotes ( data )
	for k,v in ipairs( data ) do

		QUOTES[k] = {}
		local quote = QUOTES[k]
		
		log( ">>Quote #" .. k, "debug" )
	
		quote.text = v.quote or v
		log( ">>Text: " .. quote.text, "debug" )

    quote.by   = v.by   or nil
		if quote.by then
      log( ">>By: " .. tostring(quote.by), "debug" )
    end
    
    quote.attachments = v.attachments or nil
    if quote.attachments then
      log( ">>Attachments: " .. tostring(#quote.attachments), "debug" )
    end

  end
end

function serialize ()

	local header =
[[-- Lua file for initializing the BeeshQuotes™ system
-- if you want to manually add quotes, this is the place to do it

-- Ask away on Discord if you need help or want to know stuff. ;)

quotes {

]]

	local out = io.open( QUOTEFILE, "w" )
	out:write( header )

	for k,v in ipairs( QUOTES ) do

		if not v.by and not v.attachments then
			out:write('\t"' .. v.text .. '",\n\n')
		else
      local text = "\t{\n\n\t\tquote = [[" .. v.text .. "]],\n"
			if v.by then
        text = text .. "\t\tby    = [[" .. v.by .. "]],\n"
      end
      if v.attachments and #v.attachments > 0 then
        text =  text .. "\t\tattachments = {\n"
        for _,attachmFile in ipairs(v.attachments) do
          text =  text .. "\t\t\t[["
                  .. attachmFile
                  .. "]],\n"
        end
        text = text .. "\t\t},\n"
      end
      text = text .. "\n\t},\n\n"
      out:write(text)
		end

	end

	out:write("}")

	out:flush()
	out:close()
end

-- for some reason, we have to manually add these functions to the global table
-- no idea why… implementation error by luvit???
_G.log      = log
_G.quotes   = quotes
_G.config   = config
_G.commands = commands
_G.serialize= serialize



--[[ INTERNAL PREPARATIONS ]]
--[[ 
  || preparation of various variables, some of which should get
  || put into separate modules some time in the future
  || * the bot's ID for later ignoring of echo  (SELF)
  || * the table for all quotes                 (QUOTES)
  || * the table of the commands + help data    (COMMANDS)
  || * the order/structure of the help output   (ORDER)
--]]


_G.SELF     = nil
_G.QUOTES   = {}
_G.COMMANDS = {}



--[[ STARTUP ]]
--[[ 
  || here we run external configs and gather data
  || we also initialize some Discordia stuff, connect the client
  || and define hooks for events
  || * loading bot configurations               (dofile( "bot.cfg" ))
  || * loading quotes                           (dofile( QUOTEFILE ))
  || * hook on successful startup               (client:on("ready", …))
  || * hook on any text input                   (client:on("messageCreate", …))
--]]


dofile( "bot.cfg" )

log( "=Successfully loaded bot.cfg, logging started!", "info" )

log( ">Data initialization starting…", "info" )

log( ">Loading known quotes…", "info" )
dofile( QUOTEFILE )
log( "<Loaded known quotes!", "info" )

log( ">Loading commands…", "info" )
dofile( COMMANDSFILE )
log( "<Loaded commands!", "info" )

log( "<Data initialization completed!", "info" )

--


log( ">Startup entered!", "info" )

log( ">Loading Discordia module…", "debug" )
_G.discordia = require("discordia")
log( "<Loaded Discordia module!", "debug" )

log( ">Creating Discordia Client…", "debug" )
_G.client = discordia.Client(
	{
		logFile = LOGFILE
	})
log( "<Created Discordia Client!", "debug" )



client:on("ready", function()
	SELF = client.user.id
	client:setGame( "!sbl_help" )
	log( "=Logged in as " .. client.user.username .. " (ID: " .. SELF .. ")", "info" )
  
  log( ">Running self-test…", "info" )
  
  local testableCommands =  {
                              "ping",
                              "message",
                              "quote",
                              "help",
                              "_size",
                            }
  local channelFake = {
                        channel   = {
                                      send =  function( _, text )
                                                log("<"
                                                    .. tostring(text), "debug" )
                                              end,
                                    },
                        arguments = "test",
                      }
                      
  for k,v in ipairs( testableCommands ) do
    log( ">" .. v, "debug" )
    COMMANDS[v].fn(channelFake)
  end
  
  log( "<Self-test completed successfully!", "info" )
  
  log( "<Startup completed successfully! Have fun ;)", "info" )
  
end)



client:on("messageCreate", function(message)
	log( ">Message incoming…", "debug" )
	
	local data = {}
	data.user			    = message.author
	data.channel			= message.channel
	data.content			= message.content
	data.command, data.arguments	= data.content:match( "^![sS][bB][lL]_(%S*)%s*(.*)$" )
  data.attachments  = message.attachments or {}
	
	log( "<Message received!", "debug" )

	if not data.command or data.user.id == SELF
    then return end
	

	--COMMAND PREFIX FOUND

	data.command = data.command:lower()


	log( ">Command found, working…", "info" )

	log( ">USER:\t" .. data.user.username .. " (" .. tostring(data.user) .. ")", "debug" )
	log( ">CHANNEL:\t" .. data.channel.name .. " (" .. tostring(data.channel) .. ")", "debug" )
	log( ">MESSAGE:\t" .. tostring(data.content), "debug" )
  log( ">ATTACHMENTS:\t" .. tostring(#data.attachments), "debug" )
	log( ">COMMAND:\t" .. data.command, "info" )
	log( ">ARGUMENTS:\t" .. tostring(data.arguments), "info" )

  local command = COMMANDS[data.command]
  if command ~= nil
    then command.fn( data ) end
  
  log( "<Finished working on command!", "info" )
end)

client:run( TOKEN )