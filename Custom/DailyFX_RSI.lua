-- Strategy profile initialization routine
-- Defines Strategy profile properties and Strategy parameters
-- TODO: Add minimal and maximal value of numeric parameters and default color of the streams
function Init()
    strategy:name("DailyFX_RSI");
    strategy:description("No description");

    strategy.parameters:addGroup("Price Parameters");
    strategy.parameters:addString("TF", "TF", "Time frame ('t1', 'm1', 'm5', etc.)", "m1");
    strategy.parameters:setFlag("TF", core.FLAG_PERIODS);
    strategy.parameters:addGroup("Parameters");
    strategy.parameters:addInteger("LotSize", "LotSize", "Sets the lot size for the trade", 1);
    strategy.parameters:addInteger("StopLoss", "StopLoss", "Sets the stop loss for the trade in pips.  If Stop Loss = 0 then do not use stop loss", 115);
    strategy.parameters:addInteger("TakeProfit", "TakeProfit", "Sets the take profit for the trade in pips.  If Take Profit = 0, then do not use Take Profit", 120);
    strategy.parameters:addInteger("RSIPeriod", "RSIPeriod", "Sets the period for the RSI indicator", 14);
    strategy.parameters:addDouble("RSIOverbought", "RSIOverbought", "sets the overbought line for the indicator", 70);
    strategy.parameters:addDouble("RSIOversold", "RSIOversold", "sets the oversold line for the indicator", 30);
    strategy.parameters:addString("MagicNumber", "MagicNumber", "No description", "123456");
    strategy.parameters:addBoolean("Debug", "Debug", "No description", false);

    strategy.parameters:addGroup("Trading Parameters");
    strategy.parameters:addString("Account", "Account to trade on", "", "");
    strategy.parameters:setFlag("Account", core.FLAG_ACCOUNT);
end

-- strategy instance initialization routine
-- Processes strategy parameters and creates output streams
-- TODO: Calculate all constants, create instances all necessary indicators and load all required libraries
-- Parameters block
local LotSize;
local StopLoss;
local TakeProfit;
local RSIPeriod;
local RSIOverbought;
local RSIOversold;
local MagicNumber;
local gSource = nil; -- the source stream
local AllowTicks = true;
local PlaySound;
local RecurrentSound;
local SoundFile;
local Email;
local SendEmail;
local AllowTrade;
local Account;
local Amount;
local BaseSize;
local SetLimit;
local Limit;
local SetStop;
local Stop;
local TrailingStop;
local Offer;
local CanClose;
--TODO: Add variable(s) for your indicator(s) if needed
local RSIIndicator;
local fileName = "";
local CustomTXT;

-- Routine
function Prepare(nameOnly)
    LotSize = instance.parameters.LotSize;
    StopLoss = instance.parameters.StopLoss;
    TakeProfit = instance.parameters.TakeProfit;
    RSIPeriod = instance.parameters.RSIPeriod;
    RSIOverbought = instance.parameters.RSIOverbought;
    RSIOversold = instance.parameters.RSIOversold;
    MagicNumber = instance.parameters.MagicNumber;

    local name = profile:id() .. "(" .. instance.bid:instrument() .. ", " .. tostring(LotSize) .. ", " .. tostring(StopLoss) .. ", " .. tostring(TakeProfit) .. ", " .. tostring(RSIPeriod) .. ", " .. tostring(RSIOverbought) .. ", " .. tostring(RSIOversold) .. ", " .. tostring(MagicNumber) .. ")";
    instance:name(name);

    if nameOnly then
        return ;
    end

    if (not(AllowTicks)) then
        assert(instance.parameters.TF ~= "t1", "The strategy cannot be applied on ticks.");
    end

    Account = instance.parameters.Account;
    BaseSize = core.host:execute("getTradingProperty", "baseUnitSize", instance.bid:instrument(), Account);
    Offer = core.host:findTable("offers"):find("Instrument", instance.bid:instrument()).OfferID;
    CanClose = core.host:execute("getTradingProperty", "canCreateMarketClose", instance.bid:instrument(), Account);
    Limit = instance.parameters.TakeProfit * instance.bid:pipSize();
    Stop = instance.parameters.StopLoss * instance.bid:pipSize();

    gSource = ExtSubscribe(1, nil, instance.parameters.TF, true, "bar"); 
    --TODO: Find indicator's profile, intialize parameters, and create indicator's instance (if needed)

    RSIIndicator = core.indicators:create("RSI", gSource.close, RSIPeriod);

    CustomTXT = "PSS_DailyFX_RSI_"..MagicNumber;

    local cur = instance.bid:instrument();
    local pos = string.find(cur, "/");
    if pos ~= nil then
        cur = string.sub(cur, 0, pos-1)..string.sub(cur, pos+1);
    end
	fileName = tostring("c:\\Marketscope Logs\\" .. profile:id().."_"..tostring(cur).."_"..instance.parameters.TF.."_"..tostring(MagicNumber)..".txt");
	--fileName = "c://Marketscope Logs//FXCM_001199_EURUSD_m1_123456.txt";
	core.host:trace("fileName: " .. fileName);
    os.execute('MKDIR "'.."c://Marketscope Logs//"..'"');
    printToFile(name .. "----------------------------------------------------");
end

-- strategy calculation routine
-- TODO: Add your code for decision making
-- TODO: Update the instance of your indicator(s) if needed
function ExtUpdate(id, source, period)
    RSIIndicator:update(core.UpdateLast);
    local RSI = RSIIndicator.RSI;

    --Do not do anything before data is complete
    if period < 1 or not(RSI:hasData(period - 1)) then
        return ;
    end

    --when RSI crosses over oversold, buying logic
    --core.host:trace("RSI: ".. tostring(RSI) .. ", " .. "RSIOversold:" .. tostring(RSIOversold));
	if core.crossesOver(RSI, RSIOversold, period) then
        --close short trades first
        if haveTrades("S") then
            exit("S");
			core.host:trace("Closing Existing Sell trade.");
        end
        if not haveTrades("B") then
            printToFile(core.formatDate(source:date(period)).."   Buy signal triggered. RSI - "..tostring(RSI[period]).." crossed over RSIOverbought:"..tostring(RSIOverbought));
            enter("B");
        end
    end
    --When RSI crosses under overbought, selling logic
    --core.host:trace("RSI: ".. tostring(RSI) .. ", " .. "RSIOverbought:" .. tostring(RSIOverbought));
	if core.crossesUnder(RSI, RSIOverbought, period) then
        --close long trade first
        if haveTrades("B") then
            exit("B");
			core.host:trace("Closing Existing Buy trade.");
        end
        if not haveTrades("S") then
            printToFile(core.formatDate(source:date(period)).."   Sell signal triggered. RSI - "..tostring(RSI[period]).." crossed over RSIOversold:"..tostring(RSIOversold));
            enter("S");
        end
    end
end


function enter(BuySell)
    local valuemap, success, msg;
    valuemap = core.valuemap();

    valuemap.OrderType = "OM";
    valuemap.OfferID = Offer;
    valuemap.AcctID = Account;
    valuemap.Quantity = LotSize * BaseSize;
    valuemap.BuySell = BuySell;
    valuemap.PegTypeStop = "M";
    valuemap.GTC = "GTC";
    valuemap.CustomID = CustomTXT;

    if TakeProfit > 0 then
        -- set limit order
        if BuySell == "B" then
            valuemap.RateLimit = instance.ask[NOW] + Limit;
        else
            valuemap.RateLimit = instance.bid[NOW] - Limit;
        end
    end

    if StopLoss > 0 then
        -- set limit order
        if BuySell == "B" then
            valuemap.RateStop = instance.ask[NOW] - Stop;
        else
            valuemap.RateStop = instance.bid[NOW] + Stop;
        end
    end

    if (not CanClose) and (StopLoss > 0 or TakeProfit > 0) then
        valuemap.EntryLimitStop = 'Y'
    end
    
    success, msg = terminal:execute(100, valuemap);

    if not(success) then
        terminal:alertMessage(instance.bid:instrument(), instance.bid[instance.bid:size() - 1], "alert_OpenOrderFailed: " .. msg, instance.bid:date(instance.bid:size() - 1));
        return false;
    end

    return true;
end


-- -----------------------------------------------------------------------
-- Return count of opened trades for spicific direction
-- (both directions if BuySell parameters is 'nil')
-- -----------------------------------------------------------------------
function haveTrades(BuySell)
    local enum, row;
    local found = false;
    enum = core.host:findTable("trades"):enumerator();
    row = enum:next();
    while (not found) and (row ~= nil) do
        if row.AccountID == Account and
           row.OfferID == Offer and
           (row.BS == BuySell or BuySell == nil) and
           row.QTXT == CustomTXT then
           found = true;
        end
        row = enum:next();
    end

    return found;
end

-- exit from the specified direction
function exit(BuySell)
    local valuemap, success, msg;
    if haveTrades(BuySell) then
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
        valuemap.GTC = "GTC";
        valuemap.CustomID = CustomTXT;

        success, msg = terminal:execute(101, valuemap);

        if not(success) then
            terminal:alertMessage(instance.bid:instrument(), instance.bid[instance.bid:size() - 1], "alert_OpenOrderFailed" .. msg, instance.bid:date(instance.bid:size() - 1));
        end
    end
end

local File;

function printToFile(message)
	if instance.parameters.Debug == true then
		--try
			File = io.open(fileName, "a");
			File:write(message.."\n");
			File:flush();
			File:close();
		--catch err do
		--	core.host:trace("An error occured: "..err);
		--end
	end
	core.host:trace(message);
end

dofile(core.app_path() .. "\\strategies\\standard\\include\\helper.lua");

