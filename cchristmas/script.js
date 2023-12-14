document.body.onload = init;
var date = new Date();

var dates = [
    [13, 13, 0, 0],
    [14, 13, 0, 0],
    [15, 13, 0, 0],
    [16, 13, 0, 0],
    [17, 13, 0, 0],
    [18, 13, 0, 0],
    [19, 13, 0, 0],
    [20, 13, 0, 0],
    [21, 13, 0, 0],
    [22, 13, 0, 0],
    [23, 13, 0, 0],
    [24, 13, 0, 0]
]

var titles = [
    "Flare by Veitamura",
    "UNKNOWN by UNKNOWN",
    "UNKNOWN by UNKNOWN",
    "UNKNOWN by UNKNOWN",
    "UNKNOWN by UNKNOWN",
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
    date.setSeconds(date.getSeconds() + 1);
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
                (date.getDate() < dates[i][0]) ||
                (date.getDate() == dates[i][0] && date.getHours() < dates[i][1]) ||
                (date.getDate() == dates[i][0] && date.getHours() == dates[i][1] && date.getMinutes() < dates[i][2]) ||
                (date.getDate() == dates[i][0] && date.getHours() == dates[i][1] && date.getMinutes() > dates[i][2] && date.getSeconds() < dates[i][3])
                ) {
                end = true;
                var text = document.createElement("h5");
                var t = "Unlocks in: ";

                var unlockDate = new Date(date);
                unlockDate.setDate(dates[i][0]);
                unlockDate.setHours(dates[i][1]);
                unlockDate.setMinutes(dates[i][2]);
                unlockDate.setSeconds(dates[i][3]);

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