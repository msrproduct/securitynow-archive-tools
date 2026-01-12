# Security Now Archive Tools

This repo contains PowerShell tools and a CSV index to help you build your own local archive of Steve Gibson’s Security Now show notes.[web:52][file:2]

- No PDFs or MP3s are stored here.
- All content comes directly from GRC.com and TWiT when you run the script.[web:52][web:76]

## How to use

1. Open PowerShell.
2. Go to the repo folder:

   `cd "D:\Desktop\SecurityNow-Full"`

3. Run the main script:

   `.\scripts\SecurityNow-EndToEnd.ps1`

This will create a **local** folder structure (PDF, mp3, AI notes) and update `SecurityNow_NotesIndex.csv` on your machine.[file:2][file:78]

## What this repo is

- A script: `scripts\SecurityNow-EndToEnd.ps1`.[file:2]
- A CSV index: `SecurityNow_NotesIndex.csv` with episode number, URL, and local file name.[file:78]

## What this repo is not

- It does **not** contain original show-note PDFs from GRC (`sn-XXXX-notes.pdf`).[web:52]
- It does **not** contain TWiT audio or transcripts.[web:76]
