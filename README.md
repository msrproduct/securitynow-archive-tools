# Security Now! Tools & Index

This repository contains tooling and index data to help researchers and fans work with Steve Gibson's **Security** Now! podcast episodes.[file:1]

## What this repo contains

- PowerShell scripts to:
  - Discover official show-notes PDFs (\sn-XXXX-notes.pdf\) on Gibson Research Corporation (GRC).[file:1]
  - Detect episodes with no official notes and (optionally) generate clearly marked AI-derived notes locally.
  - Organize local notes PDFs by year.
  - Maintain a CSV index of all episodes and their associated notes files.

- A CSV index under \data\ (for example \SecurityNowNotesIndex.csv\) with:
  - Episode number
  - Title (when available)
  - Original show-notes URL on GRC and TWiT.tv
  - Local file name (on **your** system)
  - Flags indicating whether AI-derived notes exist locally.[file:1]

## What this repo does NOT contain

This public repository does **not** contain:

- Original Security Now! show-notes PDFs from GRC (\sn-XXXX-notes.pdf\).[file:1]
- TWiT.tv transcripts or audio files (MP3s).
- Any copyrighted content from GRC or TWiT.tv.

Instead, it provides tools and an index so that you can obtain that material yourself from the official sources and keep it in a separate private archive.[file:1]

## Respecting Steve Gibson and TWiT

All Security Now! content is authored and owned by Steve Gibson / Gibson Research Corporation and published in cooperation with TWiT.tv.[file:1]
This project exists to assist with personal research and archival and to avoid making others re-implement the same tooling.

Any AI-derived notes workflow is intended only to fill gaps for episodes which never had official show notes, and generated files must always be clearly labeled as automatically generated and **not** official show notes.[file:1]

## High-level workflow

1. Clone this repo locally.
2. Place the end-to-end PowerShell script into \scripts\SecurityNow-EndToEnd.ps1\.
3. Run the script to:
   - Build or update your local notes archive under a separate \local\ folder (kept out of this public repo).
   - Update the CSV index under \data\.
4. Maintain a **private** clone of this repo (or a separate private repo) that stores:
   - PDFs (official and AI-derived).
   - MP3s.
   - AI-generated transcripts under \local\.[file:1]
