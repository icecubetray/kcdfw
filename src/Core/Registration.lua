kcdfw.registerCommand = function(command, expr, description, usage)
	local strUsage = usage;
	local strUsageEx = "";
	local strDescription = description;

	if type(usage) == "table" then
		strUsage = "[-";
		strUsageEx = "\n\nOptions:";

		local strUsageVal = "";
		local strTmpDesc;
		local strTmpOpt;
		for opt, desc in pairs(usage) do
			if type(desc) == "table" then
				if desc.value then
					strTmpOpt = false;

					strUsageVal = strUsageVal .. (" -%s <%s>"):format(opt, desc.value);
				else
					strTmpOpt = opt;
				end

				strTmpDesc = desc.description;
			else
				strTmpOpt = opt;
				strTmpDesc = desc;
			end

			if strTmpOpt then
				strUsage = strUsage .. strTmpOpt;
			end

			strUsageEx = strUsageEx .. ("\n  -%s  %s"):format(opt, strTmpDesc);
		end

		strUsage = strUsage .. "]" .. strUsageVal;
	end

	if not strUsage then
		strUsage = "";
	end
	if not strDescription then
		strDescription = "";
	end

	if not kcdfw.runLocal then
		System.AddCCommand(
			command,
			expr,
			kcdfw.trimText(
				("%s\n\nUsage: %s %s%s"):format(
					strDescription,
					command,
					strUsage,
					strUsageEx
				)
			)
		);
		kcdfw.logNotice(kcdfw, "Command registered: %q", command);
	else
		kcdfw.logNotice(kcdfw, "Skipped registering command: %q", command);
		kcdfw.logDebug(kcdfw, strDescription);
		kcdfw.logDebug(kcdfw, ("Usage: %s %s%s"):format(command, strUsage, strUsageEx));
	end
end


kcdfw.eventMap.postLoadingScreen = { };
kcdfw.registerPostLoadingScreen = function (id, callback)
	if type(id) ~= "string" or type(callback) ~= "function" then
		kcdfw.logError(kcdfw, "Type error.");
		return false
	end

	kcdfw.eventMap.postLoadingScreen[id] = callback;
end
