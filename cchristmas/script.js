document.body.onload = init;
var date = new Date();

const CURRENT_YEAR = "2025";
const yearSelect = document.getElementById("yearSelect");
yearSelect.onchange = update;
function getYear() {
    return yearSelect.options[yearSelect.selectedIndex].value;
}


// Yes, you can access the mods early :)
var dates = [
    [13, 9, 0, 0],
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

var titles = {
    "2023" : [
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
    ],
    "2024" : [
        "Duality by Superboi",
        "Bump Jump Mania by cominixo",
        "Shooting Star by ooooggll and btdubbz",
        "sans titre by kikoo",
        "Burnin' Trail by Lord Snek and Howf Wuff",
        "Celestial Valley v2.2 by petthepetra",
        "Sterrenmeid by faith",
        "Filament by antibrain",
        "Winter Glass by AnshumanNeon",
        "Blanc v2 by Sheebeehs",
        "Labyrinth by ahumanhuman",
        "Fairway by Meep",
    ],
    "2025" : [
        "Maddy on the Moon by Wisper",
        "???",
        "???",
        "???",
        "???",
        "???",
        "???",
        "???",
        "???",
        "???",
        "???",
        "???",
    ]
}

async function init() {
    update();

    const res = await fetch("https://worldtimeapi.org/api/timezone/America/Los_Angeles");
    const json = await res.json();

    date = new Date(json.unixtime * 1000);
    
    setInterval(update, 1000);
}

function update() {
    if (getYear() == CURRENT_YEAR) {
        updateCurrent();
    } else {
        updatePast();
    }
}

function updatePast() {
    date.setUTCSeconds(date.getUTCSeconds() + 1);
    var container = document.getElementById("grid-container");
    while (container.firstChild) {
        container.removeChild(container.lastChild);
    }

    var end = false;

    for (let i = 0; i < 12; i++) {
        var card = document.createElement("div")
        card.className = "card";

        
        var pic = document.createElement("img");
        pic.src = getYear() + "/day" + (i+1) + "/cover.png";
        pic.style = "width: 100%";

        var title = document.createElement("h5");
        title.textContent = titles[getYear()][i];

        card.appendChild(pic);
        card.appendChild(title);
        card.onclick = () => {
            window.location.href = getYear() + "/day" + (i+1) + "/index.html";
        }
        
        container.appendChild(card);
    }
}

function updateCurrent() {
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
                var t = "Coming soon! \nUnlocks in: ";

                var unlockDate = new Date(date);
                unlockDate.setUTCDate(dates[i][0]);
                unlockDate.setUTCHours(dates[i][1]);
                unlockDate.setUTCMinutes(dates[i][2]);
                unlockDate.setUTCSeconds(dates[i][3]);

                var diff =  new Date(unlockDate - date);
                var days = parseInt(diff.toISOString().slice(8, 10)) - 1;
                if (days > 1)
                    t += days + " days + ";
                else if (days == 1)
                    t += days + " day + ";

                t += diff.toISOString().slice(11, 19);
                
                text.textContent = t;
                card.appendChild(text);
            }
            else {
                var pic = document.createElement("img");
                pic.src = getYear() + "/day" + (i+1) + "/cover.png";
                pic.style = "width: 100%";

                var title = document.createElement("h5");
                title.textContent = titles[getYear()][i];

                card.appendChild(pic);
                card.appendChild(title);
                card.onclick = () => {
                    window.location.href = getYear() + "/day" + (i+1) + "/index.html";
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