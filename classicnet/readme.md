# Celeste CLASSIC Online Multiplayer Mod

## How to play
- Go to EvergreenGames.github.io/classicnet
- Enter server address and click "Connect"
- Press play on the PICO 8 player

## Server Hosting Guide
- Download and install [Node.js](https://nodejs.org)
- Download the server folder from this repo (/classicnet/server)
- Navigate to the downloaded folder in your terminal
- Run `npm install` in this folder to install dependencies
- Run `node server.js` to start the local server
### Connecting local server to the internet
In order for your local server to be accessible online, you need to connect the node server to a public address. I like to use [ngrok](https://ngrok.com).
#### Ngrok Guide
- Run `npm install ngrok -g` to install ngrok
- Run `ngrok http 8080` to start the connection
- Look for your server url under **Forwarding**. It should look like `[numbersandletters].ngrok.io`
- Give this url to players to connect!
