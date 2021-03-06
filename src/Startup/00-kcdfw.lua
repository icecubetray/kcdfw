KCDFW_LEVEL_DEBUG 		= 45;

KCDFW_LEVEL_VERBOSE		= 40;
KCDFW_LEVEL_INFO		= 35;
KCDFW_LEVEL_NOTICE		= 30;

KCDFW_LEVEL_WARNING		= 25;
KCDFW_LEVEL_ERROR		= 20;

KCDFW_LEVEL_BOOTSTRAP	= 10;
KCDFW_LEVEL_ALWAYS		= 0;

--                        0x0FFF = range for true log level (more than ever ever ever needed but who cares)
KCDFW_FLAG_EXTRA_FRAME	= 0x1000;
KCDFW_FLAG_NO_PREFIX	= 0x2000;




kcdfw = {
	distribution = false, -- [intermeta-TODO:ask]
	runLocal = true, -- [intermeta:false]

	package = {
		name = "&{META_NAME}",
		author = "&{META_AUTHOR}",
		date = "&{META_BUILD_DATE}",
		version = "&{META_VERSION}"
	},

	usersMap = { },

	eventMap = { },


	-- Lua 5.1 (used in KCD) does not support native bitwise operations, until KCD makes use of 5.2+ these
	-- functions will have to drop in for that deficiency.

	bitwiseAnd = function (x, y)
		-- Taken from https://stackoverflow.com/questions/32387117/

		local result = 0
		local bitval = 1

		while x > 0 and y > 0 do
		if x % 2 == 1 and y % 2 == 1 then -- test the rightmost bits
			result = result + bitval      -- set the current bit
		end

		bitval = bitval * 2 -- shift left
		x = math.floor(x / 2) -- shift right
		y = math.floor(y / 2)
		end

		return result
	end,

	bitwiseOr = function (x, y)
		-- Absolutely not ideal, but this works so long as no bits overlap (should be the case in this codebase).
		return (x + y);
	end,


	log = function (level, context, fmt, ...)
		local str = (("%s %s %s"):format("[%s]", "(%s)", fmt)):format(context.package.name, kcdfw.bitwiseAnd(level, 0x0FFF), ...);

		if not kcdfw.runLocal then
			System.LogAlways(str);
		else
			print(str);
		end
	end,
	logLevel = KCDFW_LEVEL_INFO
};




if kcdfw.runLocal and not kcdfw.distribution then
	kcdfw.logLevel = KCDFW_LEVEL_DEBUG;
end


kcdfw.logDebug = function (context, fmt, ...)
	kcdfw.log(
		kcdfw.bitwiseOr(KCDFW_LEVEL_DEBUG, KCDFW_FLAG_EXTRA_FRAME),
		context,
		fmt,
		...
	);
end

kcdfw.logVerbose = function (context, fmt, ...)
	kcdfw.log(
		kcdfw.bitwiseOr(KCDFW_LEVEL_VERBOSE, KCDFW_FLAG_EXTRA_FRAME),
		context,
		fmt,
		...
	);
end

kcdfw.logInfo = function (context, fmt, ...)
	kcdfw.log(
		kcdfw.bitwiseOr(KCDFW_LEVEL_INFO, KCDFW_FLAG_EXTRA_FRAME),
		context,
		fmt,
		...
	);
end

kcdfw.logNotice = function (context, fmt, ...)
	kcdfw.log(
		kcdfw.bitwiseOr(KCDFW_LEVEL_NOTICE, KCDFW_FLAG_EXTRA_FRAME),
		context,
		fmt,
		...
	);
end

kcdfw.logWarning = function (context, fmt, ...)
	kcdfw.log(
		kcdfw.bitwiseOr(KCDFW_LEVEL_WARNING, KCDFW_FLAG_EXTRA_FRAME),
		context,
		fmt,
		...
	);
end

kcdfw.logError = function (context, fmt, ...)
	kcdfw.log(
		kcdfw.bitwiseOr(KCDFW_LEVEL_ERROR, KCDFW_FLAG_EXTRA_FRAME),
		context,
		fmt,
		...
	);
end

kcdfw.logBootstrap = function (context, fmt, ...)
	kcdfw.log(
		kcdfw.bitwiseOr(KCDFW_LEVEL_BOOTSTRAP, KCDFW_FLAG_EXTRA_FRAME),
		context,
		fmt,
		...
	);
end

kcdfw.logAlways = function (context, fmt, ...)
	kcdfw.log(
		kcdfw.bitwiseOr(KCDFW_LEVEL_ALWAYS, KCDFW_FLAG_EXTRA_FRAME),
		context,
		fmt,
		...
	);
end




kcdfw.getScriptRoot = function()
	local pwdPath = debug.getinfo(2, "S").source:sub(2);
	pwdPath = pwdPath:sub(
		1,
		pwdPath:find("/[^/]*$") - 1
	);
	pwdPath = pwdPath:sub(
		1,
		pwdPath:find("/[^/]*$") - 1
	);

	local rootPath;
	if not kcdfw.runLocal then
		rootPath = "Scripts";
	else
		rootPath = pwdPath;
	end

	return rootPath
end

local function buildPaths()
	local rootPath = kcdfw.getScriptRoot();

	return {
		root = rootPath,
		cmds = ("%s/%s"):format(rootPath, "Commands"),
		core = ("%s/%s"):format(rootPath, "Core"),
		util = ("%s/%s"):format(rootPath, "Utilities")
	};
end

kcdfw.paths = buildPaths();




KCDFW_MODULE_PATH = nil;

kcdfw.bootstrap = function (context, base, ...)
	for i, module in ipairs({...}) do
		KCDFW_MODULE_PATH = ("%s/%s.lua"):format(base, module);

		kcdfw.logVerbose(context, "Module load: %q", KCDFW_MODULE_PATH);
		if not kcdfw.runLocal then
			Script.ReloadScript(KCDFW_MODULE_PATH);
		else
			dofile(KCDFW_MODULE_PATH);
		end
		kcdfw.logBootstrap(context, "Module init: %q", KCDFW_MODULE_PATH);
	end

	KCDFW_MODULE_PATH = nil;

	if context and context.package.name and not kcdfw.usersMap[context.package.name] then
		kcdfw.usersMap[context.package.name] = context;
	end
end

kcdfw.logBootstrap(kcdfw, "Bootstrapping started.");
kcdfw.bootstrap(kcdfw, kcdfw.paths.core, "Override", "Console", "Registration", "EventListeners");
kcdfw.bootstrap(kcdfw, kcdfw.paths.util, "Tables", "Text", "Sanity", "Introspection", "Quests");
kcdfw.bootstrap(kcdfw, kcdfw.paths.cmds, "Diagnostics");
kcdfw.logBootstrap(kcdfw, "Bootstrapping finished.");




kcdfw.log(
	((kcdfw.runLocal and KCDFW_LEVEL_BOOTSTRAP) or KCDFW_LEVEL_INFO),
	kcdfw,
	"KCDFW initialized, run %q to dump state.",
	((kcdfw.runLocal and "kcdfw.dumpToConsole([cmdline])") or "kcdfw_dump")
);
