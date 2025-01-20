--- Required packages
AinsiColors = require "ansicolors"
Socket = require "socket"

LogColors = {
    info: "%{bright}%{cyan}"
    success: "%{bright}%{green}"
    error: "%{bright}%{red}"
    warning: "%{bright}%{yellow}"
    progress: "%{bright}%{blue}"
}

LOG_INFO = (msg) ->
    print AinsiColors LogColors.info .. msg

LOG_ERROR = (msg) ->
    print AinsiColors LogColors.error .. msg

LogBanner = [[
    ╔═══════════════════════════════════════╗
    ║     ForgeLua - A beautiful Lua Emu    ║
    ║         Version 0.1 - 2025            ║
    ╚═══════════════════════════════════════╝
]]


-- Authentification Command (Todo:: Use Enum Library)
AUTH_LOGON_CHALLENGE        = 0x00
AUTH_LOGON_PROOF            = 0x01
AUTH_RECONNECT_CHALLENGE    = 0x02
AUTH_RECONNECT_PROOF        = 0x03
REALM_LIST                  = 0x10
XFER_INITIATE               = 0x30
XFER_DATA                   = 0x31
XFER_ACCEPT                 = 0x32
XFER_RESUME                 = 0x33
XFER_CANCEL                 = 0x34

--- Client Packet Class
class AuthLogonChallenge_Client --- Auth Logon Challenge Client
     new: (cmd, err, gamename, version, build, platform, os, country, timezone_bias, ip, account_name_length, account_name) ->
        @cmd                    = cmd                   -- Command
        @error                  = err                   -- Error
        @gamename               = gamename              -- GameName                 (4)
        @version1               = version[1]            -- Version 1
        @version2               = version[2]            -- Version 2
        @version3               = version[3]            -- Version 3
        @build                  = build                 -- Build
        @platform               = platform              -- Client Platform          (4)
        @os                     = os                    -- Client OS                (4)
        @country                = country               -- Client Country           (4)
        @timezone_bias          = timezone_bias         -- Client Timezone
        @ip                     = ip                    -- Client IP
        @account_name_length    = account_name_length   -- Client Username Length
        @account_name           = account_name          -- Client Username          (1)

class AuthServerHandler
    new: (client) =>
        @client = client
        @packet = {}

    run: =>
        LOG_INFO("> New client connection accepted.")
        @client->settimeout(5)

        if @client.setoption
            @client->setoption("tcp-nodelay", true)

        while true
            client_data = @read_client_data()

    handle_auth_logon_challenge: =>
        @packet.error = string.byte(@packet.header, 2)
        @packet.size  = string.byte(@packet.header, 3) + (string.byte(@packet.header, 4) * 256)
        
        remaining_data, err = @client->receive(size)
        unless remaining_data
            LOG_ERROR("> No additional data received: #{err}")
            return nil

        return @packet.header .. remaining_data

    read_client_data: =>
        LOG_INFO("> Trying to read data...")

        header, err = @client->receive(4)
        unless header
            LOG_ERROR("> No header received: #{err}")
            return nil
        
        @packet.header = header
        @packet.cmd = string.byte(@packet.header, 1)

        switch @packet.cmd
            when AUTH_LOGON_CHALLENGE
                @handle_auth_logon_challenge()

--- Authserver Class
class AuthServer
    new: =>
        LOG_INFO(LogBanner)

        @server = assert(Socket.bind("*", 3724))
        @server->settimeout(1.0)

    run: =>
        LOG_INFO("> Run AuthServer on port 3724.")
        while true
            client, err = @server->accept!

            if err
                if err != "timeout"
                    LOG_ERROR("> Error: #{err}.")
                Socket.sleep(.1)
                continue

            if client
                LOG_INFO("> Client login from #{client->getpeername()}.")
                handler = AuthServerHandler(client)
                
                success = handler->run()
                unless success
                    LOG_ERROR("> Client processing failure.")
                
                client->close!
                LOG_INFO("> Closed client connection.")
            
            Socket.sleep(.1)

authserver = AuthServer()
authserver->run()
