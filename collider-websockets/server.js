var app = require('http').createServer(handler),
    io = require('socket.io').listen(app),
    fs = require('fs');

app.listen(5555);

function handler (req, res) {
  var filename;

  if (req.url === '/') {
    filename = '/index.html';
  } else if (req.url === '/bootstrap.css') {
    filename = '/bootstrap.css';
  } else if (req.url === '/bo_play.png') {
    filename = '/bo_play.png';
  } else if (req.url === '/collider.js') {
    filename = '/collider.js';
  } else if (req.url === '/d3.js') {
    filename = '/d3.js';
  } else if (req.url === '/underscore.js') {
    filename = '/underscore.js';
  }

  fs.readFile(__dirname + filename,
    function (err, data) {
      if (err) {
        res.writeHead(500);
        return res.end('Error loading index.html');
      }

      res.writeHead(200);
      res.end(data);
    }
  );
}

players = []
console.log("init server");
io.sockets.on('connection', function (socket) {
  players.push(socket.id);
  io.sockets.emit('update-players', {ids: players});

  socket.on('game-player-moved', function (data) {
    io.sockets.emit('game-player-moved', data);
  });

  socket.on('close', function(a,b,c) {
    console.log('closed: ',a,b,c);
  });
});
