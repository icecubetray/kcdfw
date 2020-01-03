kcdfw.log = function (level, fmt, ...)
	local trueLevel = (level & 0x0FFF);
	if trueLevel > kcdfw.logLevel then
		return;
	end

	local frame = debug.getinfo(2 + ((level & KCDFW_FLAG_EXTRA_FRAME) >> 12));
	local sauce = frame.source;
	local line = frame.currentline;
	local idx = sauce:find(kcdfw.paths.root);
	if idx then
		if kcdfw.distribution then
			sauce = "KCDFW";
		else
			sauce = ("%s" .. ((line > 0 and ":%u") or "")):format(sauce:sub(#kcdfw.paths.root + idx + 1), line);
		end
	else
		-- sauce = "External";
	end

	local strFormatted;
	if ((level & KCDFW_FLAG_NO_PREFIX) == KCDFW_FLAG_NO_PREFIX) then
		strFormatted = fmt:format(...);
	else
		if trueLevel > 0 then
			strFormatted = (("%s %s %s"):format("[%s]", "(%s)", fmt)):format(sauce, trueLevel, ...);
		else
			strFormatted = (("%s %s"):format("[%s]", fmt)):format(sauce, ...);
		end
	end

	if not kcdfw.runLocal then
		System.LogAlways(strFormatted);
	else
		print(strFormatted);
	end
end

kcdfw.logNotice("Logging function upgraded.");
kcdfw.logBootstrap("Permitted log levels set to %u to %u.", KCDFW_LEVEL_BOOTSTRAP, kcdfw.logLevel);




kcdfw.normalizeCmdlineKey = function(key)
	return key:gsub("^-*", ""):gsub("=.*$", "");
end

kcdfw.parseCmdline = function(cmdline, nonoptions)
	local found = {};
	local nopts = (nonoptions or {});

	local key = nil;
	local optend = false;
	for arg in cmdline:gmatch("%S+") do
		if not optend then
			if arg:sub(1, 1) == '-' then
				if key then
					found[key] = true
				end

				if arg == '--' then
					key = nil;
					optend = true;
				else
					key = kcdfw.normalizeCmdlineKey(arg);
				end
			else
				if key then
					found[key] = arg;
					key = nil;
				else
					table.insert(nopts, arg);
				end
			end
		else
			table.insert(nopts, arg);
		end
	end

	if key then
		found[key] = true
		key = nil;
	end

	-- For any key=value pairs, override.
	for key, value in cmdline:gsub(" -- .*", ""):gmatch("-?(%S+)=(%S+)") do
		found[kcdfw.normalizeCmdlineKey(key)] = value;
	end

	return found;
end
