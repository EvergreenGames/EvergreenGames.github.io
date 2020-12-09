'use strict';

const ws = require('ws');
const server = new ws.Server({port: 8080});

var pid_counter = 0;
var clients = [];
 
server.on('connection', (connection) => 
{
	console.log('Client connected');
	pid_counter++;
	var local_pid = pid_counter;

	var newC = {
		socket: connection,
		pid: local_pid,
		username: "",
		room: 0
	}

	clients.push(newC);

	connection.send('init,1,-2,' + pid_counter);
	connection.on('message', (data) =>
	{
		if(typeof(data)!='string'){
			data = data.toString();
		}
		if(data.split(",").length < 3)
			return

		try{
			handleMessage(data);
		}
		catch(e){}
  	}); 
  	connection.on('close', (data) =>
	{
		clients = clients.filter(c => c.pid!=local_pid);
		broadcast("disconnect,1,-2," + local_pid);
		console.log('Client disconnected');
  	});
});

function handleMessage(data){
	console.log(data);
	var msg = data.split(",");
	if(msg[0]=="room"){
		var sclient = getClientFromPID(msg[2]);
		var oldroom = sclient.room;
		sclient.room = msg[4];
		clients.forEach((client) => {
			if(client.pid==msg[2]){
				client.username = msg[3];
				clients.forEach((oc) => {
					if(oc.pid==client.pid || oc.room!=client.room) return;
					client.socket.send("sync,1,"+oc.pid+","+oc.username);
				});
			}
			else{
				if(client.room==msg[4]){
					client.socket.send("connect,1,"+msg[2]+","+msg[3]);
				}
				else if(client.room==oldroom){
					client.socket.send("disconnect,1,-2,"+msg[2]);
				}
			}
		});
		return;
	}
	if(msg[0]=="disconnect"){
		getClientFromPID(msg[3]).room=0
	}

	broadcast(data)
}

//refactor server(-2) messages
function broadcast(data)
{
	var msg_pid = data.split(",")[2];
	var sclient = getClientFromPID(msg_pid);
	clients.forEach((client) =>
	{
    	if(client.pid==msg_pid) return;
    	if(sclient!=-2 && sclient != null && client.room!=sclient.room) return;
    	client.socket.send(data);
  	});
}

function getClientFromPID(pid){
	if(pid==-2) return -2;
	var c=null;
	clients.forEach((client) => {
		if(client.pid==pid)
			c=client;
	})
	return c;
}

console.log('Listening for connections');