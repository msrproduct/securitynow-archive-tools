# Security Now Archive Workflow (placeholder)

This document will describe:

- How to configure local paths.
- How to run the end-to-end script to:
  - Fetch official notes from GRC/TWiT.
  - Generate AI-derived notes for missing episodes.
  - Organize everything by year.
- How to maintain a separate private archive repo containing media files under \local\.

TODO: Fill in after the end-to-end script is finalized and stable.[file:1]
## Source of truth and remotes

The **local private repository** is your primary source of truth:

- Work in D:\Desktop\SecurityNow-Full-Private first for all scripts, docs, and media.
- Commit and push from the local private repo to msrproduct/securitynow-full-archive on GitHub as a backup.
- The local public repo D:\Desktop\SecurityNow-Full and the public GitHub repo msrproduct/securitynow-archive-tools are **read-only mirrors** for tools and docs, not places to edit first.

Git does **not** auto-sync between repos:

- Changes in private do not appear in public until you run Sync-Repos.ps1.
- Changes made directly on GitHub will not appear locally until you run git pull in the matching local repo.

Normal workflow:

1. Edit and test in D:\Desktop\SecurityNow-Full-Private.
2. Run git add, git commit, git push in the private repo.
3. Run .\scripts\Sync-Repos.ps1 to copy non-media changes from private → public and push to the public GitHub repo.
