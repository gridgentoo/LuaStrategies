function Init() --The strategy profile initialization
    strategy:name("Ichimoku Stategy");
    strategy:description("Ichimoku Strategy utilising ATR");
    
    strategy.parameters:addGroup("Price");
    strategy.parameters:addString("Type", "Price Type", "", "Bid");
    strategy.parameters:addStringAlternative("Type", "Bid", "", "Bid");
    strategy.parameters:addStringAlternative("Type", "Ask", "", "Ask");
    
    strategy.parameters:addString("TF", "Time frame", "", "m5");
    strategy.parameters:setFlag("TF", core.FLAG_PERIODS);
    
    strategy.parameters:addGroup("Calculation");
    strategy.parameters:addInteger("T", "Tenkan Period", "Tenkan Period", 9);
    strategy.parameters:addInteger("K", "Kijun Period", "Kijun Period", 26);
    strategy.parameters:addInteger("S", "Senkou Period", "Senkou Period", 52);
    strategy.parameters:addInteger("atrN", "ATR Period", "ATR Period", 14);

    strategy.parameters:addGroup("Selector");
    
    strategy.parameters:addString("Action".. 1, "SL/TL Cross Over", "", "NO");
    strategy.parameters:addStringAlternative("Action".. 1, "No Action", "", "NO");
    strategy.parameters:addStringAlternative("Action".. 1, "Sell", "", "SELL");
    strategy.parameters:addStringAlternative("Action".. 1, "Buy", "", "BUY");
    strategy.parameters:addStringAlternative("Action".. 1, "Close Position", "", "CLOSE");
    strategy.parameters:addStringAlternative("Action".. 1, "Alert", "", "Alert");
    
    strategy.parameters:addString("Action".. 2, "SL/TL Cross Under", "", "NO");
    strategy.parameters:addStringAlternative("Action".. 2, "No Action", "", "NO");
    strategy.parameters:addStringAlternative("Action".. 2, "Sell", "", "SELL");
    strategy.parameters:addStringAlternative("Action".. 2, "Buy", "", "BUY");
    strategy.parameters:addStringAlternative("Action".. 2, "Close Position", "", "CLOSE");
    strategy.parameters:addStringAlternative("Action".. 2, "Alert", "", "Alert");
    
    strategy.parameters:addString("Action".. 3, "CS / Price Cross Over", "", "NO");
    strategy.parameters:addStringAlternative("Action".. 3, "No Action", "", "NO");
    strategy.parameters:addStringAlternative("Action".. 3, "Sell", "", "SELL");
    strategy.parameters:addStringAlternative("Action".. 3, "Buy", "", "BUY");
    strategy.parameters:addStringAlternative("Action".. 3, "Close Position", "", "CLOSE");
    strategy.parameters:addStringAlternative("Action".. 3, "Alert", "", "Alert");
    
    strategy.parameters:addString("Action".. 4, "CS / Price Cross Under", "", "NO");
    strategy.parameters:addStringAlternative("Action".. 4, "No Action", "", "NO");
    strategy.parameters:addStringAlternative("Action".. 4, "Sell", "", "SELL");
    strategy.parameters:addStringAlternative("Action".. 4, "Buy", "", "BUY");
    strategy.parameters:addStringAlternative("Action".. 4, "Close Position", "", "CLOSE");
    strategy.parameters:addStringAlternative("Action".. 4, "Alert", "", "Alert");
    
    
    strategy.parameters:addString("Action".. 5, "Top Cloud / Price  Cross Over", "", "NO");
    strategy.parameters:addStringAlternative("Action".. 5, "No Action", "", "NO");
    strategy.parameters:addStringAlternative("Action".. 5, "Sell", "", "SELL");
    strategy.parameters:addStringAlternative("Action".. 5, "Buy", "", "BUY");
    strategy.parameters:addStringAlternative("Action".. 5, "Close Position", "", "CLOSE");
    strategy.parameters:addStringAlternative("Action".. 5, "Alert", "", "Alert");
    
    strategy.parameters:addString("Action".. 6, "Top Cloud / Price Cross Under", "", "NO");
    strategy.parameters:addStringAlternative("Action".. 6, "No Action", "", "NO");
    strategy.parameters:addStringAlternative("Action".. 6, "Sell", "", "SELL");
    strategy.parameters:addStringAlternative("Action".. 6, "Buy", "", "BUY");
    strategy.parameters:addStringAlternative("Action".. 6, "Close Position", "", "CLOSE");
    strategy.parameters:addStringAlternative("Action".. 6, "Alert", "", "Alert");
    
    strategy.parameters:addString("Action".. 7, "Bottom Cloud / Price  Cross Over", "", "NO");
    strategy.parameters:addStringAlternative("Action".. 7, "No Action", "", "NO");
    strategy.parameters:addStringAlternative("Action".. 7, "Sell", "", "SELL");
    strategy.parameters:addStringAlternative("Action".. 7, "Buy", "", "BUY");
    strategy.parameters:addStringAlternative("Action".. 7, "Close Position", "", "CLOSE");
    strategy.parameters:addStringAlternative("Action".. 7, "Alert", "", "Alert");
    
    strategy.parameters:addString("Action".. 8, "Bottom Cloud / Price Cross  Under", "", "NO");
    strategy.parameters:addStringAlternative("Action".. 8, "No Action", "", "NO");
    strategy.parameters:addStringAlternative("Action".. 8, "Sell", "", "SELL");
    strategy.parameters:addStringAlternative("Action".. 8, "Buy", "", "BUY");
    strategy.parameters:addStringAlternative("Action".. 8, "Close Position", "", "CLOSE");
    strategy.parameters:addStringAlternative("Action".. 8, "Alert", "", "Alert");
    
    strategy.parameters:addString("Action".. 9, "Chinkou / Top Cloud  Cross Over", "", "NO");
    strategy.parameters:addStringAlternative("Action".. 9, "No Action", "", "NO");
    strategy.parameters:addStringAlternative("Action".. 9, "Sell", "", "SELL");
    strategy.parameters:addStringAlternative("Action".. 9, "Buy", "", "BUY");
    strategy.parameters:addStringAlternative("Action".. 9, "Close Position", "", "CLOSE");
    strategy.parameters:addStringAlternative("Action".. 9, "Alert", "", "Alert");
    
    strategy.parameters:addString("Action".. 10, "Chinkou / Top Cloud  Cross Under", "", "NO");
    strategy.parameters:addStringAlternative("Action".. 10, "No Action", "", "NO");
    strategy.parameters:addStringAlternative("Action".. 10, "Sell", "", "SELL");
    strategy.parameters:addStringAlternative("Action".. 10, "Buy", "", "BUY");
    strategy.parameters:addStringAlternative("Action".. 10, "Close Position", "", "CLOSE");
    strategy.parameters:addStringAlternative("Action".. 10, "Alert", "", "Alert");
    
    strategy.parameters:addString("Action".. 11, "Chinkou /  Bottom Cloud  Cross Over", "", "NO");
    strategy.parameters:addStringAlternative("Action".. 11, "No Action", "", "NO");
    strategy.parameters:addStringAlternative("Action".. 11, "Sell", "", "SELL");
    strategy.parameters:addStringAlternative("Action".. 11, "Buy", "", "BUY");
    strategy.parameters:addStringAlternative("Action".. 11, "Close Position", "", "CLOSE");
    strategy.parameters:addStringAlternative("Action".. 11, "Alert", "", "Alert");
    
    strategy.parameters:addString("Action".. 12, "Chinkou /  Bottom Cloud  Cross Under", "", "NO");
    strategy.parameters:addStringAlternative("Action".. 12, "No Action", "", "NO");
    strategy.parameters:addStringAlternative("Action".. 12, "Sell", "", "SELL");
    strategy.parameters:addStringAlternative("Action".. 12, "Buy", "", "BUY");
    strategy.parameters:addStringAlternative("Action".. 12, "Close Position", "", "CLOSE");
    strategy.parameters:addStringAlternative("Action".. 12, "Alert", "", "Alert");
    
    
    strategy.parameters:addString("Action".. 13, "SA /  SB  Cross Over", "", "NO");
    strategy.parameters:addStringAlternative("Action".. 13, "No Action", "", "NO");
    strategy.parameters:addStringAlternative("Action".. 13, "Sell", "", "SELL");
    strategy.parameters:addStringAlternative("Action".. 13, "Buy", "", "BUY");
    strategy.parameters:addStringAlternative("Action".. 13, "Close Position", "", "CLOSE");
    strategy.parameters:addStringAlternative("Action".. 13, "Alert", "", "Alert");
    
    strategy.parameters:addString("Action".. 14, "SA /  SB  Cross Under", "", "NO");
    strategy.parameters:addStringAlternative("Action".. 14, "No Action", "", "NO");
    strategy.parameters:addStringAlternative("Action".. 14, "Sell", "", "SELL");
    strategy.parameters:addStringAlternative("Action".. 14, "Buy", "", "BUY");
    strategy.parameters:addStringAlternative("Action".. 14, "Close Position", "", "CLOSE");
    strategy.parameters:addStringAlternative("Action".. 14, "Alert", "", "Alert");
    
    strategy.parameters:addGroup("Strategy Parameters");
    strategy.parameters:addString("Direction", "Type of signal", "", "direct");
    strategy.parameters:addStringAlternative("Direction", "direct", "", "direct");
    strategy.parameters:addStringAlternative("Direction", "reverse", "", "reverse");

    strategy.parameters:addGroup("Time Parameters");
    strategy.parameters:addString("StartTime", "Start Time for Trading", "", "00:00:00");
    strategy.parameters:addString("StopTime", "Stop Time for Trading", "", "24:00:00");

    strategy.parameters:addBoolean("UseMandatoryClosing", "Use Mandatory Closing", "", false);
    strategy.parameters:addString("ExitTime", "Mandatory Closing  Time", "", "23:59:00");
    strategy.parameters:addInteger("ValidInterval", "Valid interval for operation in second", "", 60);

    CreateTradingParameters();
   
end

function CreateTradingParameters()
    strategy.parameters:addGroup("Trading Parameters");

    strategy.parameters:addBoolean("AllowTrade", "Allow strategy to trade", "", false);
    -- NG: optimizer/backtester hint
    strategy.parameters:setFlag("AllowTrade", core.FLAG_ALLOW_TRADE);
    strategy.parameters:addString("ALLOWEDSIDE", "Allowed side", "Allowed side for trading or signaling, can be Sell, Buy or Both", "Both");
    strategy.parameters:addStringAlternative("ALLOWEDSIDE", "Both", "", "Both");
    strategy.parameters:addStringAlternative("ALLOWEDSIDE", "Buy", "", "Buy");
    strategy.parameters:addStringAlternative("ALLOWEDSIDE", "Sell", "", "Sell");

    strategy.parameters:addBoolean("AllowMultiple", "Allow Multiple", "", true);
    strategy.parameters:addString("Account", "Account to trade on", "", "");
    strategy.parameters:setFlag("Account", core.FLAG_ACCOUNT);
    strategy.parameters:addInteger("Amount", "Trade Amount in Lots", "", 1, 1, 100);
    strategy.parameters:addBoolean("SetLimit", "Set Limit Orders", "", false);
    strategy.parameters:addInteger("Limit", "Limit Order in pips", "", 30, 1, 10000);
    strategy.parameters:addBoolean("SetStop", "Set Stop Orders", "", false);
    strategy.parameters:addInteger("Stop", "Stop Order in pips", "", 30, 1, 10000);
    strategy.parameters:addBoolean("TrailingStop", "Trailing stop order", "", false);

    strategy.parameters:addGroup("Alerts");
    strategy.parameters:addBoolean("ShowAlert", "ShowAlert", "", true);
    strategy.parameters:addBoolean("PlaySound", "Play Sound", "", false);
    strategy.parameters:addFile("SoundFile", "Sound File", "", "");
    strategy.parameters:setFlag("SoundFile", core.FLAG_SOUND);
    strategy.parameters:addBoolean("RecurrentSound", "Recurrent Sound", "", true);
    strategy.parameters:addBoolean("SendEmail", "Send Email", "", false);
    strategy.parameters:addString("Email", "Email", "", "");
    strategy.parameters:setFlag("Email", core.FLAG_EMAIL);
end

local Source;

local SoundFile = nil;
local RecurrentSound = false;
local ALLOWEDSIDE;
local AllowMultiple;
local AllowTrade;
local Offer;
local CanClose;
local Account;
local Amount;
local SetLimit;
local Limit;
local SetStop;
local Stop;
local TrailingStop;
local ShowAlert;
local Email;
local SendEmail;
local BaseSize;


local Action={};
local Direction;
local first={};

local Tenkan;
local Kijun;
local Senkou;
local ICH;

----- ATR ------
local ATR;
local currentAtr = 0;

local UseMandatoryClosing;
local ValidInterval;
local Number = 14;

-- Don't need to store hour + minute + second for each time
local OpenTime, CloseTime, ExitTime;
--
function Prepare( nameOnly)
    UseMandatoryClosing = instance.parameters.UseMandatoryClosing;   
    Direction = instance.parameters.Direction;    
    ValidInterval= instance.parameters.ValidInterval;
    
    Tenkan = instance.parameters.T;
    Kijun = instance.parameters.K;
    Senkou = instance.parameters.S;

    assert(instance.parameters.TF ~= "t1", "The time frame must not be tick");

    local name;
    name = profile:id() .. "( " .. instance.bid:name() 
    local i;
    
    for i = 1, Number, 1 do 
    Action[i]= instance.parameters:getString ("Action" .. i);
    end
    
    name = name  ..  " )";
    instance:name(name);
   
    -- NG: parsing of the time is moved to separate function
    local valid;
    OpenTime, valid = ParseTime(instance.parameters.StartTime);
    assert(valid, "Time " .. instance.parameters.StartTime .. " is invalid");
    CloseTime, valid = ParseTime(instance.parameters.StopTime);
    assert(valid, "Time " .. instance.parameters.StopTime .. " is invalid");
    ExitTime, valid = ParseTime(instance.parameters.ExitTime);
    assert(valid, "Time " .. instance.parameters.ExitTime .. " is invalid");

    PrepareTrading();

    if nameOnly then
        return ;
    end
    
    Source = ExtSubscribe(1, nil, instance.parameters.TF, instance.parameters.Type == "Bid", "bar");
   
    ICH = core.indicators:create("ICH", Source, Tenkan, Kijun, Senkou);
    ATR = core.indicators:create("ATR", Source, instance.parameters.atrN);
    
    first["SL"]=ICH.SL:first();
    first["TL"]=ICH.TL:first();
    first["SA"]=ICH.SA:first();
    first["CS"]=ICH.CS:first();
    first["SB"]=ICH.SB:first();
    first["PRICE"]=Source:first();

    if UseMandatoryClosing then
        core.host:execute("setTimer", 100, math.max(ValidInterval / 2, 1));
    end
end


function PrepareTrading()
    AllowMultiple =  instance.parameters.AllowMultiple;
    ALLOWEDSIDE = instance.parameters.ALLOWEDSIDE;

    local PlaySound = instance.parameters.PlaySound;
    if PlaySound then
        SoundFile = instance.parameters.SoundFile;
    else
        SoundFile = nil;
    end
    assert(not(PlaySound) or (PlaySound and SoundFile ~= ""), "Sound file must be chosen");

    ShowAlert = instance.parameters.ShowAlert;
    RecurrentSound = instance.parameters.RecurrentSound;

    SendEmail = instance.parameters.SendEmail;

    if SendEmail then
        Email = instance.parameters.Email;
    else
        Email = nil;
    end
    assert(not(SendEmail) or (SendEmail and Email ~= ""), "E-mail address must be specified");


    AllowTrade = instance.parameters.AllowTrade;
    if AllowTrade then
        Account = instance.parameters.Account;
        Amount = instance.parameters.Amount;
        BaseSize = core.host:execute("getTradingProperty", "baseUnitSize", instance.bid:instrument(), Account);
        Offer = core.host:findTable("offers"):find("Instrument", instance.bid:instrument()).OfferID;
        CanClose = core.host:execute("getTradingProperty", "canCreateMarketClose", instance.bid:instrument(), Account);
        SetLimit = instance.parameters.SetLimit;
        Limit = instance.parameters.Limit;
        SetStop = instance.parameters.SetStop;
        Stop = instance.parameters.Stop;
        TrailingStop = instance.parameters.TrailingStop;
    end
end


-- NG: create a function to parse time
function ParseTime(time)
    local Pos = string.find(time, ":");
    local h = tonumber(string.sub(time, 1, Pos - 1));
    time = string.sub(time, Pos + 1);
    Pos = string.find(time, ":");
    local m = tonumber(string.sub(time, 1, Pos - 1));
    local s = tonumber(string.sub(time, Pos + 1));
    return (h / 24.0 +  m / 1440.0 + s / 86400.0),                          -- time in ole format
           ((h >= 0 and h < 24 and m >= 0 and m < 60 and s >= 0 and s < 60) or (h == 24 and m == 0 and s == 0)); -- validity flag
end

function ExtUpdate(id, source, period)  -- The method called every time when a new bid or ask price appears.

    if AllowTrade then
        if not(checkReady("trades")) or not(checkReady("orders")) then
            return ;
        end
    end
    
       if id ~= 1   then
        return;
    end

    
  local now = core.host:execute("getServerTime");
    now = now - math.floor(now);

    if now >= OpenTime and now <= CloseTime then
        ICH:update(core.UpdateLast);
        ATR:update(core.UpdateLast);
        currentAtr = ATR[period];

        if period-1 > math.max( first["SL"],  first["TL"])  then   
            if core.crossesOver(ICH.SL, ICH.TL, period)then                                    
                ACTION(1,"SL/TL" ,"Over");                                
            end
            if core.crossesUnder(ICH.SL, ICH.TL, period) then        
                ACTION(2,"SL/TL" ,"Under");      
            end                
        end 

        if period-1 > math.max( first["CS"] +Kijun ,  first["PRICE"] +Kijun) then
            if core.crossesOver(ICH.CS, Source.close, period-Kijun, period-Kijun-1 ) then    
                ACTION(3,"CS / Price" ,"Over");    
            end      
            if core.crossesUnder(ICH.CS, Source.close, period-Kijun, period-Kijun-1 )  then    
                ACTION(4,"CS / Price" ,"Under");    
            end      
        end        
        
        if period-1 > math.max( first["SA"],  first["SB"]) then    
            if math.max(ICH.SA[period], ICH.SB[period])< Source.close[period] and  math.max(ICH.SA[period-1], ICH.SB[period-1]) > Source.close[period-1]   then    
                ACTION(5,"Top Cloud / Price" , "Over");
            end                                     
            if  math.max(ICH.SA[period], ICH.SB[period]) >  Source.close[period] and  math.max(ICH.SA[period-1], ICH.SB[period-1]) < Source.close[period-1]  then    
                ACTION(6,"Top Cloud / Price" ,"Under");
            end                
            if math.min(ICH.SA[period], ICH.SB[period]) < Source.close[period] and  math.min(ICH.SA[period-1], ICH.SB[period-1]) > Source.close[period-1] then                                    
                ACTION(7,"Bottom Cloud / Price" ,"Over");    
            end                                    
            if   math.min(ICH.SA[period], ICH.SB[period])> Source.close[period] and  math.min(ICH.SA[period-1], ICH.SB[period-1]) < Source.close[period-1] then        
                ACTION(8,"Bottom Cloud / Price" ,"Under");    
            end              
        end
        
        
        if period-1 > math.max( first["CS"] +Kijun+1 ,  first["SA"]) then
            if ICH.CS[period-Kijun-1] < math.max(ICH.SA[period-1-Kijun], ICH.SB[period-1-Kijun]) and ICH.CS[period-Kijun] > math.max(ICH.SA[period-Kijun], ICH.SB[period-Kijun]) then    
                ACTION(9,"CS / Top Cloud" ,"Over");    
            end      
            if ICH.CS[period-Kijun-1] > math.max(ICH.SA[period-1-Kijun], ICH.SB[period-1-Kijun]) and ICH.CS[period-Kijun] < math.max(ICH.SA[period-Kijun], ICH.SB[period-Kijun]) then    
                ACTION(10,"CS / Top Cloud" ,"Under");    
            end      

            if ICH.CS[period-Kijun-1] < math.min(ICH.SA[period-1-Kijun], ICH.SB[period-1-Kijun]) and ICH.CS[period-Kijun] > math.min(ICH.SA[period-Kijun], ICH.SB[period-Kijun])  then    
                ACTION(11,"SA / SB" ,"Over");    
            end      
            if  ICH.CS[period-Kijun-1] > math.min(ICH.SA[period-1-Kijun], ICH.SB[period-1-Kijun]) and ICH.CS[period-Kijun] < math.min(ICH.SA[period-Kijun], ICH.SB[period-Kijun])   then    
                ACTION(12,"SA / SB" ,"Under");    
            end      
        end        

        if period >  first["SA"] then
            if  core.crossesOver(ICH.SA,ICH.SB, period+Kijun ) then
                ACTION(13,"CS / Bottom Cloud" ,"Over");
            end

            if  core.crossesUnder(ICH.SA,ICH.SB, period+Kijun ) then
                ACTION(14,"CS / Bottom Cloud" ,"Over");
            end
        end
    end
end

-- NG: Introduce async function for timer/monitoring for the order results
function ExtAsyncOperationFinished(cookie, success, message)
    if cookie == 100 then
        -- timer
        if UseMandatoryClosing and AllowTrade then
            now = core.host:execute("getServerTime");
            -- get only time
            now = now - math.floor(now);
            -- check whether the time is in the exit time period
            if now >= ExitTime and now < ExitTime + ValidInterval then
                if not(checkReady("trades")) or not(checkReady("orders")) then
                    return ;
                end
                if haveTrades("S") then
                    exit("S");
                    Signal ("Close Short");
                end
                if haveTrades("B") then
                   exit("B");
                   Signal ("Close Long");
               end
            end
        end
    elseif cookie == 200 and not success then
        terminal:alertMessage(instance.bid:instrument(), instance.bid[instance.bid:size() - 1], "Open order failed" .. message, instance.bid:date(instance.bid:size() - 1));
    elseif cookie == 201 and not success then
        terminal:alertMessage(instance.bid:instrument(), instance.bid[instance.bid:size() - 1], "Close order failed" .. message, instance.bid:date(instance.bid:size() - 1));
    end
end



function ACTION (Flag, Line, Label)

    if Action[Flag] ==  "NO" then
    return;                                
    elseif Action[Flag] ==  "BUY" then
    
        BUY();
    
    elseif Action[Flag] ==  "SELL" then                

        SELL();

    elseif Action[Flag] ==  "CLOSE" then
    
        if AllowTrade then
                                                
            if haveTrades('B') then
                exit('B');
                Signal ("Close Long");
            end                            
                    
            if haveTrades('S') then
                exit('S');
                Signal ("Close Short");
            end    
        else
             
            Signal ("Close All");                                    
        end    
    elseif Action[Flag] ==  "Alert" then                                         
        Signal (Line .. " Line Cross" .. Label );                         
    end

end

--===========================================================================--
--                    TRADING UTILITY FUNCTIONS                              --
--============================================================================--


function BUY()
         
    if AllowTrade then

        if haveTrades('B')  and not  AllowMultiple then
            if     haveTrades('S')     then
                exit('S');
                Signal ("Close Short");
            end    
                                            
            return;
        end
                        
        if ALLOWEDSIDE == "Sell"   then
            if     haveTrades('S')     then
                exit('S');
                Signal ("Close Short");
            end    

            return;
        end 
        
        if haveTrades('S') then
            exit('S');
            Signal ("Close Short");
        end
        enter('B');
        Signal ("Open Long");
                                
    elseif ShowAlert then
        Signal ("Up Trend");          
    end

end   
    
function SELL ()

    if AllowTrade then
    
        if haveTrades('S')  and not  AllowMultiple then
            if     haveTrades('B') then
                exit('B');
                Signal ("Close Long");
            end
            return;
        end
        if ALLOWEDSIDE == "Buy"  then
            if  haveTrades('B') then
                exit('B');
                Signal ("Close Long");
            end
            return;
        end

        if haveTrades('B') then
            exit('B');
            Signal ("Close Long");
        end
        enter('S');
        Signal ("Open Short");                                                                                
    else
        Signal ("Down Trend");
    end                 
    
end

function Signal (Label)

    if ShowAlert then
        terminal:alertMessage(instance.bid:instrument(), instance.bid[NOW],  Label, instance.bid:date(NOW));
    end
    if SoundFile ~= nil then
        terminal:alertSound(SoundFile, RecurrentSound);
    end
    
    if Email ~= nil then
       terminal:alertEmail(Email, Label, profile:id() .. "(" .. instance.bid:instrument() .. ")" .. instance.bid[NOW]..", " .. Label..", " .. instance.bid:date(NOW));
    end
end                                

function checkReady(table)
    local rc;
    if Account == "TESTACC_ID" then
        -- run under debugger/simulator
        rc = true;
    else
        rc = core.host:execute("isTableFilled", table);
    end
    return rc;
end

function tradesCount(BuySell) 
    local enum, row;
    local count = 0;
    enum = core.host:findTable("trades"):enumerator();
    row = enum:next();
    while count == 0 and row ~= nil do
        if row.AccountID == Account and
           row.OfferID == Offer and
           (row.BS == BuySell or BuySell == nil) then
           count = count + 1;
        end
        row = enum:next();
    end

    return count
end


function haveTrades(BuySell) 
    local enum, row;
    local found = false;
    enum = core.host:findTable("trades"):enumerator();
    row = enum:next();
    while (not found) and (row ~= nil) do
        if row.AccountID == Account and
           row.OfferID == Offer and
           (row.BS == BuySell or BuySell == nil) then
           found = true;
        end
        row = enum:next();
    end

    return found
end

-- enter into the specified direction
function enter(BuySell)
    if not(AllowTrade) then
        return true;
    end

    -- do not enter if position in the
    -- specified direction already exists
    if tradesCount(BuySell) > 0 and not  AllowMultiple  then
        return true;
    end

    local valuemap, success, msg;
    valuemap = core.valuemap();

    valuemap.OrderType = "OM";
    valuemap.OfferID = Offer;
    valuemap.AcctID = Account;
    valuemap.Quantity = Amount * BaseSize;
    valuemap.BuySell = BuySell;

    -- add stop/limit

    valuemap.PegTypeStop = "O";
    if SetStop then 
        if BuySell == "B" then
            valuemap.PegPriceOffsetPipsStop = -Stop;
        else
            valuemap.PegPriceOffsetPipsStop = Stop;
        end
    end
    if TrailingStop then
        valuemap.TrailStepStop = 1;
    end

    valuemap.PegTypeLimit = "O";
    if SetLimit then
        if BuySell == "B" then
            valuemap.PegPriceOffsetPipsLimit = Limit;
        else
            valuemap.PegPriceOffsetPipsLimit = -Limit;
        end
    end

    if (not CanClose) then
        valuemap.EntryLimitStop = 'Y'
    end


    success, msg = terminal:execute(100, valuemap);

    if not(success) then
        terminal:alertMessage(instance.bid:instrument(), instance.bid[instance.bid:size() - 1], "Open order failed" .. msg, instance.bid:date(instance.bid:size() - 1));
        return false;
    end

    return true;
end

-- exit from the specified direction
function exit(BuySell)
    if not(AllowTrade) then
        return true;
    end

    local valuemap, success, msg;

    if tradesCount(BuySell) > 0 then
        valuemap = core.valuemap();

        -- switch the direction since the order must be in oppsite direction
        if BuySell == "B" then
            BuySell = "S";
        else
            BuySell = "B";
        end
        valuemap.OrderType = "CM";
        valuemap.OfferID = Offer;
        valuemap.AcctID = Account;
        valuemap.NetQtyFlag = "Y";
        valuemap.BuySell = BuySell;
        success, msg = terminal:execute(101, valuemap);

        if not(success) then
            terminal:alertMessage(instance.bid:instrument(), instance.bid[instance.bid:size() - 1], "Open order failed" .. msg, instance.bid:date(instance.bid:size() - 1));
            return false;
        end
        return true;
    end
    return false;
end

dofile(core.app_path() .. "\\strategies\\standard\\include\\helper.lua");
        
        
        