local _gSubscription = {};

-- subscribe for the price data
function ExtSubscribe(id, instrument, period, bid, type)
    local sub = {};
    if instrument == nil and period == "t1" then
        if bid then
            sub.stream = instance.bid;
        else
            sub.stream = instance.ask;
        end
        sub.tick = true;
        sub.loaded = true;
        sub.lastSerial = -1;
        _gSubscription[id] = sub;
    elseif instrument == nil then
        sub.stream = core.host:execute("getHistory", id, instance.bid:instrument(), period, 0, 0, bid);
        sub.tick = false;
        sub.loaded = false;
        sub.lastSerial = -1;
        _gSubscription[id] = sub;
    else
        sub.stream = core.host:execute("getHistory", id, instrument, period, 0, 0, bid);
        sub.tick = (period == "t1");
        sub.loaded = false;
        sub.lastSerial = -1;
        _gSubscription[id] = sub;
    end
    if sub.tick then
        return sub.stream;
    else
        if type == "open" then
            return sub.stream.open;
        elseif type == "high" then
            return sub.stream.high;
        elseif type == "low" then
            return sub.stream.low;
        elseif type == "close" then
            return sub.stream.close;
        elseif type == "bar" then
            return sub.stream;
        else
            assert(false, type .. " is unknown");
        end
    end
end

function AsyncOperationFinished(cookie, success, message)
    local sub;
    sub = _gSubscription[cookie];
    if sub ~= nil then
        sub.loaded = true;
        if sub.stream:size() > 1 then
           sub.lastSerial = sub.stream:serial(sub.stream:size() - 1);
        end
    else
        -- unknown cookie
        if ExtAsyncOperationFinished ~= nil then
            ExtAsyncOperationFinished(cookie, success, message)
        end
    end
end

function Update()
    for k, v in pairs(_gSubscription) do
        if v.loaded and v.stream:size() > 1 then
            local s = v.stream:serial(v.stream:size() - 1);
            local p;
            if s ~= v.lastSerial then
                if v.tick then
                    p = v.stream:size() - 1;    -- the last tick
                else
                    p = v.stream:size() - 2;    -- the previous candle
                end
                ExtUpdate(k, v.stream, p);
                v.lastSerial = s;
            end
        end
    end
end

dofile(core.app_path() .. "\\strategies\\standard\\include\\helperAlert.lua");

