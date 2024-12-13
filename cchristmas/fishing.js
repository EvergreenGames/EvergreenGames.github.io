var c = document.getElementById("fishing");
var ctx = c.getContext("2d");

const imageNames = [
    "adelie"
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

async function init() {
    for (const imgName in imageNames) {
        images[imgName] = await loadImage(imgName + ".png");
    }

    setInterval(update, 20);
}

function update() {
    
}
