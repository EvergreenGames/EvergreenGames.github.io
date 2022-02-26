local http = require("socket.http")
local ltn12 = require "ltn12"

function buildWorldUploadTable(app, proj)
    local t = {}
    t.name = app.uploadWorldVTable.name.value
    t.author = app.uploadWorldVTable.author.value
    t.startLevel = listroomtitles(proj)[app.uploadWorldVTable.startLevel.value]
    t.levels = {}
    for n,room in pairs(proj.rooms) do
        r = {}
        r.name = room.title=="" and tostring(n).."00m" or room.title
        r.width = tostring(room.w/16)
        r.height = tostring(room.h/16)
        r.data = dumproomdata(room)
        r.bottomExit = room.bottomExit==1 and "" or listroomtitles(proj)[room.bottomExit-1]
        r.leftExit = room.leftExit==1 and "" or listroomtitles(proj)[room.leftExit-1]
        r.rightExit = room.rightExit==1 and "" or listroomtitles(proj)[room.rightExit-1]
        r.topExit = room.topExit==1 and "" or listroomtitles(proj)[room.topExit-1]
        r.objectData = room.objectData
        local music_lookup = {"-1","0","10","20","30"}
        r.music = music_lookup[room.music]
        r.color = ""
        if room.col_switch then
            r.color = room.bg_col.."/"..room.cloud_col.."/"..room.fg_col_main.."/"..room.fg_col_alt
        end
        table.insert(t.levels, r)
    end
    return t
end

function uploadWorld()
    local data = JSON:encode(buildWorldUploadTable(app, project))
    --[[app.request = http.request({
        uploadURL,
        data
    },
    function (body, headers, code)
        if code == 200 then
            app.uploadState = "success"
        else
            app.uploadState = "fail"
        end
    end
    )]]
    app.uploadState = "uploading"
    local body,code,header = http.request{
        url = uploadURL,
        method = "POST",
        headers = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = string.len(data)
        },
        source = ltn12.source.string(data)
    }
    if code == 200 then
        app.uploadState = "success"
    else
        app.uploadState = "fail"
    end
end