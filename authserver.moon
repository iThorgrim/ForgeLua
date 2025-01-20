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
class Packet
    new: (data) =>
        @data = data
        @position = 1

    read_byte: =>
        byte = string.byte(@data, @position)
        @position += 1

        return byte

    read_bytes: (length) =>
        bytes = {}

        for i = 1, length
            bytes[i] = string.byte(@data, @position)
            @position += 1

        return bytes

    read_string: (length) =>
        result = ""

        for i = 1, length
            byte = string.byte(@data, @position)
            if byte
                @position += 1
                result ..= string.char(byte)

        return result

    read_uint16: =>
        low = @read_byte!
        high = @read_byte!

        return high * 256 + low

    read_uint32: =>
        result = 0

        for i = 0, 3
            result = result + (@read_byte! * (256 ^ i))

        return result

class AuthLogonChallenge_Client --- Auth Logon Challenge Client
     new: (cmd, err, gamename, version, build, platform, os, country, timezone_bias, ip, account_name_length, account_name) =>
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
            success = @read_client_data()
            unless success
                LOG_INFO("> Client disconnected")
                break
            Socket.sleep(.1)
        return true

    handle_auth_logon_challenge: =>
        @packet.error = string.byte(@packet.header, 2)
        @packet.size  = string.byte(@packet.header, 3) + (string.byte(@packet.header, 4) * 256)
        
        remaining_data, err = @client->receive(@packet.size)
        unless remaining_data
            LOG_ERROR("> No additional data received: #{err}")
            return false

        auth_challenge_packet = Packet(@packet.header .. remaining_data)
        temp = {
            -- Header data
            cmd: auth_challenge_packet->read_byte!,
            error:auth_challenge_packet->read_byte!,
            size: auth_challenge_packet->read_uint16!,

            -- Client data
            game_name: auth_challenge_packet->read_string(4),
            version: {
                version1: auth_challenge_packet->read_byte!,
                version2: auth_challenge_packet->read_byte!,
                version3: auth_challenge_packet->read_byte!,
            },
            build: auth_challenge_packet->read_uint16!

            -- User data
            platform: auth_challenge_packet->read_string(4),
            os: auth_challenge_packet->read_string(4),
            country: auth_challenge_packet->read_string(4),
            timezone_bias: auth_challenge_packet->read_uint32(),
            ip: auth_challenge_packet->read_uint32(),

            -- Form data
            name_length: auth_challenge_packet->read_byte()
        }
        temp.account_name = auth_challenge_packet->read_string(temp.name_length)

        LOG_INFO("> Account #{temp.account_name} trying to connect..")
        return true

    read_client_data: =>
        LOG_INFO("> Trying to read data...")

        header, err = @client->receive(4)
        unless header
            if err == "closed"
                LOG_INFO("> Client closed connection")
            elseif err == "timeout"
                LOG_INFO("> Client connection timeout")
            else
                LOG_ERROR("> Connection error: #{err}")
            return false
        
        @packet.header = header
        @packet.cmd = string.byte(@packet.header, 1)

        switch @packet.cmd
            when AUTH_LOGON_CHALLENGE
                return @handle_auth_logon_challenge()

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
