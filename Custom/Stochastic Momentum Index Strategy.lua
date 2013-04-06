function Init() --The strategy profile initialization
    strategy:name("Stochastic Momentum Index Strategy");
    strategy:description("Stochastic Momentum Index Strategy");

    strategy.parameters:addGroup("Parameters");
    strategy.parameters:addInteger("Period_Q", "Period_Q", "Period_Q", 2);
    strategy.parameters:addInteger("Period_R", "Period_R", "Period_R", 8);
    strategy.parameters:addInteger("Period_S", "Period_S", "Period_S", 5);
    strategy.parameters:addInteger("Period_Signal", "Period_Signal", "Period_Signal", 5);

    strategy.parameters:addGroup("Strategy Parameters");
    strategy.parameters:addString("TypeSignal", "Type of signal", "", "direct");
    strategy.parameters:addStringAlternative("TypeSignal", "direct", "", "direct");
    strategy.parameters:addStringAlternative("TypeSignal", "reverse", "", "reverse");

    strategy.parameters:addGroup("Price Parameters");
    strategy.parameters:addString("TF", "Time Frame", "", "m1");
    strategy.parameters:setFlag("TF", core.FLAG_PERIODS);

    strategy.parameters:addGroup("Trading Parameters");
    strategy.parameters:addBoolean("AllowTrade", "Allow strategy to trade", "", true);
    strategy.parameters:addString("Account", "Account to trade on", "", "");
    strategy.parameters:setFlag("Account", core.FLAG_ACCOUNT);
    strategy.parameters:addInteger("Amount", "Trade Amount in Lots", "", 1, 1, 100);
    strategy.parameters:addBoolean("SetLimit", "Set Limit Orders", "", true);
    strategy.parameters:addInteger("Limit", "Limit Order in pips", "", 30, 1, 10000);
    strategy.parameters:addBoolean("SetStop", "Set Stop Orders", "", true);
    strategy.parameters:addInteger("Stop", "Stop Order in pips", "", 30, 1, 10000);
    strategy.parameters:addBoolean("TrailingStop", "Trailing stop order", "", false);
    strategy.parameters:addString("AllowDirection", "Allow direction for positions", "", "Both");
    strategy.parameters:addStringAlternative("AllowDirection", "Both", "", "Both");
    strategy.parameters:addStringAlternative("AllowDirection", "Long", "", "Long");
    strategy.parameters:addStringAlternative("AllowDirection", "Short", "", "Short");
	strategy.parameters:addString("MagicNumber", "MagicNumber", " No Description ", "123456");

    strategy.parameters:addGroup("Signal Parameters");
    strategy.parameters:addBoolean("ShowAlert", "Show Alert", "", true);
    strategy.parameters:addBoolean("PlaySound", "Play Sound", "", false);
    strategy.parameters:addFile("SoundFile", "Sound File", "", "");
    strategy.parameters:setFlag("SoundFile", core.FLAG_SOUND);
    strategy.parameters:addBoolean("Recurrent", "RecurrentSound", "", false);

    strategy.parameters:addGroup("Email Parameters");
    strategy.parameters:addBoolean("SendEmail", "Send email", "", false);
    strategy.parameters:addString("Email", "Email address", "", "");
    strategy.parameters:setFlag("Email", core.FLAG_EMAIL);
end

-- Signal Parameters
local ShowAlert;
local SoundFile;
local RecurrentSound;
local SendEmail, Email;

-- Internal indicators
local SMI = nil;

-- Strategy parameters
local openLevel = 0
local closeLevel = 0
local confirmTrend;

-- Trading parameters
local AllowTrade = nil;
local Account = nil;
local Amount = nil;
local BaseSize = nil;
local PipSize;
local SetLimit = nil;
local Limit = nil;
local SetStop = nil;
local Stop = nil;
local TrailingStop = nil;
local CanClose = nil;
local AllowDirection;


function Prepare()
    ShowAlert = instance.parameters.ShowAlert;
    AllowDirection = instance.parameters.AllowDirection;
    local PlaySound = instance.parameters.PlaySound
    if  PlaySound then
        SoundFile = instance.parameters.SoundFile;
    else
        SoundFile = nil;
    end
    assert(not(PlaySound) or SoundFile ~= "", "Sound file must be chosen");
    RecurrentSound = instance.parameters.Recurrent;

    local SendEmail = instance.parameters.SendEmail;
    if SendEmail then
        Email = instance.parameters.Email;
    else
        Email = nil;
    end
    assert(not(SendEmail) or Email ~= "", "Email address must be specified");
    assert(instance.parameters.TF ~= "t1", "The time frame must not be tick");

    local name;
    name = profile:id() .. "(" .. instance.bid:name() .. "." .. instance.parameters.TF .. "," .. ")";
    instance:name(name);

	core.host:trace(GetTimeString(core.now()) .. " The Stochastic Momentum Index Strategy is Implemented Successfully in Time Frame -" .. instance.parameters.TF);

    AllowTrade = instance.parameters.AllowTrade;
    if AllowTrade then
        Account = instance.parameters.Account;
        Amount = instance.parameters.Amount;
        BaseSize = core.host:execute("getTradingProperty", "baseUnitSize", instance.bid:instrument(), Account);
        Offer = core.host:findTable("offers"):find("Instrument", instance.bid:instrument()).OfferID;
        CanClose = core.host:execute("getTradingProperty", "canCreateMarketClose", instance.bid:instrument(), Account);
        PipSize = instance.bid:pipSize();
        SetLimit = instance.parameters.SetLimit;
        Limit = instance.parameters.Limit;
        SetStop = instance.parameters.SetStop;
        Stop = instance.parameters.Stop;
        TrailingStop = instance.parameters.TrailingStop;
    end

    Source = ExtSubscribe(2, nil, instance.parameters.TF, true, "bar");
    SMI = core.indicators:create("STOCHASTIC MOMENTUM INDEX", Source, instance.parameters.Period_Q, instance.parameters.Period_R, instance.parameters.Period_S, instance.parameters.Period_Signal);

    ExtSetupSignal(profile:id() .. ":", ShowAlert);
    ExtSetupSignalMail(name);
end

function ExtUpdate(id, source, period)  -- The method called every time when a new bid or ask price appears.
    SMI:update(core.UpdateLast);

    -- Check that we have enough data
    if (SMI.DATA:first() > (period - 1)) then
        return
    end

    local pipSize = instance.bid:pipSize()

    local trades = core.host:findTable("trades");
    local haveTrades = (trades:find('AccountID', Account) ~= nil)

    local MustOpenB=false;
    local MustOpenS=false;

	if SMI.DataBuff[period-1]>SMI.SignalBuff[period-1] and SMI.DataBuff[period]<SMI.SignalBuff[period] then
--		core.host:trace(GetTimeString(source:date(period)) .. string.format(" For Previous Bar, SMI Data value %f, is greater than SMI Signal value %f, by %f", SMI.DataBuff[period - 1], SMI.SignalBuff[period-1], SMI.DataBuff[period - 1] - SMI.SignalBuff[period-1]));
--		core.host:trace(GetTimeString(source:date(period)) .. string.format(" For Current Bar, SMI Data value %f, is less than SMI Signal value %f, by %f", SMI.DataBuff[period], SMI.SignalBuff[period], SMI.DataBuff[period] - SMI.SignalBuff[period]));
--		core.host:trace(GetTimeString(source:date(period)) .. " SMI Indicator Line crosses SMI Signal Line from ABOVE to BELOW ");
		if instance.parameters.TypeSignal=="direct" then
			MustOpenB=true;
		else
			MustOpenS=true;
		end
    end

    if SMI.DataBuff[period-1]<SMI.SignalBuff[period-1] and SMI.DataBuff[period]>SMI.SignalBuff[period] then
--		core.host:trace(GetTimeString(source:date(period)) .. string.format(" For Current Bar, SMI Data value %f, is greater than SMI Signal value %f, by %f", SMI.DataBuff[period], SMI.SignalBuff[period], SMI.DataBuff[period] - SMI.SignalBuff[period]));
--		core.host:trace(GetTimeString(source:date(period)) .. string.format(" For Previous Bar, SMI Data value %f, is less than SMI Signal value %f, by %f", SMI.DataBuff[period - 1], SMI.SignalBuff[period-1], SMI.DataBuff[period - 1] - SMI.SignalBuff[period-1]));
--		core.host:trace(GetTimeString(source:date(period)) .. " SMI Indicator Line crosses SMI Signal Line from BELOW to ABOVE ");
		if instance.parameters.TypeSignal=="direct" then
			MustOpenS=true;
		else
			MustOpenB=true;
		end
    end

    if (haveTrades) then
        local enum = trades:enumerator();
        while true do
            local row = enum:next();
            if row == nil then break end
				if row.AccountID == Account and row.OfferID == Offer then
					-- Close position if we have corresponding closing conditions.
					if row.BS == 'B' then
						if MustOpenS then
							if ShowAlert then
								if instance.parameters.AllowDirection=="Long" then

									ExtSignal(source, period, "Close BUY", SoundFile, Email, RecurrentSound);
								else
								ExtSignal(source, period, "Close BUY and SELL", SoundFile, Email, RecurrentSound);
							end
						end
						if AllowTrade then
							Close(row);
							if instance.parameters.AllowDirection~="Long" then
--								core.host:trace(GetTimeString(source:date(period)) .. " Sending signal to Open SELL" );
								Open("S", Amount)
							end
						end
					end
					elseif row.BS == 'S' then
					if MustOpenB then
						if ShowAlert then
							if instance.parameters.AllowDirection=="Short" then
								ExtSignal(source, period, "Close SELL", SoundFile, Email, RecurrentSound);
							else

								ExtSignal(source, period, "Close SELL and BUY", SoundFile, Email, RecurrentSound);
							end
						end
						if AllowTrade then
							Close(row);
							if instance.parameters.AllowDirection~="Short" then
--								core.host:trace(GetTimeString(source:date(period)) .. " Sending signal to Open BUY" );
								Open("B", Amount)
							end
						end
					end
				end
			end
		end
	else
		if MustOpenB==true and instance.parameters.AllowDirection~="Short" then
			if ShowAlert then
				ExtSignal(source, period, "BUY", SoundFile, Email, RecurrentSound)
			end
			if AllowTrade then
--				core.host:trace(GetTimeString(source:date(period)) .. " No Trades present, sending signal to Open a BUY Trade! ");
				Open("B", Amount)
			end
		end
		if MustOpenS==true and instance.parameters.AllowDirection~="Long" then
            if ShowAlert then
            	ExtSignal(source, period, "SELL", SoundFile, Email, RecurrentSound)
			end
            if AllowTrade then
--				core.host:trace(GetTimeString(source:date(period)) .. " No Trades present, sending signal to Open a SELL Trade! ");
                Open("S", Amount)
			end
        end
    end
end


-- The strategy instance finalization.
function ReleaseInstance()
end

function tradesCount(BuySell)
    local enum, row;
    local count = 0;
    enum = core.host:findTable("trades"):enumerator();
    row = enum:next();
    while count == 0 and row ~= nil do
        if row.AccountID == Account and
           row.OfferID == Offer and
           (row.BS == BuySell or BuySell == nil)  and
		   row.QTXT == "Programming Services" .. " " .. profile:id() .. " " .. instance.parameters.MagicNumber then
           count = count + 1;
        end
        row = enum:next();
    end
    return count
end

-- The method enters to the market
function Open(side, aLotSize)
	if not(AllowTrade) then
		return true;
	end

	-- do not enter if position in the
    -- specified direction already exists
	if tradesCount(side) > 0 then
        return true;
    end

	local valuemap, success, msg;

    valuemap = core.valuemap();

	valuemap.OrderType = "OM";
    valuemap.OfferID = Offer;
    valuemap.AcctID = Account;
    valuemap.Quantity = aLotSize * BaseSize;
	valuemap.PegTypeStop = "M";
	valuemap.CustomID = "Programming Services" .. " " .. profile:id() .. " " .. instance.parameters.MagicNumber;
	valuemap.BuySell = side;
	if SetLimit then
		if side == "B" then
			valuemap.RateLimit = instance.ask[NOW] + (Limit * instance.bid:pipSize());
		else
			valuemap.RateLimit = instance.bid[NOW] - (Limit * instance.bid:pipSize());
		end
	end

	if SetStop then
		if side == "B" then
			valuemap.RateStop = instance.ask[NOW] - (Stop * instance.bid:pipSize());
		else
			valuemap.RateStop = instance.bid[NOW] + (Stop * instance.bid:pipSize());
		end
	end

	if TrailingStop then
		valuemap.TrailStepStop = 1;
	end

	if (not CanClose) and (Limit > 0) then
		valuemap.EntryLimitStop = 'Y';
	end

    success, msg = terminal:execute(100, valuemap);

	if not(success) then
        terminal:alertMessage(instance.bid:instrument(), instance.bid[instance.bid:size() - 1], "alert_OpenOrderFailed" .. msg, instance.bid:date(instance.bid:size() - 1));
        return false;
    end

	return true;

end

-- Closes specific position
function Close(trade,source, period)
    local valuemap, success, msg;

	if not(AllowTrade) then
        return true;
	end

	if tradesCount(trade.BS) > 0 then
		valuemap = core.valuemap();
		if CanClose then
			-- non-FIFO account, create a close market order
			valuemap.OrderType = "CM";
			valuemap.TradeID = trade.TradeID;
--			core.host:trace(GetTimeString(core.now()) .. " Account type = Non-FIFO, Hence create a Close Market Order ");
		else
			-- FIFO account, create an opposite market order
			valuemap.OrderType = "OM";
--			core.host:trace(GetTimeString(core.now()) .. " Account type = FIFO, Hence create a Opposite Market Order ");
		end

		valuemap.OfferID = trade.OfferID;
		valuemap.AcctID = trade.AccountID;
		valuemap.Quantity = trade.Lot;
		valuemap.CustomID = "Programming Services" .. " " .. profile:id() .. " " .. instance.parameters.MagicNumber;

		if trade.BS == "B" then
			valuemap.BuySell = "S";
		else
			valuemap.BuySell = "B";
		end

		success, msg = terminal:execute(101, valuemap);
		if not(success) then
            terminal:alertMessage(instance.bid:instrument(), instance.bid[instance.bid:size() - 1], "Open order failed" .. msg, instance.bid:date(instance.bid:size() - 1));
            return false;
        end

		return true;

	else
		return false;
	end
end

function GetTimeString(date)
    local dateTable = core.dateToTable(date);
	local str = string.format("%02i/%02i/%04i  %02i:%02i:%02i",dateTable.month, dateTable.day, dateTable.year, dateTable.hour, dateTable.min, dateTable.sec);
    return str;
end

dofile(core.app_path() .. "\\strategies\\standard\\include\\helper.lua");
