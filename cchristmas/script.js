document.body.onload = init;
var date = new Date();

var dates = [
    [13, 21, 0, 0],
    [14, 21, 0, 0],
    [15, 21, 0, 0],
    [16, 21, 0, 0],
    [17, 21, 0, 0],
    [18, 21, 0, 0],
    [19, 21, 0, 0],
    [20, 21, 0, 0],
    [21, 21, 0, 0],
    [22, 21, 0, 0],
    [23, 21, 0, 0],
    [24, 21, 0, 0]
]

var titles = [
    "Flare by Veitamura",
    "MadeMaker by AntiBrain\nSquiggle by ChillSpider",
    "Adelie Golf by Calverin",
    "Rift by ooooggll",
    "St. Leste by coolelectronics\nSwitch by dehoisted",
    "UNKNOWN by UNKNOWN",
    "UNKNOWN by UNKNOWN",
    "UNKNOWN by UNKNOWN",
    "UNKNOWN by UNKNOWN",
    "UNKNOWN by UNKNOWN",
    "UNKNOWN by UNKNOWN",
    "UNKNOWN by UNKNOWN"
]

async function init() {
    const res = await fetch("https://worldtimeapi.org/api/timezone/America/Los_Angeles");
    const json = await res.json();

    date = new Date(json.unixtime * 1000);
    
    setInterval(update, 1000);
}

function update() {
    date.setUTCSeconds(date.getUTCSeconds() + 1);
    var container = document.getElementById("grid-container");
    while (container.firstChild) {
        container.removeChild(container.lastChild);
    }

    var end = false;

    for (let i = 0; i < 12; i++) {
        var card = document.createElement("div")
        card.className = "card";

        if(!end) {
            if (
                (date.getUTCDate() < dates[i][0]) ||
                (date.getUTCDate() == dates[i][0] && date.getUTCHours() < dates[i][1]) ||
                (date.getUTCDate() == dates[i][0] && date.getUTCHours() == dates[i][1] && date.getUTCMinutes() < dates[i][2]) ||
                (date.getUTCDate() == dates[i][0] && date.getUTCHours() == dates[i][1] && date.getUTCMinutes() > dates[i][2] && date.getUTCSeconds() < dates[i][3])
                ) {
                end = true;
                var text = document.createElement("h5");
                var t = "Unlocks in: ";

                var unlockDate = new Date(date);
                unlockDate.setUTCDate(dates[i][0]);
                unlockDate.setUTCHours(dates[i][1]);
                unlockDate.setUTCMinutes(dates[i][2]);
                unlockDate.setUTCSeconds(dates[i][3]);

                var diff =  unlockDate - date;
                t += new Date(diff).toISOString().slice(11, 19);
                
                text.textContent = t;
                card.appendChild(text);
            }
            else {
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
            }
        }
        else {
            var text = document.createElement("h5");
            text.textContent = "December " + dates[i][0];
            card.appendChild(text);
        }
        
        container.appendChild(card);
    }
}