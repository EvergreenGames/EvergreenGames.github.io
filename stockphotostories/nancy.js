//Ruben Green
//UID: 505411174

card_id = 0;
class Card {
	constructor(x,y){
		this.image = new Image;
		this.image.src = "https://source.unsplash.com/random/200x300?action&sig=" + (card_id++);
		this.x = x;
		this.y = y;
		this.w = IMAGE_W;
		this.h = IMAGE_H;
	}
	draw(){
		ctx.drawImage(this.image, this.x, this.y, this.w, this.h);
		ctx.strokeStyle = "#FFFFFF"
		ctx.lineWidth = 10;
		if(this.mouseover()){
			ctx.strokeRect(this.x, this.y, this.w, this.h);
		}
	}
	mouseover(){
		return mousex >= this.x && mousex <= this.x+IMAGE_W && mousey >= this.y && mousey <= this.y+IMAGE_H;
	}
}

var canvas = document.getElementById("mainCanvas");
var ctx = canvas.getContext("2d");
updateCanvasSize();
var mousex, mousey;
canvas.addEventListener("mousemove", function(e) {
	const canvasPos = getPosition(canvas);
	mousex = e.clientX - canvasPos.x;
	mousey = e.clientY - canvasPos.y;
}, false);

canvas.addEventListener("click", function(e) {
	if(e.button != 0) return;

	if(board.length >= HAND_SIZE){
		restartGame();
		return;
	}

	var clicked = false;
	for (var i = 0; i < hand.length; i++) {
		if(hand[i].mouseover()){
			hand[i].y = 50;
			hand[i].x = canvas.width/2 - (BOARD_SIZE/2)*(IMAGE_W*2+20) + board.length * (IMAGE_W*2+20);
			hand[i].w *= 2;
			hand[i].h *= 2;
			board.push(hand.splice(i,1)[0]);
			clicked = true;
		}
	}
	if(clicked){
		hand = [];
		if(board.length < BOARD_SIZE){
			createHand();
		}
	}
}, false);

window.onresize = function(){
	updateCanvasSize();
}

setInterval(updateGame,20);

HAND_SIZE = 5
BOARD_SIZE = 5

IMAGE_W = 100
IMAGE_H = 150

hand = [];
createHand();
board = [];

function updateGame(){
	ctx.clearRect(0, 0, canvas.width, canvas.height);
	for (var i = 0; i < BOARD_SIZE; i++) {
		ctx.strokeStyle = "#111111";
		ctx.lineWidth = 10;
		ctx.strokeRect(canvas.width/2 - (BOARD_SIZE/2)*(IMAGE_W*2+20) + i * (IMAGE_W*2+20), 50, IMAGE_W*2, IMAGE_H*2);
	}
	for(const c of hand){
		c.draw();
	}
	for(const c of board){
		c.draw();
	}
	if(board.length == BOARD_SIZE){
		ctx.fillStyle = "#FFFFFF";
		ctx.fillText("Click to restart!", canvas.width/2-100, canvas.height-50);
		ctx.font = "25px sans-serif";
	}
}

function restartGame(){
	hand=[];
	createHand();
	board=[];
}

function createHand(){
	for (var i = 0; i < HAND_SIZE; i++) {
		hand.push(new Card(canvas.width/2-(HAND_SIZE/2 - i)*(IMAGE_W+20), canvas.height-IMAGE_H-5));
	}
}

function updateCanvasSize(){
	canvas.width = window.innerWidth*0.8
	canvas.height = window.innerHeight*0.7
}

function getPosition(el) {
  var xPos = 0;
  var yPos = 0;
 
  while (el) {
    if (el.tagName == "BODY") {
      // deal with browser quirks with body/window/document and page scroll
      var xScroll = el.scrollLeft || document.documentElement.scrollLeft;
      var yScroll = el.scrollTop || document.documentElement.scrollTop;
 
      xPos += (el.offsetLeft - xScroll + el.clientLeft);
      yPos += (el.offsetTop - yScroll + el.clientTop);
    } else {
      // for all other non-BODY elements
      xPos += (el.offsetLeft - el.scrollLeft + el.clientLeft);
      yPos += (el.offsetTop - el.scrollTop + el.clientTop);
    }

    el = el.offsetParent;
  }
  return {
    x: xPos,
    y: yPos
  };
}
