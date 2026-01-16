@'
# Quick Template Setup
cd C:\Users\Admin\dev-templates\enhanced-context-system

# File 1
".ai-context-TEMPLATE.md" | Out-File -Encoding UTF8 -NoNewline
"# AI Context - [PROJECT NAME]

**Version:** 1.0
**Last Updated:** [DATE]

Replace [PROJECT NAME] and [DATE] with your details" | Out-File ".ai-context-TEMPLATE.md" -Encoding UTF8

# File 2
"# New Thread Checklist - [PROJECT NAME]

- [ ] Read .ai-context.md
- [ ] Check COMMON-MISTAKES.md
- [ ] Review recent commits" | Out-File "NEW-THREAD-CHECKLIST-TEMPLATE.md" -Encoding UTF8

# File 3
"# Common Mistakes Log - [PROJECT NAME]

Document repeated errors here" | Out-File "COMMON-MISTAKES-TEMPLATE.md" -Encoding UTF8

# Commit
git add .
git commit -m "feat: Add basic templates"

Write-Host "Done! Now manually edit the 3 files to add full content" -ForegroundColor Green
Get-ChildItem *.md
'@ | Out-File quick-setup.ps1 -Encoding UTF8

Write-Host "Created quick-setup.ps1 - now run it" -ForegroundColor Green
