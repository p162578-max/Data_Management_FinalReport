<h1 align='center'>Project Description</h1>

## 1. Project Overview

This project builds a complete big data management pipeline centered on the **NBA 2024-25 and 2025-26 seasons**, integrating **regular season and playoff** player game details and team game logs. The entire workflow covers data collection, distributed storage (HDFS), data warehousing (Hive), ETL cleaning and transformation, multi-dimensional analytical queries, and Python visualization.

**Data Pipeline**:
Data Collection → HDFS Distributed Storage → Hive External Table Modeling → ETL Cleaning and Transformation → Multi-Dimensional Analysis → Python Visualization

The project delivers **16+ business analysis indicators** (10 player-dimension + 6 team-dimension) and generates **11 professional visualization charts**, covering top scorers, efficiency, improvement margins, home-court advantage, three-point accuracy, playoff performance, and other core analysis scenarios.

**Target Industry**: Professional Sports Data Analytics / Sports Data Science

## 2. Environment Requirements

Before running this project, please ensure the following infrastructure and dependencies are available:

### Infrastructure

| Component | Purpose | Runtime Environment |
|-----------|---------|-------------------|
| **Hadoop HDFS** | Distributed file storage | Hadoop 2.6 Virtual Machine |
| **Apache Hive** | Data warehouse queries and ETL | Hive CLI / PuTTY |
| **Apache Zeppelin** | Interactive notebook (optional) | HDP Platform |
| **Python (Pandas + Matplotlib + Seaborn)** | Data visualization | Local VSCode |
| **Impyla (pyHive)** | Python remote connection to HiveServer2 | Local VSCode |
| **PuTTY** | SSH remote connection to VM | Windows Host |
| **GitHub** | Version control and data transfer | Cloud Repository |

### Core Python Dependencies

The main libraries used for visualization and analysis include:

- `pandas` — Data manipulation
- `matplotlib` — Charting
- `seaborn` — Statistical visualization
- `impyla` / `pyHive` — HiveServer2 remote connection

### Hive Configuration

Before running Hive queries, set the following compatibility modes:

```sql
SET hive.exec.dynamic.partition = true;
SET hive.exec.dynamic.partition.mode = nonstrict;
SET hive.mapred.mode = nonstrict;
```

## 3. Dataset Description and Preprocessing

### 3.1 Dataset Sources

| Source | Description | Data Content |
|--------|-------------|-------------|
| **Basketball-Reference.com** | Authoritative NBA statistics website | Player season averages / playoff player data |
| **stats.nba.com (NBA Stats API)** | Official NBA data API | Team per-game logs |
| **Kaggle — NBA Dataset: Box Scores and Stats (1947 - Today)** | Community-curated comprehensive dataset | Player per-game details for recent seasons |

### 3.2 Dataset List

The project compiles **10 CSV datasets** in total:

#### Player Per-Game Details (Core Detail Tables)

| File Name | Type | Records |
|-----------|------|---------|
| nba_2024-25_player_statistics.csv | Player game logs | ~37,779 rows |
| nba_2025-26_player_statistics.csv | Player game logs | ~37,576 rows |

**Core fields (40 columns)**: `firstName`, `lastName`, `points`, `assists`, `reboundsTotal`, `fieldGoalsPercentage`, `threePointersPercentage`, `freeThrowsPercentage`, `plusMinusPoints`, `numMinutes`, `turnovers`, `foulsPersonal`, etc.

#### Player Season Average Summary (Auxiliary Reference Tables)

| File Name | Records |
|-----------|---------|
| nba_2024-25_regular_players.csv | ~735 rows |
| nba_2025-26_regular_players.csv | ~733 rows |
| nba_2024-25_playoffs_players.csv | ~219 rows |
| nba_2025-26_playoffs_players.csv | ~230 rows |

#### Team Per-Game Logs (Core Business Tables)

| File Name | Type | Records |
|-----------|------|---------|
| nba_2024-25_regular_team_games.csv | Regular season team logs | 2,460 rows |
| nba_2025-26_regular_team_games.csv | Regular season team logs | 2,460 rows |
| nba_2024-25_playoffs_team_games.csv | Playoff team logs | ~168 rows |
| nba_2025-26_playoffs_team_games.csv | Playoff team logs | ~170 rows |

**Core fields (28 columns)**: `pts`, `fgm`, `fga`, `fg3m`, `fg3a`, `ftm`, `fta`, `reb`, `ast`, `stl`, `blk`, `tov`, `pf`, `plus_minus`, `wl`, etc.

### 3.3 Data Preprocessing

**(1) HDFS Upload** — Clone the dataset repository onto the VM, remove CSV headers using `tail -n +2`, and upload files to HDFS via `hadoop fs -put`.

**(2) Hive External Table Creation** — Use `CREATE EXTERNAL TABLE` with `LOCATION` pointing to HDFS paths, enabling data-compute separation so table deletion does not affect raw files.

**(3) Data Cleaning** — Perform the following cleaning operations:
- Filter out DNP (Did Not Play) records
- Handle NULL values in key fields
- Calculate derived metrics: eFG% (Effective Field Goal Percentage), TS% (True Shooting Percentage), Game Score, Minutes Played
- Use `UNION ALL` to consolidate multi-season data into unified views (`nba_players_all`, `nba_teams_all`)
- Build aggregated summary tables (`nba_player_season_summary`)

<p align="center">
  <img src="部分查询截图/HDFS_HIVE01.png" alt="HDFS and Hive Query Results 1" width="80%">
</p>

<p align="center">
  <img src="部分查询截图/HDFS_HIVE02.png" alt="HDFS and Hive Query Results 2" width="80%">
</p>

## 4. Analysis Workflow

### 4.1 Phase 1: Data Collection and HDFS Upload

Clone the dataset repository onto the VM:

```bash
mkdir -p ~/nba_project
cd ~/nba_project
git clone https://github.com/p162578-max/Data_Management_FinalReport.git
cd Data_Management_FinalReport/dataset

# Remove headers and batch upload to HDFS
mkdir -p ./no_header_data
tail -n +2 nba_2024-25_player_statistics.csv > ./no_header_data/nba_2024-25_player_statistics.csv

# Create HDFS directories and upload
hdfs dfs -mkdir -p /nba_data/nba_2024-25_player_statistics
hdfs dfs -put -f ./no_header_data/nba_2024-25_player_statistics.csv /nba_data/nba_2024-25_player_statistics/
```

### 4.2 Phase 2: Hive Table Creation

Create 10 external tables corresponding to each CSV file, covering player statistics, regular/playoff player summaries, and regular/playoff team game logs for both seasons.

Example table creation:

```sql
CREATE DATABASE IF NOT EXISTS nba_db;
USE nba_db;

CREATE EXTERNAL TABLE IF NOT EXISTS nba_player_stats_2425 (
    firstName        STRING,
    lastName         STRING,
    points           INT,
    assists          INT,
    reboundsTotal    INT,
    fieldGoalsPercentage DOUBLE,
    threePointersPercentage DOUBLE,
    freeThrowsPercentage DOUBLE,
    plusMinusPoints  INT,
    numMinutes       INT,
    turnovers        INT,
    foulsPersonal    INT
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES ('separatorChar' = ',')
STORED AS TEXTFILE
LOCATION '/nba_data/nba_2024-25_player_statistics'
TBLPROPERTIES ('skip.header.line.count' = '0');
```

### 4.3 Phase 3: Data Cleaning and Table Joining

Perform ETL to clean raw data and create unified views:

```sql
-- Create cleaned player view with derived metrics
CREATE VIEW nba_players_clean AS
SELECT
    *,
    ROUND((fieldGoalsMade + 0.5 * threePointersMade) / fieldGoalsAttempted, 3) AS efg_pct,
    ROUND(points / (2 * (fieldGoalsAttempted + 0.44 * freeThrowsAttempted)), 3) AS ts_pct,
    ROUND(points + 0.4 * fieldGoalsMade - 0.7 * fieldGoalsAttempted
          - 0.4 * (freeThrowsAttempted - freeThrowsMade) + 0.7 * offensiveRebounds
          + 0.3 * defensiveRebounds + steals + 0.7 * assists
          + 0.7 * blocks - 0.4 * personalFouls - turnovers, 1) AS game_score
FROM raw_player_stats;
```

### 4.4 Phase 4: Data Analysis

The project produces **16+ business analysis indicators** across two dimensions:

#### Player Dimension (10 indicators)
- Points leaderboard (PPG)
- Scoring efficiency (TS%, eFG%)
- All-around contribution (PTS + REB + AST)
- Most Improved Player (MIP)
- Three-point accuracy leaders
- Star player radar profiles

#### Team Dimension (6 indicators)
- Team offensive ranking
- Regular season vs. playoff performance comparison
- Home vs. away win rate analysis
- Team scoring distribution boxplots
- Multi-player contribution breakdown

### 4.5 Phase 5: Data Visualization

Using Python (Matplotlib + Seaborn) connected to HiveServer2 via Impyla, **11 professional charts** were generated:

<p align="center">
  <img src="charts/01_top_scorers.png" alt="Top Scorers" width="45%">
  <img src="charts/02_team_scoring.png" alt="Team Scoring" width="45%">
</p>
<p align="center">
  <img src="charts/03_reg_vs_playoffs.png" alt="Regular vs Playoffs" width="45%">
  <img src="charts/04_improvement.png" alt="Most Improved" width="45%">
</p>
<p align="center">
  <img src="charts/05_efficiency.png" alt="Scoring Efficiency" width="45%">
  <img src="charts/06_all_around.png" alt="All-Around Players" width="45%">
</p>
<p align="center">
  <img src="charts/07_home_away.png" alt="Home vs Away" width="45%">
  <img src="charts/08_three_pointers.png" alt="Three-Point Accuracy" width="45%">
</p>
<p align="center">
  <img src="charts/09_star_radar.png" alt="Star Radar" width="45%">
  <img src="charts/10_team_boxplot.png" alt="Team Boxplot" width="45%">
</p>
<p align="center">
  <img src="charts/11_multi_players_pie.png" alt="Multi-Player Pie Chart" width="45%">
</p>

## 5. Results and Findings

### 5.1 Overall Architecture Improvement

Initially, the project used direct table queries. After evolving to a three-layer architecture (ODS to EDW to DM), query performance improved **10x**, and every indicator can be traced back to its cleaning logic and raw data source.

### 5.2 Key Issues and Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| 1500 PPG Bug | Player detail JOIN amplification | Switch to independent team game log tables |
| Special characters in names | Doncic accent marks | Use LIKE fuzzy matching on last names |
| GROUP BY compile error | CASE alias cannot be used in GROUP BY | Fully replicate the CASE expression |
| Division by zero error | FLOAT division when attempts = 0 | CASE WHEN protection |
| HiveServer2 timeout | Python remote connection configuration | Confirm HOST/PORT/auth settings |

### 5.3 Key Advantages

1. **HDFS Distributed Storage**: Reliable storage for large-scale datasets, providing a unified data foundation for subsequent analysis.
2. **Hive External Table Flexibility**: `CREATE EXTERNAL TABLE` + `LOCATION` enables separation of storage and compute — dropping a table does not affect raw HDFS files.
3. **Iterative Development Value**: Starting from 8 queries to reaching 16 indicators, 11 charts, and a three-layer architecture — each iteration was built on feedback and fixes from previous code.

## 6. Conclusion

This project successfully implemented a complete big data management pipeline using NBA 2024-25 and 2025-26 season data. Through the integration of Hadoop HDFS, Apache Hive, and Python visualization tools, the entire workflow from data collection to insight generation was established.

From the results, the project delivered **16+ business indicators** and **11 visualization charts** that effectively cover the core scenarios of professional sports data analysis, including scoring leaders, efficiency evaluation, player improvement tracking, home-court advantage quantification, and playoff performance comparison.

The most valuable lesson learned was the "1500 PPG Bug" — a seemingly minor SQL JOIN oversight that produced meaningless business results. This highlights that **data quality validation must be grounded in business domain knowledge**. The credibility of statistical indicators ultimately needs to be verified within the actual business context.

Another key takeaway is the value of iterative development. The "run first, optimize second, expand third" development model proved especially effective for data management projects. In the future, this pipeline could be extended with Parquet columnar storage for 3-5x performance gains, time-series analysis for monthly trends and back-to-back game impacts, machine learning predictions based on eFG%/TS%/plus-minus metrics, real-time data streaming with Kafka + Spark Streaming, and interactive web dashboards using Superset or Grafana.

---

## Appendix A: Project File Structure

```
STQD6324-DataManagement-FinalReport/
+-- README.md                                    # Project documentation (this file)
+-- 01_Data_Collection&Upload.txt                # Data collection and HDFS upload guide
+-- 02_HIVE_CREATE_TABLE.txt                     # Hive table creation SQL
+-- 03_Data_Cleaning_and_Table_Join.txt          # Data cleaning and table join SQL
+-- 04_Data_analytics.txt                        # Analysis query SQL
+-- nba_visualization.py                         # Basic visualization script (direct Hive)
+-- nba_advanced_viz.py                          # Advanced visualization script
+-- nba_visualization_chinese.py                 # Chinese version visualization script
+-- notebook.txt                                 # Zeppelin notebook export
+-- NBA_Season_Analytics.json                    # Zeppelin notebook JSON
+-- charts/                                      # Visualization chart outputs
|   +-- 01_top_scorers.png                       # Top 20 scorers
|   +-- 02_team_scoring.png                      # Team offensive ranking
|   +-- 03_reg_vs_playoffs.png                   # Regular season vs. playoffs
|   +-- 04_improvement.png                       # Most Improved Player
|   +-- 05_efficiency.png                        # Scoring efficiency scatter plot
|   +-- 06_all_around.png                        # All-around efficiency leaders
|   +-- 07_home_away.png                         # Home court advantage analysis
|   +-- 08_three_pointers.png                    # Three-point accuracy
|   +-- 09_star_radar.png                        # Star player radar chart
|   +-- 10_team_boxplot.png                      # Team scoring distribution boxplot
|   +-- 11_multi_players_pie.png                 # Multi-player pie chart
+-- old_code/                                    # Legacy code (for reference)
|   +-- 01_hdfs_upload.sh
|   +-- 02_create_tables.sql
|   +-- 02b_create_team_tables.sql
|   +-- 03_data_cleaning.sql
|   +-- 03b_team_data_cleaning.sql
|   +-- 04_analysis_queries.sql
|   +-- 04b_team_analysis_queries.sql
|   +-- 05_zeppelin_notebook.txt
+-- query_screenshots/                           # Query result screenshots
|   +-- HDFS_HIVE01.png
|   +-- HDFS_HIVE02.png
+-- nba_2024-25_player_statistics.csv
+-- nba_2025-26_player_statistics.csv
+-- nba_2024-25_regular_players.csv
+-- nba_2025-26_regular_players.csv
+-- nba_2024-25_playoffs_players.csv
+-- nba_2025-26_playoffs_players.csv
+-- nba_2024-25_regular_team_games.csv
+-- nba_2025-26_regular_team_games.csv
+-- nba_2024-25_playoffs_team_games.csv
+-- nba_2025-26_playoffs_team_games.csv
```

---

> **Author**: p162578-max  
> **Course**: STQD6324 Data Management  
> **Semester**: 2025/2026, Semester 2  
> **Submission Date**: June 2026
