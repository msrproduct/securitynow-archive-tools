# Special-Sync.ps1 - Complete Repository Sync Tool

## Overview

`Special-Sync.ps1` is your **single-command solution** to keep all 4 repositories in perfect sync:
- Local Private Repo (D:\Full-Private) → Source of Truth (SOC)
- GitHub Private Repo → Backup with copyrighted material
- Local Public Repo (D:\Full) → Tools-only mirror
- GitHub Public Repo → Community-accessible tools/docs

## Why This Script Exists

You needed ONE script that handles the entire sync workflow automatically, eliminating manual Git commands and ensuring consistency across all four repositories[file:1][file:2].

**The Problem:** Manually syncing 4 repos is error-prone and time-consuming.

**The Solution:** One script, one command, complete sync.

## What It Does (5 Steps)

### Step 1: Sync Local Private → GitHub Private
- Pulls latest changes from GitHub private repo
- Commits any local changes in D:\Full-Private
- Pushes to GitHub private repo
- **Result:** Private backup is current

### Step 2: Detect Changes
- Compares files between local private and local public repos
- Uses SHA-256 hashing to detect even 1-byte differences
- Lists NEW, UPDATE, SAME status for each file

### Step 3: Exclude Copyrighted Content
Automatically skips:
- `/local-pdf/` - Official GRC PDFs
- `/local-mp3/` - Audio files
- `/local-notes-ai-transcripts/` - AI transcripts
- `.gitignore` - Each repo maintains its own

### Step 4: Sync Local Private → Local Public
- Copies only tools, docs, and scripts
- Excludes ALL copyrighted material
- Maintains separate `.gitignore` files

### Step 5: Push to GitHub Public
- Commits changes to local public repo
- Pushes to GitHub public repo
- **Result:** Community has latest tools/docs

## Usage

### Basic Sync (One Command)
```powershell
cd D:\Full-Private
.\scripts\Special-Sync.ps1
