document.body.onload = init;

var titles = [
    "Flare by Veitamura",
    "MadeMaker by AntiBrain\nSquiggle by ChillSpider",
    "Adelie Golf by Calverin",
    "Rift by ooooggll",
    "St. Leste by coolelectronics\nSwitch by dehoisted",
    "Celestial Valley by Taco360",
    "Actuate by Sparky9d\nBlanc by Sheebeehs",
    "Hollow Celeste by Lord SNEK and Sparky9D",
    "Solanum by Cominixo",
    "ultimate selfie by cannonwuff and smellyfishtiks",
    "true north by meep",
    "newleste.p8 - old site"
]

function init() {
    var container = document.getElementById("grid-container");
    while (container.firstChild) {
        container.removeChild(container.lastChild);
    }

    for (let i = 0; i < 12; i++) {
        var card = document.createElement("div")
        card.className = "card";
        
        var pic = document.createElement("img");
        pic.src = "day" + (i+1) + "/cover.png";
        pic.style = "width: 100%";

        var title = document.createElement("h5");
        title.textContent = titles[i];

        card.appendChild(pic);
        card.appendChild(title);
        card.onclick = () => {
            window.location.href = "day" + (i+1) + "/index.html";
        }

        container.appendChild(card);
    }
}