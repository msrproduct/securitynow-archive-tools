# Contributing to Security Now! Archive Tools

Thank you for your interest in improving this project! This document provides guidelines for contributing.

## 🎯 Project Goals

This project aims to:
1. **Respect copyright** - Never redistribute Steve Gibson's or TWiT.tv's content
2. **Automate archival** - Make it easy for fans to build personal archives from official sources
3. **Fill gaps** - Generate AI transcripts ONLY for episodes without official notes
4. **Stay simple** - Keep the tooling accessible to non-developers

## 🤝 Ways to Contribute

### 1. Report Bugs

Found a problem? [Open an issue](https://github.com/msrproduct/securitynow-archive-tools/issues/new) with:
- **Clear title**: "Episode 432 PDF download fails"
- **Environment**: PowerShell version, OS, Whisper version
- **Steps to reproduce**: Exact commands you ran
- **Expected vs. actual behavior**
- **Error messages**: Copy/paste full output

### 2. Suggest Enhancements

Have an idea? [Open an issue](https://github.com/msrproduct/securitynow-archive-tools/issues/new) with:
- **Use case**: Why is this needed?
- **Proposed solution**: How would it work?
- **Alternatives considered**: Other approaches you thought about

### 3. Improve Documentation

Documentation improvements are always welcome:
- Fix typos or unclear instructions
- Add troubleshooting tips for errors you encountered
- Create video tutorials or screenshots
- Translate documentation to other languages

### 4. Submit Code Improvements

Before writing code, please:
1. Check [existing issues](https://github.com/msrproduct/securitynow-archive-tools/issues) to avoid duplicates
2. Open an issue to discuss your approach first
3. Follow the code guidelines below

## 📋 Code Guidelines

### PowerShell Style

- **Use clear variable names**: `$episodeNumber` not `$en`
- **Add comments**: Explain *why*, not *what*
- **Error handling**: Use `try/catch` blocks for network operations
- **Avoid hard-coded paths**: Use `$HOME` or script parameters
- **Test on Windows**: Primary platform for this project

**Example:**
```powershell
# Good
$episodeNumber = 432
$grcUrl = "https://www.grc.com/sn/sn-$episodeNumber-notes.pdf"

try {
    Invoke-WebRequest -Uri $grcUrl -OutFile $localPath -ErrorAction Stop
} catch {
    Write-Warning "Failed to download episode $episodeNumber: $_"
}

# Avoid
$e = 432
$u = "https://www.grc.com/sn/sn-" + $e + "-notes.pdf"
Invoke-WebRequest -Uri $u -OutFile "C:\archive\file.pdf"
```

### Testing

Before submitting a pull request:

1. **Test the full workflow** on a clean system
2. **Test edge cases**: Missing episodes, network failures, bad paths
3. **Check output**: Verify PDFs, CSV index, folder structure
4. **Document changes**: Update README.md or WORKFLOW.md if needed

### Commit Messages

- **Use imperative mood**: "Add episode range filter" not "Added" or "Adds"
- **Be specific**: "Fix episode 1 MP3 download URL" not "Fix bug"
- **Reference issues**: "Closes #42: Add dry-run mode"

**Examples:**
```
✅ Add support for custom Whisper models
✅ Fix year mapping for episodes 1009-1060 (2025)
✅ Improve error handling for 403/404 responses

❌ Update script
❌ Fixed stuff
❌ WIP
```

## 🔄 Pull Request Process

### 1. Fork and Clone

```powershell
# Fork the repo on GitHub, then:
git clone https://github.com/YOUR_USERNAME/securitynow-archive-tools.git
cd securitynow-archive-tools
```

### 2. Create a Branch

```powershell
git checkout -b feature/add-episode-range-filter
# or
git checkout -b fix/episode-432-download
```

**Branch naming:**
- `feature/` - New functionality
- `fix/` - Bug fixes
- `docs/` - Documentation changes
- `test/` - Test improvements

### 3. Make Changes

- Edit files in your branch
- Test thoroughly
- Commit incrementally with clear messages

### 4. Push and Open PR

```powershell
git push origin feature/add-episode-range-filter
```

Then on GitHub:
1. Open a Pull Request to the `main` branch
2. Fill out the PR template (title, description, testing notes)
3. Link related issues with "Closes #42" in the description

### 5. Code Review

- Expect feedback and questions
- Be responsive to review comments
- Make requested changes in new commits (don't force-push during review)
- Squash commits before merge if requested

## 🚫 What NOT to Contribute

### Never Submit:

❌ **Copyrighted content**:
- GRC show notes PDFs
- TWiT audio files (MP3s)
- Full transcripts from Steve Gibson
- Episode audio/video

❌ **Scrapers that bypass GRC/TWiT**:
- Direct CDN access tools
- Anything that circumvents official sources
- Bulk downloaders that hammer servers

❌ **Commercial integration**:
- Paid API wrappers
- Monetization features
- Advertising or tracking

### Acceptable Contributions:

✅ **Automation improvements**:
- Better error handling
- Performance optimizations
- Cross-platform support (macOS, Linux)

✅ **AI transcript enhancements**:
- Better Whisper model selection
- Improved HTML/PDF formatting
- Disclaimer customization

✅ **Documentation**:
- Setup guides
- Troubleshooting tips
- Example workflows

✅ **Testing**:
- Unit tests
- Integration tests
- CI/CD pipelines

## 🛡️ Copyright and Legal

### Your Contributions

By submitting a pull request, you agree that:
- Your code is original or properly attributed
- You grant this project a license to use your code under the MIT License
- You have the right to grant this license

### Security Now! Content

All Security Now! podcast content is © Steve Gibson / GRC and TWiT.tv.

Contributions must:
- Link to official sources (GRC, TWiT.tv)
- Never redistribute copyrighted media
- Clearly mark AI-generated content as such
- Include disclaimers on AI transcripts

## 📞 Getting Help

**Questions about contributing?**

1. Check [existing issues](https://github.com/msrproduct/securitynow-archive-tools/issues)
2. Read the [WORKFLOW.md](docs/WORKFLOW.md) documentation
3. Open a [discussion](https://github.com/msrproduct/securitynow-archive-tools/discussions) (not an issue)

**Security vulnerabilities?**

Please email privately rather than opening a public issue.

## 🙏 Recognition

Contributors will be:
- Listed in release notes
- Credited in a future CONTRIBUTORS.md file
- Thanked in commit messages

Thank you for helping make this project better for the Security Now! community! 🔐📻
