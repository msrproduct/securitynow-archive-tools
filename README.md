Security Now! Tools & Episode Index

This project helps you build your own local Security Now! archive using Steve Gibson’s official show notes on GRC and the Security Now episodes from TWiT.tv, without redistributing any copyrighted content.
​

It is designed for:

    Fans and researchers who want a complete, organized archive of Security Now episodes on their own machine.

    Users who may have no development tools installed and need a guided, step‑by‑step setup.


What This Project Does

The scripts and data in this repository help you:

    Scan the official archives

        GRC archive pages: https://www.grc.com/securitynow.htm and https://www.grc.com/sn/past-YYYY.htm.

​

​

TWiT episode pages: https://twit.tv/shows/security-now/episodes/{number}.
​

    ​

Download official show‑notes PDFs to your machine

    Files like SN-1050-Notes.pdf are fetched directly from GRC into a local folder tree on your system.

​

    ​

Organize notes by year

    Episodes are filed into PDF\YYYY folders (2005–2026) using a built‑in episode‑to‑year mapping.

    ​

Maintain a structured CSV index

    data/SecurityNowNotesIndex.csv tracks, per episode:

    ​

        Episode number and title (when available)

        Official GRC/TWiT show‑notes URL

        Local filename on your machine

        Flags indicating whether AI‑derived notes exist

Optionally generate AI‑derived notes for missing PDFs

    For episodes with no official GRC PDF, the workflow can:

        ​

            Download the official MP3.

            Use a Whisper speech‑to‑text tool to create a transcript.

            Wrap that transcript into a PDF with a bold disclaimer that it is not an official Steve Gibson document.

All AI‑generated content is for personal research and is always clearly labeled as unofficial.

​
What This Project Does Not Do

To respect Steve Gibson, Gibson Research Corporation, and TWiT:

    This public repository does not contain:

​

    Original GRC show‑notes PDFs (SN-XXXX-Notes.pdf).

    TWiT transcripts or MP3 audio files.

    Any other copyrighted GRC/TWiT content.

Instead, it contains only:

    ​

        PowerShell scripts and helper code.

        A CSV index with episode metadata and official URLs.

        Documentation describing how to build your own private archive at home.

The idea is: all original content comes from GRC and TWiT, this repo just automates the work Steve and Leo would fully approve of you doing for yourself.
​

​
Legal & Attribution

    Security Now! is written and hosted by Steve Gibson (Gibson Research Corporation) and co‑hosted by Leo Laporte on the TWiT network.

​

All official show notes, transcripts, and audio remain the property of GRC and TWiT.

    ​

This project:

    Exists solely to assist with personal research and archival.

    Requires you to fetch original show notes and audio from GRC and TWiT.tv yourself.

​

Requires that any AI‑derived notes you generate are clearly marked as automatically generated and not official show notes.

    ​

If you share anything publicly, share only your own code, your CSV index, and instructions that point other fans back to GRC and TWiT.
Repository Layout (Public Tools Repo)

This repo is intentionally small and media‑free so it is safe to share:

text
securitynow-archive-tools/
├── data/
│   └── SecurityNowNotesIndex.csv   # Episode index (numbers, titles, URLs, local filenames)
├── scripts/
│   └── SecurityNow-EndToEnd.ps1    # Main end-to-end automation script
├── docs/
│   ├── README.md                   # This file
│   └── WORKFLOW.md                 # Detailed workflow & advanced usage (optional)
└── .gitignore                      # Ensures media never enters this public repo

On your machine, you will typically also have a private clone that adds a local folder for media, for example:

​

text
C:\SecurityNow-Full-Private\
├── data\
│   └── SecurityNowNotesIndex.csv
├── scripts\
│   └── SecurityNow-EndToEnd.ps1
├── docs\
├── local\                          # PRIVATE MEDIA (not pushed to public GitHub)
│   ├── PDF\
│   │   ├── 2005\
│   │   ├── 2024\
│   │   └── SN-XXXX-Notes*.pdf / SN-XXXX-Notes-AI.pdf
│   ├── mp3\
│   │   └── sn-XXXX.mp3
│   └── Notes\
│       └── ai-transcripts\
│           └── sn-XXXX-notes-ai.txt
└── .gitignore

The local folder is where all PDFs, MP3s, and AI transcripts live, and it must never be committed to this public repo.

​
Prerequisites (Assume the User Has Nothing)

This section assumes the user starts from a clean Windows system and has never used Git or PowerShell before.
1. GitHub account (optional but recommended)

    Visit https://github.com/ and create a free account if you want to keep your own fork or contribute fixes.

​

If you don’t want to use Git at all, you can download a ZIP of this repo and skip cloning.

    ​

2. PowerShell

    Windows 10/11 already comes with PowerShell.

    For best experience, install PowerShell 7 from Microsoft’s official download page (search “Install PowerShell 7”).

    ​

    You will run all commands in a PowerShell window (not Command Prompt).

3. A folder for your archive

The scripts are designed to work on any drive or path. You do not have to use D:.

​

A common setup is:

text
C:\SecurityNow-Full          # Public tools/index clone (this repo)
C:\SecurityNow-Full-Private  # Private working copy with media

You can change these to any path you prefer (for example, E:\SNArchive); you will configure the root once and the script will create data, scripts, and local under that root.

​
4. Optional: Whisper for AI transcripts

What Whisper is

    Whisper is an open‑source speech‑to‑text system that can listen to audio (like Security Now MP3s) and produce a text transcript.

    This project assumes a command‑line version (“Whisper CLI”), such as whisper.cpp or similar, that you run from PowerShell.

    ​

Why you might want Whisper

    Some Security Now episodes never had official GRC show‑notes PDFs.

    For those, Whisper can:

        Listen to the official MP3.

        Produce a transcript (sn-XXXX-notes-ai.txt).

        Let the pipeline wrap that text into an AI‑generated PDF (sn-XXXX-notes-ai.pdf) with a strong disclaimer.

        ​

Basic install pattern (example)

    Download a Whisper CLI build (e.g., whisper.cpp compiled for Windows).

    Put it and its model file in a folder, such as:

text
C:\whisper-cli\whisper-cli.exe
C:\whisper-cli\ggml-base.en.bin

In scripts\SecurityNow-EndToEnd.ps1, you will set:

    WhisperExe – full path to the CLI (e.g., C:\whisper-cli\whisper-cli.exe).

    WhisperModel – full path to the model (e.g., C:\whisper-cli\ggml-base.en.bin).

    ​

If you skip Whisper configuration:

    The script can still:

        Download official PDFs.

        Build the CSV index.

        Organize PDFs by year.

    You simply will not get AI‑generated PDFs for episodes that lack official notes.

    ​

Getting Started (Step‑by‑Step, Novice‑Friendly)
Step 1 – Get this repo onto your machine

You can use Git or download the ZIP.
Option A: Clone with Git (recommended if you know Git)

powershell
# 1. Choose a folder for the public tools
New-Item -ItemType Directory -Path "C:\SecurityNow-Full" -Force | Out-Null
Set-Location "C:\SecurityNow-Full"

# 2. Clone the public tools repo into this folder
git clone https://github.com/msrproduct/securitynow-archive-tools.git .

Option B: Download ZIP (no Git required)

    Go to https://github.com/msrproduct/securitynow-archive-tools.

    Click the green Code button → Download ZIP.

    Extract the ZIP into C:\SecurityNow-Full (or any folder you like).

    ​

Step 2 – Create your private working copy

The private working copy is where you will actually download PDFs and MP3s and run Whisper.

powershell
# Create a private root folder
New-Item -ItemType Directory -Path "C:\SecurityNow-Full-Private" -Force | Out-Null
Set-Location "C:\SecurityNow-Full-Private"

# Copy or clone the tools into the private folder
git clone https://github.com/msrproduct/securitynow-archive-tools.git .

Now create the local media folders:

powershell
New-Item -ItemType Directory -Path .\local\PDF -Force                 | Out-Null
New-Item -ItemType Directory -Path .\local\mp3 -Force                 | Out-Null
New-Item -ItemType Directory -Path .\local\Notes\ai-transcripts -Force | Out-Null

Everything downloaded or generated (PDFs, MP3s, transcripts) will go under local\ and stay on your machine.

​
Step 3 – Configure paths and options in the script

Open scripts\SecurityNow-EndToEnd.ps1 in an editor (Notepad, Notepad++, VS Code).

Look for a configuration section near the top; you will typically set:

    Repo root

        Often defined relative to the script location (for example, using PSScriptRoot), so you should not need to hard‑code C: or D:.

    ​

Local media root

    Defaults to something like .\local, which is inside your repo root.

    This is where PDFs, MP3s, and AI transcripts are stored.

Whisper settings (if using AI notes)

    Set WhisperExe to C:\whisper-cli\whisper-cli.exe (or wherever your CLI lives).

    Set WhisperModel to C:\whisper-cli\ggml-base.en.bin (or your chosen model).

        ​

If you want the whole archive somewhere else (like E:\SecurityNowArchive), change the base path once, and let the script create its own data, scripts, and local folders there.

​
Step 4 – First full run (private repo)

From your private working copy:

powershell
Set-Location "C:\SecurityNow-Full-Private"

# Run the end-to-end script
.\scripts\SecurityNow-EndToEnd.ps1

On the first run, the script will:

​

    Scan GRC’s Security Now archive pages for all years.

​

​

Download any official show‑notes PDFs it finds into local\PDF\YYYY.

Build or update data\SecurityNowNotesIndex.csv.

If Whisper is configured and an episode has no official PDF, it will:

    Download the official MP3 (if needed).

    Create sn-####-notes-ai.txt under local\Notes\ai-transcripts.

    Create sn-####-notes-ai.pdf under local\PDF\YYYY with a prominent AI disclaimer.

        ​

If something fails:

    Already‑downloaded files remain on disk.

    You can fix configuration or networking issues and re‑run without losing progress.

Keeping Public and Private in Sync

Typical usage pattern:

    Do all heavy work in the private repo (C:\SecurityNow-Full-Private):

        Running the script.

        Downloading PDFs/MP3s.

        Generating AI notes.

        ​

    Copy safe changes back to the public repo (C:\SecurityNow-Full):

        data\SecurityNowNotesIndex.csv

        Updated scripts under scripts\

Example:

powershell
# From PowerShell
Copy-Item "C:\SecurityNow-Full-Private\data\SecurityNowNotesIndex.csv" `
          "C:\SecurityNow-Full\data\SecurityNowNotesIndex.csv" -Force

Copy-Item "C:\SecurityNow-Full-Private\scripts\SecurityNow-EndToEnd.ps1" `
          "C:\SecurityNow-Full\scripts\SecurityNow-EndToEnd.ps1" -Force

Then, from the public repo:

powershell
Set-Location "C:\SecurityNow-Full"
git add data\SecurityNowNotesIndex.csv scripts\SecurityNow-EndToEnd.ps1
git commit -m "Update Security Now index and pipeline"
git push

Your private archive keeps media; the public repo only shares scripts and index data.
