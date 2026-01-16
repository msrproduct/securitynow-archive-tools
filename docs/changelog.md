# Changelog - sn-full-run.ps1

All notable changes to the Security Now! Archive Builder production script.

## [3.1.1] - 2026-01-13

### Fixed
- Fixed duplicate header display (removed second header in initialization section)
- Fixed potential null reference errors in Download-GrcPdfWithRetry error handling
- Added missing error handling to Save-EpisodeDateIndex and Save-ErrorLog functions
- Fixed HTML CSS styling - added word-wrap: break-word for long URLs in AI transcripts

### Added
- Added SkipAI parameter to params block for skipping AI transcript generation
- Added parameter validation: MinEpisode must be less than or equal to MaxEpisode
- Added HttpTimeoutSec and MaxRetryAttempts configuration variables (moved from hardcoded values)
- Added comprehensive Write-Verbose logging throughout all functions for debugging
- Enhanced parameter help documentation with SkipAI usage examples

### Changed
- Improved error handling patterns for consistency across all functions
- Better separation of concerns in function design
- Applied PowerShell best practices (ValidateRange, proper try-catch blocks)
- Enhanced inline documentation and comments

### Testing
- ✅ Dry-run mode validated on episodes 1-5 with verbose logging
- ✅ SkipAI parameter working correctly (episodes 500-501 tested)
- ✅ Parameter validation catches invalid ranges (MinEpisode > MaxEpisode)
- ✅ Verbose logging provides detailed debugging information

## [3.1.0] - 2026-01-13

### Changed
- Standardized script filename (removed -v3 suffix for consistency)
- Archived previous versions to rchive/historical-dev/
- Created git tags for version tracking

### Fixed
- Verified Whisper paths (C:\tools\whispercpp\)
- Confirmed GRC regex pattern with non-breaking space (character 160)

## [3.0.0] - 2026-01-13

### Added
- Aggressive rewrite with improved error handling
- Episode 7 AI transcript validated after 8-hour debugging session
- Better MP3 URL discovery with 4-digit zero-padded format support (sn0001, sn0099, sn1000)

### Changed
- Switched from browser-based PDF conversion to wkhtmltopdf
- Improved dry-run output formatting

## [2.1.0] - 2026-01-12

### Added
- Integration with pisode-dates.csv for accurate year sorting
- wkhtmltopdf HTML-to-PDF conversion
- Red AI disclaimer banner on generated PDFs

## [2.0.0] - 2026-01-11

### Added
- Initial production release
- GRC PDF download automation from grc.com/sn/
- AI transcription via Whisper for missing episodes
- MP3 discovery from TWiT CDN (cdn.twit.tv/audio/sn/)
- CSV index management (SecurityNowNotesIndex.csv)
- Episode date caching system (pisode-dates.csv)
