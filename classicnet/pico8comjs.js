var pico8_gpio = Array(128);

var server_address = "localhost:8080";

var connection;
var interval_in;
var interval_out;

var initMessage;

var form_div = document.createElement("div");
form_div.style.position="absolute";
form_div.style.width="100%";
form_div.style.textAlign="center";
var form_result = document.createElement("p");
form_result.style.display = "inline";
form_result.style.paddingLeft = "10px";
var form_address = document.createElement("INPUT");
form_address.defaultValue = server_address;
var form_button = document.createElement("BUTTON");
form_button.innerHTML = "Connect";
form_button.onclick = function(){

if(p8_is_running){
	form_result.innerHTML = "Can't change server while running.";
	return;
}

server_address = form_address.value;

// Connection

if(connection!=null){
	connection.close();
}

var sock_addr = 'wss://' + server_address;
if(server_address.includes('localhost')){
	sock_addr = 'ws://' + server_address;
}

connection = new WebSocket(sock_addr);
connection.onopen = function() 
{
	console.log('Connected to server');
	form_result.innerHTML = "Connected!";

	interval_out = setInterval(function()
	{
		var control = pico8_gpio[OUTPUT_INDEX];
		if (control)
		{
			for (var i = OUTPUT_INDEX + 1; i < 64; i ++)
			{
				if (!pico8_gpio[i])
				{
					processOutput();
					break;
				}

				outputMessage += String.fromCharCode(pico8_gpio[i]);
			}

			if (control == 2)
				processOutput();

			pico8_gpio[0] = 0;
		}
	}, OUTPUT_FREQUENCY);



	interval_in = setInterval(function()
	{
		var control = pico8_gpio[INPUT_INDEX];
		if (control == 1) return;

		if (inputMessage == null && inputQueue.length > 0)
			inputMessage = inputQueue.shift();

		if (inputMessage != null)
		{
			pico8_gpio[INPUT_INDEX] = 1;
			for (var i = 1; i < 64; i ++)
				pico8_gpio[INPUT_INDEX + i] = 0;

			var chunk = inputMessage.substr(0, 63);
			for (var i = 0; i < chunk.length; i ++)
				pico8_gpio[INPUT_INDEX + 1 + i] = chunk.charCodeAt(i);

			inputMessage = inputMessage.substr(63);
			if (inputMessage.length == 0)			
			{
				inputMessage = null;
				if (chunk.length == 63)
					pico8_gpio[INPUT_INDEX] = 2;
			}
		}
	}, INPUT_FREQUENCY);
};

connection.onerror = function(error)
{
	console.log('Connection error ' + error);
	form_result.innerHTML = "Connection Failed";
};

connection.onmessage = function(event) 
{
	var data = event.data;
	console.log('Server message ' + data + ' received');

	processInput(data);
};

connection.onclose = function()
{
	clearInterval(interval_in);
	clearInterval(interval_out);
};

};

// Output

var OUTPUT_INDEX = 0;
var OUTPUT_FREQUENCY = 1000 / 60;

var outputMessage = '';

function processOutput()
{
	if(outputMessage.split(",")[0]=="cartload"){
		inputQueue.push(initMessage);
		outputMessage="disconnect,1,-2," + initMessage.split(",")[3];
	}

	connection.send(outputMessage);

	outputMessage = '';
}

// Input

var INPUT_INDEX = 64;
var INPUT_FREQUENCY = 1000 / 60;
var MAX_INPUT_QUEUE = 4;

var inputQueue = [];
var inputMessage = null;

function processInput(message)
{
	var pmessage = message.split(",", 3)
	var mtype = pmessage[0];
	var reliable = pmessage[1]=="1";

	if(mtype=="init"){	
		initMessage=message;
	}

	if(!reliable){
		inputQueue = inputQueue.filter(i => i.split(",",2)[0]!=mtype);
	}
	if(pico8_gpio[0]!=null && mtype!="init" && inputQueue.length <= MAX_INPUT_QUEUE){
		inputQueue.push(message);
	}
}

form_div.appendChild(form_address);
form_div.appendChild(form_button);
form_div.appendChild(form_result);
document.body.appendChild(form_div);







