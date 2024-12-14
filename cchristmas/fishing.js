var c = document.getElementById("fishing");
var ctx = c.getContext("2d");

var mouseClick = false;
var mouseX = 0;
var mouseY = 0;
var keys = {};
c.addEventListener('mousedown', function(event) {
    mouseClick = true;
});
c.addEventListener('mouseup', function(event) {
    mouseClick = false;
});
c.addEventListener('touchstart', function(event) {
    mouseClick = true;

    const rect = c.getBoundingClientRect();
    mouseX = (event.touches[0].clientX  - rect.left) / 4;
    mouseY = (event.touches[0].clientY - rect.top) / 4;
});
c.addEventListener('touchend', function(event) {
    mouseClick = false;
});
c.addEventListener('mousemove', function(event) {
    const rect = c.getBoundingClientRect();
    mouseX = (event.clientX - rect.left) / 4;
    mouseY = (event.clientY - rect.top) / 4;
})
c.addEventListener('touchmove', function(event) {
    const rect = c.getBoundingClientRect();
    mouseX = (event.touches[0].clientX  - rect.left) / 4;
    mouseY = (event.touches[0].clientY - rect.top) / 4;
});
document.addEventListener('keydown', function(event) {
    keys[event.key] = true;
});
document.addEventListener('keyup', function(event) {
    keys[event.key] = false;
});

document.getElementById("buy_boat").addEventListener('click', function(event) {
    document.getElementById('buy_boat').hidden = true;

    numFish -=200;
    localStorage.setItem("numFish", numFish);
    localStorage.setItem("buy_boat", "1");
    document.getElementById("fish_count").innerHTML = numFish;

    o = spawnObject(Boat, 140, 0);
    o.key = 'x';
});

const imageNames = [
    "fisher",
    "hook",
    "fish",
    "goldfish"
]

var images = {}

async function loadImage(src) {
    return new Promise((resolve, reject) => {
        const img = new Image();
        img.onload = () => resolve(img);
        img.onerror = reject;
        img.src = src;
    });
}

var accum = 0;
var lastTime = 0;

const UPDATE_INTERVAL = (1/60) * 1000;

const SCREENW = 800;
const SCREENH = 300;

async function init() {
    for (const imgName of imageNames) {
        images[imgName] = await loadImage("assets/" + imgName + ".png");
    }

    if (localStorage.getItem("numFish"))
        numFish = parseInt(localStorage.getItem("numFish"));

    document.getElementById("fish_count").innerHTML = numFish;

    c.width = SCREENW;
    c.height = SCREENH;

    ctx.scale(4, 4);
    ctx.imageSmoothingEnabled = false;

    startGame();
    lastTime = Date.now();
    window.requestAnimationFrame(gameLoop);
}

let objects = [];
let numFish = 0;

function startGame() {
    let o = spawnObject(Boat, 20, 0);
    o.key = 'z';

    if(localStorage.getItem("buy_boat")) {
        o = spawnObject(Boat, 140, 0);
        o.key = 'x';
    }
}

function gameLoop() {
    const time = Date.now();
    const deltaTime = time - lastTime;

    accum += deltaTime;
    if (accum > UPDATE_INTERVAL) {
        accum -= UPDATE_INTERVAL;
        
        for(var i = 0; i < objects.length; i++) {
            objects[i].update();
        }
    }


    ctx.clearRect(0, 0, c.width, c.height);
    
    // water
    ctx.fillStyle = "#1d2b53";
    ctx.fillRect(0, 11, SCREENW, SCREENH);
    for (let x = 0; x < SCREENW; x++) {
        const y = 11 + 1 * Math.sin(0.3 * x + time/500);
        ctx.fillStyle = "#fff1e8";
        ctx.fillRect(x, Math.floor(y), 1, 1);
        ctx.fillStyle = "#29adff";
        ctx.fillRect(x, Math.floor(y)+1, 1, 2);
    }


    for(var i = 0; i < objects.length; i++) {
        objects[i].draw();
    }

    //fade
    ctx.globalCompositeOperation = "destination-in";
    let gradient = ctx.createLinearGradient(0, 0, SCREENW/4, 0);
    gradient.addColorStop(0, "transparent");
    gradient.addColorStop(0.02, "white");
    gradient.addColorStop(0.98, "white");
    gradient.addColorStop(1, "transparent");
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, SCREENW, SCREENH);
    ctx.globalCompositeOperation = "source-over";

    window.requestAnimationFrame(gameLoop);
}

init();

function spawnObject(type, x, y) {
    var o = new type;
    o.x = x;
    o.y = y;
    o.init();
    objects.push(o);
    return o;
}

function deleteObject(obj) {
    objects = objects.filter(function (item) {return item !== obj});
}

function drawImage(img, x, y) {
    ctx.drawImage(img, Math.floor(x), Math.floor(y));
}

class Boat {
    init() {
        this.hook = 0
        this.state = "up"
        this.caughtFish = null;
        this.lastSuccess = true;
        this.key = "";
    }

    update() {
        if (this.state == "up") {
            if ((mouseClick && Math.abs(mouseX - this.x-20) < 30) || keys[this.key])
                this.state = "move_down";
        }
        else if (this.state == "move_down") {
            this.hook += (this.lastSuccess ? 1 : 0.1);
            if (this.hook >= 45) {
                let hasfish = false;
                for (var ob of objects)
                    if (ob instanceof Fish && ob.dir == (this.key == "z" ? -1 : 1))
                        hasfish = true;

                if (!hasfish) {
                    if (this.key == 'z') {
                        var o = spawnObject(Fish, SCREENW/4, 48);
                        o.dir = -1;
                    }
                    else {
                        var o = spawnObject(Fish, 0, 48);
                        o.dir = 1;
                    }
                }

                this.state = "ready";
            }
        }
        else if (this.state == "ready") {
            if ((mouseClick && Math.abs(mouseX - this.x-20) < 30) || keys[this.key]) {
                for (var o of objects) {
                    if (o instanceof Fish) {
                        if (Math.abs(o.x - (this.x + 18)) <= 7) {
                            o.caught = true;
                            this.caughtFish = o;
                        }
                    }
                }
                this.state = "move_up";
            }
        }
        else if (this.state == "move_up") {
            this.hook -= 1;
            if (this.caughtFish) {
                this.caughtFish.x = this.x + 16;
                this.caughtFish.y = this.y + 3 + this.hook;
            }
            if (this.hook <= 0) {
                this.lastSuccess = false;
                if (this.caughtFish) {
                    awardFish(this.caughtFish);
                    deleteObject(this.caughtFish);
                    this.lastSuccess = true;
                    this.caughtFish = null;
                }

                this.state = "move_down";
            }
        }
    }

    draw() {
        drawImage(images["fisher"], this.x, this.y);
        drawImage(images["hook"], this.x + 16, this.y + 1 + this.hook);
        ctx.strokeStyle = "#fff1e8";
        ctx.beginPath();
        ctx.moveTo(this.x + 19.5, this.y + 1);
        ctx.lineTo(this.x + 19.5, this.y + 1 + this.hook);
        ctx.stroke();
    }
}

function awardFish(caughtFish) {
    numFish += (caughtFish.spd > 2 ? 5 : 1);
    localStorage.setItem("numFish", numFish);
    document.getElementById("fish_count").innerHTML = numFish;
    
    if (numFish >= 200) {
        var boatCount = 0;
        for(var o of objects)
            if (o instanceof Boat)
                boatCount++;
        if (boatCount <= 1) {
            document.getElementById('buy_boat').hidden = false;
        }
    }
}

class Fish {
    init() {
        this.randomSpd()
        this.caught = false;
    }
    update() {
        if (!this.caught) {
            this.x += this.spd * this.dir;
            if (this.dir == -1 && this.x < -10) {
                this.x = SCREENW/4 + 200 + Math.random() * 400;
                this.randomSpd();
            }
            else if (this.dir == 1 && this.x > SCREENW + 10) {
                this.x = -200 - Math.random() * 400;
                this.randomSpd();
            }
        }
    }
    draw() {
        if (this.spd > 2)
            drawImage(images["goldfish"], this.x, this.y, this.dir == 1);
        else
            drawImage(images["fish"], this.x, this.y);
    }
    randomSpd() {
        this.spd = Math.pow(Math.random(), 3) * 1.5 + 1;
    }
}