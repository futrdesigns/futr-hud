Config = {}

-- Speed unit (false = KM/H, true = MPH)
Config.UseMPH = false

-- Framework auto-detection ('qbcore', 'qbox', 'esx', or 'auto')
-- 'auto' will automatically detect which framework is running
Config.Framework = 'auto'

-- Show logo at top center, logo goes into html/assetss/img if the folder isnt there create it and add your logo in there make sure to name your logo, logo.png
Config.ShowLogo = false

-- Clock Settings
Config.ShowClock = true -- Show/hide the clock
Config.ClockFormat = '24' -- '12' for 12-hour format or '24' for 24-hour format
Config.TimeZone = 'UTC' -- Time zone: 'GMT', 'UTC', 'EST', 'PST', 'CST', 'MST', etc.
Config.ShowSeconds = false -- Show seconds in the clock

-- Minimap Settings
Config.AlwaysShowMinimap = false -- If true, minimap always shows. If false, only shows in vehicle

-- Money Display Settings
Config.HideCashWhenZero = true -- Hide cash display when balance is $0
Config.HideBankWhenZero = true -- Hide bank display when balance is $0
