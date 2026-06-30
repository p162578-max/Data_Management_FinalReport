#!/bin/bash
# =============================================================================
# NBA Data Management - Final Report
# Phase 1 & 2: Data Collection, Download & HDFS Upload
# =============================================================================

# =============================================================================
# Phase 1: Data Collection
# =============================================================================
# Data sources include Basketball-Reference.com, stats.nba.com, and the
# "NBA Dataset: Box Scores and Stats (1947 – Today)" from Kaggle.
# After processing, 10 raw CSV datasets were compiled for the two most recent
# seasons (2024-25 and 2025-26). All raw files are stored in the dataset/ folder
# of this repository.

# =============================================================================
# Phase 2: Data Download and Transfer
# =============================================================================

# --- Step 1: Log in via PuTTY, clone the repository, and navigate to the download directory ---

mkdir -p ~/nba_project

cd ~/nba_project

# Clone the dataset from GitHub
git clone https://github.com/p162578-max/Data_Management_FinalReport.git

# Navigate to the directory containing the 10 CSV files
cd Data_Management_FinalReport/dataset

# List all CSV files
ls -l *.csv


# --- Step 2: One-click creation of HDFS directories and data upload ---

# Create a temporary folder to store CSV files with headers removed
mkdir -p ./no_header_data

# Remove the header (first line) from each CSV file
tail -n +2 nba_2024-25_player_statistics.csv      > ./no_header_data/nba_2024-25_player_statistics.csv
tail -n +2 nba_2025-26_player_statistics.csv      > ./no_header_data/nba_2025-26_player_statistics.csv
tail -n +2 nba_2024-25_playoffs_players.csv       > ./no_header_data/nba_2024-25_playoffs_players.csv
tail -n +2 nba_2025-26_playoffs_players.csv       > ./no_header_data/nba_2025-26_playoffs_players.csv
tail -n +2 nba_2024-25_playoffs_team_games.csv    > ./no_header_data/nba_2024-25_playoffs_team_games.csv
tail -n +2 nba_2025-26_playoffs_team_games.csv    > ./no_header_data/nba_2025-26_playoffs_team_games.csv
tail -n +2 nba_2024-25_regular_players.csv        > ./no_header_data/nba_2024-25_regular_players.csv
tail -n +2 nba_2025-26_regular_players.csv        > ./no_header_data/nba_2025-26_regular_players.csv
tail -n +2 nba_2024-25_regular_team_games.csv     > ./no_header_data/nba_2024-25_regular_team_games.csv
tail -n +2 nba_2025-26_regular_team_games.csv     > ./no_header_data/nba_2025-26_regular_team_games.csv

# Create HDFS directories and upload data for all 10 datasets

# --- Player per-game statistics ---
hdfs dfs -mkdir -p /nba_data/nba_2024-25_player_statistics
hdfs dfs -put -f ./no_header_data/nba_2024-25_player_statistics.csv /nba_data/nba_2024-25_player_statistics/

hdfs dfs -mkdir -p /nba_data/nba_2025-26_player_statistics
hdfs dfs -put -f ./no_header_data/nba_2025-26_player_statistics.csv /nba_data/nba_2025-26_player_statistics/

# --- Playoffs player statistics ---
hdfs dfs -mkdir -p /nba_data/nba_2024-25_playoffs_players
hdfs dfs -put -f ./no_header_data/nba_2024-25_playoffs_players.csv /nba_data/nba_2024-25_playoffs_players/

hdfs dfs -mkdir -p /nba_data/nba_2025-26_playoffs_players
hdfs dfs -put -f ./no_header_data/nba_2025-26_playoffs_players.csv /nba_data/nba_2025-26_playoffs_players/

# --- Regular season player statistics ---
hdfs dfs -mkdir -p /nba_data/nba_2024-25_regular_players
hdfs dfs -put -f ./no_header_data/nba_2024-25_regular_players.csv /nba_data/nba_2024-25_regular_players/

hdfs dfs -mkdir -p /nba_data/nba_2025-26_regular_players
hdfs dfs -put -f ./no_header_data/nba_2025-26_regular_players.csv /nba_data/nba_2025-26_regular_players/

# --- Playoffs team per-game data ---
hdfs dfs -mkdir -p /nba_data/nba_2024-25_playoffs_team_games
hdfs dfs -put -f ./no_header_data/nba_2024-25_playoffs_team_games.csv /nba_data/nba_2024-25_playoffs_team_games/

hdfs dfs -mkdir -p /nba_data/nba_2025-26_playoffs_team_games
hdfs dfs -put -f ./no_header_data/nba_2025-26_playoffs_team_games.csv /nba_data/nba_2025-26_playoffs_team_games/

# --- Regular season team per-game data ---
hdfs dfs -mkdir -p /nba_data/nba_2024-25_regular_team_games
hdfs dfs -put -f ./no_header_data/nba_2024-25_regular_team_games.csv /nba_data/nba_2024-25_regular_team_games/

hdfs dfs -mkdir -p /nba_data/nba_2025-26_regular_team_games
hdfs dfs -put -f ./no_header_data/nba_2025-26_regular_team_games.csv /nba_data/nba_2025-26_regular_team_games/

# Verify the created HDFS directories (also visible in Hadoop NameNode Web UI)
hdfs dfs -ls /nba_data
