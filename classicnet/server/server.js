'use strict';

const DBURL = "mongodb+srv://ServerUser:classicnet7823@classicnet.ibhp6.mongodb.net/classicnet?retryWrites=true&w=majority"

const fs = require('fs');
const https = require('https');

var ssl;

const ws = require('ws');
var server;

if(fs.existsSync('../cert/signed_chain.crt')) {
	ssl = https.createServer({
		cert: fs.readFileSync('../cert/signed_chain.crt'),
		key: fs.readFileSync('../cert/domain.key')
	}).listen(443);
	server = new ws.Server({server: ssl});
}
else {
	server = new ws.Server({port: 8080});
}

const MongoClient = require('mongodb').MongoClient;
const db = new MongoClient(DBURL);
var db_worlds;
var db_levels;
var db_sequences;
db.connect(function(err, cli){
	db_levels = db.db("classicnet").collection("levels");
	db_worlds = db.db("classicnet").collection("worlds");
	db_sequences = db.db("classicnet").collection("sequences");
});

const express = require('express');
const http = express();
http.use(
	express.urlencoded({
		extended: true
	})
)
http.use(express.json());

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
	//console.log(data);
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
		getClientFromPID(msg[3]).room=0;
	}
	if(msg[0]=="get"){
		if(msg[3]=="list"){
			console.log("Getting level list");
			getWorldList(msg[2],msg[4]);
		}
		if(msg[3]=="level"){
			console.log("Getting leveldata");
			getLevelData(msg[2], parseInt(msg[4]));
		}
		return;
	}
	if(msg[0]=="upload"){
		uploadLevel(msg);
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

async function getWorldList(pid,name){
	var query = {};
	if(name!=null) {
		query = { $or: [
			{name: { $regex: name, $options: 'i'}}, {author: {$regex: name, $options: 'i'}}, {id: name}
	]}}
	var wld_list_msg = "get,1,-2,list,";
	var world_list = await db_worlds.find(query).toArray();
	world_list.forEach((wld) => {
		wld_list_msg += wld.name;
		wld_list_msg += "~";
		wld_list_msg += wld.author;
		wld_list_msg += "~";
		wld_list_msg += wld.id;
		wld_list_msg += "~";
		wld_list_msg += wld.startLevel;
		wld_list_msg += "|";
	});
	console.log(wld_list_msg);
	wld_list_msg = wld_list_msg.slice(0, -1);
	getClientFromPID(pid).socket.send(wld_list_msg);
}

async function getLevelData(pid, lvlid){
	var query = { id: lvlid };
	var docs = await db_levels.find(query).toArray();

	var lvl_msg = "get,1,-2,level,";
	for (var i = 0; i < docs.length; i++) {
		lvl_msg += docs[i].name;
		lvl_msg += "~";
		lvl_msg += lvlid;
		lvl_msg += "~";
		lvl_msg += docs[i].width;
		lvl_msg += "~";
		lvl_msg += docs[i].height;
		lvl_msg += "~";
		lvl_msg += docs[i].data;
		lvl_msg += "~";
		lvl_msg += docs[i].topExit;
		lvl_msg += "~";
		lvl_msg += docs[i].bottomExit;
		lvl_msg += "~";
		lvl_msg += docs[i].leftExit;
		lvl_msg += "~";
		lvl_msg += docs[i].rightExit;
		lvl_msg += "~";
		lvl_msg += docs[i].music;
		lvl_msg += "~";
		lvl_msg += docs[i].color;
		lvl_msg += "~";
		lvl_msg += docs[i].objectData;
		lvl_msg += "|";
	}

	lvl_msg = lvl_msg.slice(0, -1);
	getClientFromPID(pid).socket.send(lvl_msg);
}

function makeLvlId(worldId, levelName){
	if(levelName=="")
		return "";
	else
		return worldId + "-" + levelName;
}

function uploadLevel(data, worldId, worldAuthor){
	var obj = data.objectData.split('/');
	obj.forEach(element => element = "" + worldId + "-" + element);
	var doc = {
		name: data.name,
		width: data.width,
		height: data.height,
		id: worldId,
		createdAt: new Date(),
		data: data.data,
		bottomExit: makeLvlId(worldId, data.bottomExit),
		leftExit: makeLvlId(worldId, data.leftExit),
		rightExit: makeLvlId(worldId, data.rightExit),
		topExit: makeLvlId(worldId, data.topExit),
		objectData: data.objectData.split('/').map(e => "" + worldId + "-" + e).join('/'),
		music: data.music,
		color: data.color
	}
	db_levels.insertOne(doc, function(err, res){
		if(err) throw err;
		console.log("Level Uploaded: " + data.name);
	});
}

function uploadWorld(data){
	var inc = {
		$inc: {worldId: 1}
	}
	db_sequences.findOneAndUpdate({}, inc, function(err, res){
		if(err) throw err;
		var doc = {
			name: data.name,
			author: data.author,
			startLevel: res.value.worldId + "-" + data.startLevel,
			id: res.value.worldId,
			createdAt: new Date(),
		}
		db_worlds.insertOne(doc, function(err, res){
			if(err) throw err;
			console.log("World Uploading: " + data.name);
		});

		for (var i = 0; i < data.levels.length; i++) {
			uploadLevel(data.levels[i], res.value.worldId, data.author);
		}
	});
}

http.post('/upload', (req, res) => {
	console.log('Incoming upload request');
	try{
		uploadWorld(req.body);
		res.sendStatus(200);
	} catch{
			res.sendStatus(500);
	}
})
http.listen(80);
console.log('Listening for game connections');
console.log('Listening for level upload');