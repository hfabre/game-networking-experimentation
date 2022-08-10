# HugoCo

The idea behind this project is to implement a simple game (platformer) with network ability and an authoritative server.
It aims to be a sandbox to test how various network optimization techniques can
impact (positively) the gameplay under various network conditions.

The main guide I use to write this is [this awesome article series](https://www.gabrielgambetta.com/client-server-game-architecture.html)
from Gabriel Gambetta.

Keep in mind I want this project to stay as simple as possible so I won't look too much into securiy, implementing my own protocol over UDP or use time based contraints instead of frame based.

## Usage

Clone the repository

```sh
cd hugoco
bundle install
```

Start the server

```sh
ruby server.rb
```

Here is the server usage:

```sh
ruby server.rb -h
Usage: server [options]
    -l, --lag_comp                   Activate lag compensation
    -h, --help                       Prints this help
```
Start a client

```sh
ruby client.rb -p 9998
```

Here is the client usage:

```sh
ruby client.rb -h
Usage: client [options]
    -p, --port PORT                  Port to bind
    -f PACKET_LOSS_PERCENTAGE,       Simulated packet loss percentage (%)
        --packet_loss
    -l, --ping PING                  Simulated latency (ms)
    -s, --sync                       Should syncronize state
    -i, --lerp                       Should syncronize state with linear interpolation
    -n, --network                    Run in networked mode
    -h, --help                       Prints this help
```

## Server

It is a basic UDP server. It can run both headless or with a visualizer to see what happen.
The game implementation is shared with the client but the source of truth if the server.
It simulate every call from the client.
Every once in a while it sends a call to action to clients (results in coloring player in yellow)
If the player clicked fast enough on his mouse left button the this is a success
and player is colored in green, otherwise it's colored in red.
This is feature is here to demonstrate the usefulness of lag compensation

## Client

_Note that I'm not an expert and this is my first take on this subject so I may be wrong and/or misunderstand the techniques_

The client should be able to simulate latency and packet loss so we can see the impact of the various used techniques.
Since we use UDP and UDP is message oriented procol the client must implement a little server to receive server messages.

Note that since the client has the simulation code it will start as a standalone game by default. To start it as
a network game, use the `-n` option

It should have these options avaible to acts on network conditions

- [x] Simulate latency (`-l PING (ms)`)
- [x] Simulate packet loss (`-f PACKET_LOSS (%)`)

It should implement various techniques:

- [x] [Client side prediction](https://www.gabrielgambetta.com/client-side-prediction-server-reconciliation.html#client-side-prediction) (we get this for free since we share the implementation between client and server and we have a running simulation on both)
- [x] [Server reconciliation](https://www.gabrielgambetta.com/client-side-prediction-server-reconciliation.html#server-reconciliation) (we get this for free since when an input is comming it acts only on velocity and let the simulation (which shared) calculate the position accordingly)
- [x] [State synchronization](https://www.gabrielgambetta.com/entity-interpolation.html#server-time-step) (server send game state almost every 3 frames and the client can syncronize with it. Option `-s`)
- [x] [Entity interpolation](https://www.gabrielgambetta.com/entity-interpolation.html#entity-interpolation) (when syncronizing with the server we interpolate positions so there no "teleport effect". Option `-s -i`)
- [X] [Lag compensation](https://www.gabrielgambetta.com/lag-compensation.html#lag-compensation) (option `-l` on the server)
- [ ] [Dead reckoning](https://www.gabrielgambetta.com/entity-interpolation.html#dead-reckoning) (I have yet to find a simple example in this sandbox game to demonstrate the usefulness of this technique)

## Technical notes

Some trade between simplcity and real world utility has been made.
For exemple we syncronize all the game state once every three frame,
this leads to quite smooth interpolation even with a high packet loss percentage.
In a real game it's too much bandwidth and not even doable for very big games (Battle royal)

### Code

Since I have developed various platformer game skeleton I think the code architecture is not that bad regarding the engine.
But this is my first time implementing some network code inside this so it gets a bit messy
(specially in `server.rb` and `client.rb`)

### Game

Some things are hard coded into the engine like the map (here only the ground).
Ideally the server should send those data to new incoming client

### UDP

I used the UDP protocol for this project since it's commonly admited that it is the way to go for fast paced multiplayer games.
However I didn't implement everythin I should have since this is not the main subject of this project, but it could come later.

- There is no packet acknowledgment
- No way to send a packet and being sure it reaches the server

### Security

Even thought this project aims to talk about security (that's one key advantage of an authoritative server) it's not really.

- Messages are not encrypted
- We use the same ids client side and server side to identify player, so anyone knowing your id could make your player move
- And probably a lot other things I didn't think about

### How does it works

Protocol is pretty simple:

`packet_id;client_id;current_frame;data(;other_data)`

Server starts:

- Launch engine to simulate the game
- Launch a server listening on port `9999`
- Lauch a loop which will send state to be used to synchronize clients (`3;client_id;json_state` every three frame to all clients)
- Wait for messages

Client starts:

- Launch engine to simulate the game
- Launch a server listening on the given port (`-p 9998`)
- Send welcome packet to server to tell over which port it should comunicate (`0;;port`)
- Server spawn the new player in his simulation
- Server respond with a welcome packet (`0;new_client_id;x;y`)
- Server tell other clients a new player is coming (`2;new_client_id;frame;x;y`)
- Client store this id since it's his only way to tell the server who he is
- Client spawn his player in his simulation
- Server send already existing players (`2;new_client_id;frame;x;y` for each existing player
- Client spawn other players
- Every three frame receive sync message and changes his state accordingly (depending wether sync and interlopation are activated)

Client input:

- Player press `left` key
- Client simulate the move
- Client send the move to server (`1;client_id;frame;left`)
- Server simulate the move
- Server send to other clients the move (`1;client_id;frame;left`)
- Other clients simulate the move
