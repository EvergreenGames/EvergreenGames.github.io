'use strict';

const ws = require('ws');
const server = new ws.Server({port: 8080});

var pid_counter = 0;
 
server.on('connection', (connection) => 
{
	console.log('Client connected');
	pid_counter++;
	var local_pid = pid_counter;
	connection.send('init,1,-2,' + pid_counter);
	connection.on('message', (data) =>
	{
		console.log('Client message ' + data + ' received');
		broadcast(data);
  	}); 
  	connection.on('close', (data) =>
	{
		broadcast("disconnect,1,-2," + local_pid);
		console.log('Client disconnected');
  	}); 
});

function broadcast(data)
{
	server.clients.forEach((client) =>
	{
    	client.send(data);
  	});
}

console.log('Listening for connections');