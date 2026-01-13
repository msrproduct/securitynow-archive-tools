## Source of truth and remotes

Sync-Repos.ps1 assumes:

- D:\Desktop\SecurityNow-Full-Private is the **source-of-truth** repo.
- D:\Desktop\SecurityNow-Full is the **public mirror** for tools and docs only.

The script **only** syncs from local private → local public:

- It never copies media (PDFs, MP3s, AI transcripts) into the public repo.
- It never modifies .gitignore in either repo.
- It does not pull from GitHub; you are still responsible for git pull / git push in each repo.

Remotes:

- Private local ↔ msrproduct/securitynow-full-archive (GitHub private).
- Public local ↔ msrproduct/securitynow-archive-tools (GitHub public).

Recommended pattern:

1. Make changes in the private repo.
2. Commit and push to the private GitHub repo.
3. Run .\scripts\Sync-Repos.ps1 from the private repo to propagate safe changes to the public local repo and then to the public GitHub repo.
