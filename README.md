# ForgeLua - WoW Wrath of the Lich King Emulator (POC)
Welcome to ForgeLua! 🎮✨

ForgeLua is a Proof of Concept (POC) emulator for World of Warcraft: Wrath of the Lich King version 3.3.5 (Build 12340a). The goal of this project is to implement a functional server emulator that mimics the authentication protocol for WoW 3.3.5, focusing on handling specific packets with Lua scripting.

This is not a complete emulator, but rather a starting point for creating your own WoW server emulator in Lua. It currently supports a limited set of packets and aims to demonstrate how to handle the authentication process and some related communication.

## Features 🚀
- Basic authentication challenge and login proof handling.
- Simulated responses for successful and failed login attempts.
- Custom Lua scripting to decode and handle WoW packet structures.
- POC focused on Wrath of the Lich King (3.3.5) only.

## Installation 💻
To get started with ForgeLua, follow these steps:
### Prerequisites:
- **LuaJIT** (for better performance)
- **LuaSocket** (for network communication)
- **Ansicolors** (for terminal color)
- **Moonscript** (for launching project)

1. **Clone the repository:**
   ```bash
   git clone https://github.com/iThorgrim/ForgeLua.git forgelua
   ```
2. **Install dependencies**:
   - Use [LuaRocks](https://luarocks.org/) to install required packages:
     ```bash
     luarocks install luasocket
     luarocks install ansicolors
     ```
  - Build Moonscript fork
    ```bash
    git clone https://github.com/SoulProjects/moonscript.git
    cd moonscript && luarocks make moonscript-dev-1.rockspec
    ```
3. **Run the server:**
   - To start the server, run the `authserver.moon` file:
     ```bash
     cd forgelua
     moon authserver.moon
     ```

## Usage 🛠️
Once the server is running, it will listen for incoming client connections. The server can handle basic WoW authentication packets such as `AUTH_LOGON_CHALLENGE` and `AUTH_LOGON_PROOF`. It will send simulated responses based on the packet received.

You can test the server by attempting to connect with a WoW client configured to connect to your server.

## Limitations ⚠️
- This project is **NOT** a fully-fledged WoW emulator, but a **Proof of Concept** (POC).
- Currently, only authentication-related packets are handled.
- No database or realm list functionalities are implemented yet.

## Contributing 🤝
Feel free to fork the repository and submit pull requests. Contributions are welcome to help expand the emulator’s functionality and support additional packets.

## License 📜
ForgeLua is released under the **GNU General Public License v3.0**. See the [LICENSE](https://github.com/iThorgrim/ForgeLua/blob/main/LICENSE) file for more details.

___
Enjoy experimenting with ForgeLua! ✨🛠️
