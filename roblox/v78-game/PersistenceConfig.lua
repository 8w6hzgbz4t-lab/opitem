-- Live storage is required. Failed/locked/corrupt loads never get a writable fallback profile.
return {
 Enabled=true,
 ProfileStoreName='StealAnOPItemProfiles_v1',
 JournalStoreName='StealAnOPItemTransfers_v1',
 StudioProfileStoreName='StealAnOPItem_TESTProfiles_v1',
 StudioJournalStoreName='StealAnOPItem_TESTTransfers_v1',
 LockSeconds=120,
 AutosaveSeconds=30,
 JournalSeconds=60,
 Retries=3,
 RetryDelay=.35,
 MaxRetryDelay=2,
 MaxProfilesPerTransaction=8,
}
