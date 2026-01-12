# Write-Readme-Public.ps1
# Location: D:\Desktop\SecurityNow-Full  (or the root of your public repo)

$readmeContent = @'
# Security Now! Tools & Episode Index

This project helps you build your own **local Security Now! archive** using Steve Gibson’s official show notes and TWiT’s audio, without redistributing any copyrighted content.

It provides:

- PowerShell scripts to discover and download **official show‑notes PDFs** from GRC.
- A **CSV index** of all episodes, URLs, and filenames.
- Optional **AI‑derived notes** for episodes that never had official PDFs, clearly marked as non‑official.

---

## What This Project Does

The tools in this repo let you:

- **Scan official archives**
  - GRC show notes: `https://www.grc.com/securitynow.htm` and `https://www.grc.com/sn/past-YYYY.htm`.
  - TWiT episode pages: `https://twit.tv/shows/security-now/episodes/{number}`.

- **Download official PDFs to your machine**
  - Files like `sn-1000-notes.pdf` are fetched directly from GRC into a local folder tree on your system.

- **Organize notes by year**
  - Episodes are placed into `PDF\YYYY` folders (2005–2026) using a built‑in episode‑to‑year mapping.

- **Maintain a structured index**
  - `data/SecurityNowNotesIndex.csv` tracks, per episode:
    - Episode number and (when available) title
    - Official GRC/TWiT show‑notes URL
    - Local filename on your machine
    - Flags for AI‑derived notes

- **Optionally generate AI‑derived notes**
  - For episodes with **no official PDF**, you can use a Whisper‑based speech‑to‑text tool on the official MP3 and create:
    - `sn-####-notes-ai.txt` (transcript)
    - `sn-####-notes-ai.pdf` (PDF with a bold AI disclaimer)

---

## What This Project Does *Not* Do

To respect Steve Gibson, GRC, and TWiT:

- This public repo **does not contain**:
  - Original Security Now! show‑notes PDFs (`sn-XXXX-notes.pdf`) from GRC
  - TWiT transcripts or MP3 audio files
  - Any other copyrighted GRC/TWiT content

- Instead, it contains **only**:
  - PowerShell scripts and helper code
  - A CSV index with metadata and official URLs
  - Documentation describing how to build your own **private** archive at home

You get automation and structure, while all original media comes directly from the official sources.

---

## Legal & Attribution

All Security Now! content is authored and owned by **Steve Gibson** / Gibson Research Corporation and is published in cooperation with **TWiT.tv**.

This project:

- Exists solely to assist with **personal research and archival**.
- Requires that you fetch all original show notes and audio from **GRC** and **TWiT.tv** yourself.
- Requires that any AI‑derived notes are **prominently labeled** as automatically generated and **not official show notes**.

---

## Repository Layout

This public repo is intentionally media‑free and simple:

```text
securitynow-archive-tools/
├── data/
│   └── SecurityNowNotesIndex.csv   # Episode index (URLs + filenames, no media)
├── scripts/
│   └── SecurityNow-EndToEnd.ps1    # Main end-to-end pipeline
├── docs/
│   ├── README.md                   # This file
│   └── WORKFLOW.md                 # Detailed workflow & advanced usage (optional)
└── .gitignore                      # Ensures media never enters this public repo

On your machine, you will typically have a private working copy that adds a local folder for all media:

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
│   │   └── sn-XXXX-notes*.pdf
│   ├── mp3\
│   └── Notes\
│       └── ai-transcripts\
└── .gitignore

The local folder is where all PDFs, MP3s, and AI transcripts live and it must never be committed to this public repo.
Prerequisites (Beginner‑Friendly)

You can start with almost nothing installed. This section explains each requirement and why it is needed.
1. GitHub account (optional but recommended)

    A free GitHub account at https://github.com/ lets you clone this project and optionally contribute improvements.

    If you prefer, you can also download the project as a ZIP from GitHub and skip Git entirely.

2. PowerShell

    Windows 10/11 already includes a version of PowerShell.

    For best compatibility, install PowerShell 7 from Microsoft’s official site.

You will run all commands below in a PowerShell window.
3. A folder for your archive

You can place your archive on any drive. For example:

text
C:\SecurityNow-Full          # Public tools/index clone
C:\SecurityNow-Full-Private  # Private working copy with media

The scripts are designed to be path‑flexible:

    You do not need to use D:; that was just one developer’s environment.

    You configure the root path once, and the scripts create data, scripts, and local under that root.

4. Optional: Whisper for AI transcripts

If you want AI‑derived notes for episodes without official PDFs, you will need a Whisper CLI tool (for example, whisper.cpp or similar).

The Whisper tool’s job is:

    Take a Security Now MP3 file as input.

    Output a text transcript of that episode.

A typical Whisper setup looks like:

text
C:\whisper-cli\whisper-cli.exe
C:\whisper-cli\ggml-base.en.bin

In scripts\SecurityNow-EndToEnd.ps1, you configure two settings:

    WhisperExe – full path to the Whisper CLI executable (for example C:\whisper-cli\whisper-cli.exe).

    WhisperModel – full path to the model file (for example C:\whisper-cli\ggml-base.en.bin).

If you do not configure Whisper:

    The script can still:

        Download official PDFs

        Build the CSV index

        Organize PDFs by year

    You simply will not get AI‑generated PDFs for episodes that lack official notes.

Getting Started (Step‑by‑Step)

These steps assume no prior setup beyond Windows and a web browser.
Step 1 – Get the tools repo

You can use Git or download the ZIP.
Option A – Clone with Git

Open PowerShell and run:

powershell
# 1. Create a folder for the public tools
New-Item -ItemType Directory -Path "C:\SecurityNow-Full" -Force | Out-Null
Set-Location "C:\SecurityNow-Full"

# 2. Clone the public tools repo into this folder
git clone https://github.com/msrproduct/securitynow-archive-tools.git .

Option B – Download as ZIP

    Visit: https://github.com/msrproduct/securitynow-archive-tools

    Click “Code” → “Download ZIP”.

    Extract the ZIP into C:\SecurityNow-Full.

Step 2 – Create your private working copy

Your private copy is where you will store PDFs, MP3s, and AI transcripts.

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
Step 3 – Configure paths and options

Open scripts\SecurityNow-EndToEnd.ps1 in your editor (Notepad, VS Code, etc.) and locate the configuration section near the top.

Check or set:

    Repo root

        The script usually sets this relative to its own location (for example, using PSScriptRoot), so you should not need to hard‑code C: or D:.

    Local media root

        Defaults to .\local, relative to the repo root.

        This is where PDFs, MP3s, and AI transcripts will be stored.

    Whisper settings (optional)

        Set WhisperExe to your Whisper CLI path (for example C:\whisper-cli\whisper-cli.exe).

        Set WhisperModel to your model path (for example C:\whisper-cli\ggml-base.en.bin).

If you prefer a different layout:

    Change the root path once (for example, E:\SNArchive).

    Let the script create the necessary data, scripts, and local folders under that root.

Step 4 – First full run

From your private working copy:

powershell
Set-Location "C:\SecurityNow-Full-Private"

# Run the end-to-end script
.\scripts\SecurityNow-EndToEnd.ps1

On the first run, the script will:

    Scan the GRC Security Now archive pages for all years.

    Download any official show‑notes PDFs it finds into local\PDF\YYYY.

    Build or update data\SecurityNowNotesIndex.csv.

    If Whisper is configured, for episodes with no official PDF, it will:

        Download the official MP3 (if needed).

        Create sn-####-notes-ai.txt under local\Notes\ai-transcripts.

        Create sn-####-notes-ai.pdf under local\PDF\YYYY with a prominent AI disclaimer.

If something fails along the way:

    Already‑downloaded files remain on disk.

    You can adjust settings and re‑run the script safely.

