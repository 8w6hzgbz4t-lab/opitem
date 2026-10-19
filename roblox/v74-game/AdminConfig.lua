-- SERVER ONLY. Roblox resolves this account to a numeric UserId once at startup.
-- An explicit positive UserId takes priority. Failed lookup grants no access.
return {
 Enabled=true,
 DeveloperUserId=0, -- Optional: set your positive numeric Roblox UserId.
 DeveloperUsername='Goverment_cheesee',
 AutoAuthorizePlaceOwner=false, -- Never needed for the configured developer account.
 CommandBurst=5, CommandsPerSecond=2, ConfirmationSeconds=20,
 MaxLogs=200, FlightSpeed=42, InputInterval=.08,
 MaxCurrency=2000000000, MaxProtectionSeconds=3600,
 MinDeveloperSpeed=16, MaxDeveloperSpeed=64,
 MinDeveloperJump=50, MaxDeveloperJump=120,
}
