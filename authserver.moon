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
AUTH_LOGON_CHALLENGE                        = 0x00
AUTH_LOGON_PROOF                            = 0x01
AUTH_RECONNECT_CHALLENGE                    = 0x02
AUTH_RECONNECT_PROOF                        = 0x03
REALM_LIST                                  = 0x10
XFER_INITIATE                               = 0x30
XFER_DATA                                   = 0x31
XFER_ACCEPT                                 = 0x32
XFER_RESUME                                 = 0x33
XFER_CANCEL                                 = 0x34

-- Authentification Results (Todo:: Use Enum Library)
WOW_SUCCESS                                  = 0x00
WOW_FAIL_BANNED                              = 0x03
WOW_FAIL_UNKNOWN_ACCOUNT                     = 0x04
WOW_FAIL_INCORRECT_PASSWORD                  = 0x05
WOW_FAIL_ALREADY_ONLINE                      = 0x06
WOW_FAIL_NO_TIME                             = 0x07
WOW_FAIL_DB_BUSY                             = 0x08
WOW_FAIL_VERSION_INVALID                     = 0x09
WOW_FAIL_VERSION_UPDATE                      = 0x0A
WOW_FAIL_INVALID_SERVER                      = 0x0B
WOW_FAIL_SUSPENDED                           = 0x0C
WOW_FAIL_FAIL_NOACCESS                       = 0x0D
WOW_SUCCESS_SURVEY                           = 0x0E
WOW_FAIL_PARENTCONTROL                       = 0x0F
WOW_FAIL_LOCKED_ENFORCED                     = 0x10
WOW_FAIL_TRIAL_ENDED                         = 0x11
WOW_FAIL_USE_BATTLENET                       = 0x12
WOW_FAIL_ANTI_INDULGENCE                     = 0x13
WOW_FAIL_EXPIRED                             = 0x14
WOW_FAIL_NO_GAME_ACCOUNT                     = 0x15
WOW_FAIL_CHARGEBACK                          = 0x16
WOW_FAIL_INTERNET_GAME_ROOM_WITHOUT_BNET     = 0x17
WOW_FAIL_GAME_ACCOUNT_LOCKED                 = 0x18
WOW_FAIL_UNLOCKABLE_LOCK                     = 0x19
WOW_FAIL_CONVERSION_REQUIRED                 = 0x20
WOW_FAIL_DISCONNECTED                        = 0xFF

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
        
        -- Fixed values for authentication
        -- 
        @b = string.rep("\x3e\x32\xa1\x23", 8)      -- TEMP::32 bytes random server key
        @g = "\x07"                                 -- TEMP::generator = 7
        @N = string.rep("\xFF\xFF\xFF\xFF", 8)      -- TEMP::32 bytes modulus
        @salt = string.rep("\x22\x11\x33\x44", 8)   -- TEMP::32 bytes salt
        @version_challenge = string.rep("\xBA", 16) -- TEMP::16 bytes challenge

        @M2 = string.rep("\xBA", 20)                -- TEMP:: 20 bytes M2

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

    send_packet: (data) =>
        success, err = @client->send(data)
        unless success
            LOG_ERROR("> Failed to send packet: #{err}")
            return false
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
        
        response_data = {
            string.char(AUTH_LOGON_CHALLENGE),   -- cmd (1 byte)
            string.char(0x00),                   -- error (1 byte)
            string.char(WOW_SUCCESS),            -- result (1 byte)
            @b,                                  -- b value (32 bytes)
            string.char(0x01),                   -- g length (1 byte)
            @g,                                  -- g value (1 byte)
            string.char(0x20),                   -- N length (1 byte) = 32 en decimal
            @N,                                  -- N value (32 bytes)
            @salt,                               -- salt (32 bytes)
            @version_challenge,                  -- version challenge (16 bytes)
            string.char(0x00)                    -- security flags (1 byte)
        }

        response_str = table.concat(response_data)
        success = @send_packet(response_str)
        
        return success

    handle_auth_logon_proof: =>
        remaining_data, err = @client->receive(1 + 20 + 20 + 20 + 1)  -- cmd(1) + A(20) + M1(20) + crc_hash(20) + number_of_keys(1)
        unless remaining_data
            LOG_ERROR("> No proof data received: #{err}")
            return false

        proof_packet = Packet(remaining_data)
        
        LOG_INFO("> Received auth proof packet")

        -- Building the proof response
        response_data = {
            string.char(AUTH_LOGON_PROOF),      -- cmd (1 byte)
            string.char(0x00),                  -- error (1 byte)
            @M2,                                -- M2 (20 bytes)
            string.char(0x08),                  -- account flags (1 byte)
            string.char(0x00),                  -- survey id
            string.char(0x00)                   -- login flags
        }

        response_str = table.concat(response_data)
        
        LOG_INFO("> Sending proof response packet of size: #{#response_str} bytes")
        
        if #response_str != 25
            LOG_ERROR("> Invalid response packet size: #{#response_str} (expected 23)")
            return false

        success = @send_packet(response_str)
        unless success
            LOG_ERROR("> Failed to send proof response")
            return false

        LOG_INFO("> Auth proof response sent successfully")
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
            when AUTH_LOGON_PROOF
                return @handle_auth_logon_proof()
            else
                LOG_ERROR("> Unhandled command: #{@packet.cmd}")

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
