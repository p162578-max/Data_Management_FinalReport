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

<div align="center">

| Component | Purpose | Runtime Environment |
|-----------|---------|-------------------|
| **Hadoop HDFS** | Distributed file storage | Hadoop 2.6 Virtual Machine |
| **Apache Hive** | Data warehouse queries and ETL | Hive CLI / PuTTY |
| **Apache Zeppelin** | Interactive notebook (optional) | HDP Platform |
| **Python (Pandas + Matplotlib + Seaborn)** | Data visualization | Local VSCode |
| **Impyla (pyHive)** | Python remote connection to HiveServer2 | Local VSCode |
| **PuTTY** | SSH remote connection to VM | Windows Host |
| **GitHub** | Version control and data transfer | Cloud Repository |

</div>

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

<div align="center">

| File Name | Type | Records |
|-----------|------|---------|
| nba_2024-25_player_statistics.csv | Player game logs | ~37,779 rows |
| nba_2025-26_player_statistics.csv | Player game logs | ~37,576 rows |

</div>


**Core fields (40 columns)**: `firstName`, `lastName`, `points`, `assists`, `reboundsTotal`, `fieldGoalsPercentage`, `threePointersPercentage`, `freeThrowsPercentage`, `plusMinusPoints`, `numMinutes`, `turnovers`, `foulsPersonal`, etc.

#### Player Season Average Summary (Auxiliary Reference Tables)


<div align="center">

| File Name | Records |
|-----------|---------|
| nba_2024-25_regular_players.csv | ~735 rows |
| nba_2025-26_regular_players.csv | ~733 rows |
| nba_2024-25_playoffs_players.csv | ~219 rows |
| nba_2025-26_playoffs_players.csv | ~230 rows |

</div>

#### Team Per-Game Logs (Core Business Tables)

<div align="center">

| File Name | Type | Records |
|-----------|------|---------|
| nba_2024-25_regular_team_games.csv | Regular season team logs | 2,460 rows |
| nba_2025-26_regular_team_games.csv | Regular season team logs | 2,460 rows |
| nba_2024-25_playoffs_team_games.csv | Playoff team logs | ~168 rows |
| nba_2025-26_playoffs_team_games.csv | Playoff team logs | ~170 rows |

</div>


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

<div align="center">
    <img src="Hive%20screenshot/HDFS_HIVE01.png">
</div>

<p align="center">
  <img src="Hive%20screenshot/HDFS_HIVE02.png">
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

Create a query function on Hive and display the query results. I have placed the result screenshot in the Hive screenshot section, and it is presented below：

<p align="center">
  <img src="Data%20visualizations/01_top_scorers.png" alt="Top Scorers" width="70%">
</p>

### 4.5 Phase 5: Data Visualization

Using Python (Matplotlib + Seaborn) connected to HiveServer2 via Impyla, **11 professional charts** were generated

The connection code and function definitions are as follows:
```sql
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib
import seaborn as sns
import os, warnings
warnings.filterwarnings('ignore')

# Configuration
HIVE_HOST = '127.0.0.1'   # IP address
HIVE_PORT = 10000
HIVE_USER = 'root'
OUTPUT_DIR = 'charts'

matplotlib.rcParams['font.sans-serif'] = ['Arial', 'DejaVu Sans']
matplotlib.rcParams['axes.unicode_minus'] = False
sns.set_style('whitegrid')
sns.set_palette('Set2')
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Hive Connection
def get_conn():
    from impala.dbapi import connect
    return connect(host=HIVE_HOST, port=HIVE_PORT, user=HIVE_USER, auth_mechanism='PLAIN', database='nba_db')

def query(sql):
    conn = get_conn()
    cur = conn.cursor()
    cur.execute(sql)
    # Automatically strip table aliases (e.g., 'a.fullname' -> 'fullname') and lower case to prevent KeyErrors
    cols = [d[0].split('.')[-1].lower() for d in cur.description]
    rows = cur.fetchall()
    conn.close()
    return pd.DataFrame(rows, columns=cols)

def save_chart(fig, name):
    path = os.path.join(OUTPUT_DIR, name)
    fig.savefig(path, dpi=200, bbox_inches='tight')
    print('   -> saved:', path)

print('=== Connecting to Hive at', HIVE_HOST + '...')
try:
    df_test = query('SELECT COUNT(*) AS cnt FROM nba_players_clean_2526')
    print('   OK! Rows:', df_test.cnt[0])
except Exception as e:
    print('   FAILED:', e)
    print('   Tips: 1) Check HIVE_HOST  2) Is HiveServer2 running?  3) Port 10000 open?')
    exit()
```

#### The 11 visual charts and their content analysis are as follows:

<p align="center">
  <img src="Data%20visualizations/01_top_scorers.png" alt="Top Scorers" width="70%">
</p>

- Luka Doncic (Lakers) leads the league with an incredible 33.5 PPG, alongside near triple-double averages of 8.3 AST and 7.7 REB. He is followed by Shai Gilgeous-Alexander (Thunder, 31.1 PPG) and Anthony Edwards (Timberwolves, 29.2 PPG).

<p align="center">
  <img src="Data%20visualizations/02_team_scoring.png" alt="Team Scoring" width="70%">
</p>

- The Denver Nuggets top the league with a roaring 122.1 PPG, followed closely by the Miami Heat (120.9 PPG) and San Antonio Spurs (119.8 PPG). At the bottom, the Brooklyn Nets (105.9 PPG) struggle as the least potent offense in the league.

<p align="center">
  <img src="Data%20visualizations/03_reg_vs_playoffs.png" alt="Regular vs Playoffs" width="70%">
</p>

- This chart highlights which players step up in clutch moments. Players like Jalen Brunson (Knicks), Cade Cunningham (Pistons), and Paolo Banchero (Magic) saw significant scoring increases in the playoffs. Conversely, Shai Gilgeous-Alexander and Tyrese Maxey experienced a dip in their scoring outputs during the postseason.

<p align="center">
    <img src="Data%20visualizations/04_improvement.png" alt="Most Improved" width="70%">
</p>

- Nickeil Alexander-Walker shows the most explosive growth, increasing his scoring average by a massive +11.4 PPG. Lauri Markkanen (+7.7 PPG) and Deni Avdija (+7.5 PPG) also show stunning leaps into elite-tier scoring roles.

<p align="center">
  <img src="Data%20visualizations/05_efficiency.png" alt="Scoring Efficiency" width="70%">
</p>

- Nikola Jokic and Shai Gilgeous-Alexander occupy the ideal upper-right quadrant, combining high scoring volume with elite True Shooting Percentage (TS%) and high Plus/Minus values (dark green bubbles). Doncic has the highest volume (farthest right) but with slightly lower efficiency (~61% TS%) compared to Jokic.

<p align="center">
  <img src="Data%20visualizations/06_all_around.png" alt="All-Around Players" width="70%">
</p>

- Nikola Jokic reigns supreme as the ultimate stat-sheet stuffer with a combined score of 51.3, heavily supported by massive rebounding and assist shares. Luka Doncic (49.5) takes second, while Giannis Antetokounmpo (44.5) stands third.

<p align="center">
  <img src="Data%20visualizations/07_home_away.png" alt="Home vs Away" width="70%">
</p>

- While the game distribution between home and away is an even split (left), the win rates show a fascinating anomaly: Away teams had a higher win rate (55.4%) than Home teams (44.6%), scoring more points on the road (116.5) than at home (114.8). This flips traditional home-court advantage on its head.

<p align="center">
  <img src="Data%20visualizations/08_three_pointers.png" alt="Three-Point Accuracy" width="70%">
</p>

- Luke Kennard (Hawks) lights it up from deep, leading the league with a near-impossible 49.7% 3PT%. Bobby Portis (45.6%) and Ayo Dosunmu (45.1%) follow. Jamal Murray’s 43.7% is highly impressive given his massive volume of 561 attempts.

<p align="center">
   <img src="Data%20visualizations/09_star_radar.png" alt="Star Radar" width="70%">
</p>

- Luka Doncic (Green) covers massive real estate in cumulative box-score stats like PTS, REB, and AST. However, Shai Gilgeous-Alexander (Orange) dominates in impact and defensive metrics, showing superior marks in +/-, BLK, and STL.

<p align="center">
  <img src="Data%20visualizations/10_team_boxplot.png" alt="Team Boxplot" width="70%">
</p>

- The Denver Nuggets not only have the highest average but their entire scoring floor and median (dark blue box) are elevated. Teams like the Knicks and 76ers show wide volatility (long whiskers and outliers), while the Brooklyn Nets (far right, maroon) are compressed at the bottom of the league's scoring spectrum.

<p align="center">
  <img src="Data%20visualizations/11_multi_players_pie.png" alt="Multi-Player Pie Chart" width="70%">
</p>

This chart breaks down the scoring portfolios of the league's top 4 scorers into 2-point fields goals (2PT), 3-pointers (3PT), and free throws (FT).

- Luka Doncic (Lakers) & Anthony Edwards (Timberwolves): Both exhibit a more perimeter-heavy profile. Doncic relies on the deep ball for 35.5% of his total points, with Edwards right behind him at 34.9%, showing a much higher reliance on the 3-pointer than the other two stars.

- Shai Gilgeous-Alexander (Thunder) & Jaylen Brown (Celtics): Both dominate inside the arc. They derive a massive ~58% of their total points from 2-pointers (SGA at 58.2%, Brown at 58.3%), emphasizing their mid-range and paint dominance.

- Free Throw Reliance: SGA has the highest share of points coming from the charity stripe at 25.4%, highlighting his elite ability to drive and draw contact. Meanwhile, Edwards relies the least on free throws, with them accounting for only 19.9% of his points.

## 5. Limitations & Future Improvements

### 5.1 Optimizable Aspects (Completed but Improvable)

1. **Automated Data Cleaning**: Current cleaning steps require manual Hive SQL execution; future work can encapsulate them into a Shell script with `hive -f` for one-click execution
2. **Query Performance Optimization**: Certain JOIN queries (e.g., Q3 Regular Season vs Playoffs) can benefit from pre-partitioning `nba_player_season_summary` by `PARTITIONED BY (season, game_type)` to reduce full table scans
3. **Interactive Visualization**: Currently static PNG charts; future iterations can incorporate Plotly or ECharts for interactive dashboards

### 5.2 Technical Limitations

1. **HiveServer2 Connection Stability**: When the Python script connects to Hive via Impala, IP changes or closed ports on the VM require manual `HIVE_HOST` reconfiguration — no auto-discovery mechanism exists
2. **Single-Node Processing Bottleneck**: All analytical queries execute on a single-node Hive instance; larger datasets (e.g., multi-season full Play-by-Play logs) may encounter performance degradation
3. **Data Freshness**: CSV data was manually downloaded and uploaded — no automated data pipeline (e.g., scheduled NBA API ingestion) is in place

### 5.3 Key Takeaways

- The **external table strategy** proved crucial: raw CSV files on HDFS are mapped without duplication, and dropping tables never risks losing source data
- The **summary mart construction** approach reduced complex analytical query complexity from O(n) to O(1): all 16 metric queries reference only `nba_player_season_summary` and `nba_team_games_clean`, never rescanning raw detail tables
- In the visualization phase, the **scatter plot (Q5) and box plot (T10)** delivered the most analytical depth, revealing multi-dimensional relationships — scoring volume vs efficiency and team scoring dispersion — that bar charts and line charts cannot capture

---


## 6. Conclusion

This project successfully implemented a complete big data management pipeline using NBA 2024-25 and 2025-26 season data. Through the integration of Hadoop HDFS, Apache Hive, and Python visualization tools, the entire workflow from data collection to insight generation was established.

From the results, the project delivered **16+ business indicators** and **11 visualization charts** that effectively cover the core scenarios of professional sports data analysis, including scoring leaders, efficiency evaluation, player improvement tracking, home-court advantage quantification, and playoff performance comparison.

One key takeaway is the value of iterative development. The "run first, optimize second, expand third" development model proved especially effective for data management projects. In the future, this pipeline could be extended with Parquet columnar storage for 3-5x performance gains, time-series analysis for monthly trends and back-to-back game impacts, machine learning predictions based on eFG%/TS%/plus-minus metrics, real-time data streaming with Kafka + Spark Streaming, and interactive web dashboards using Superset or Grafana.

---

> **Author**: p162578-max  
> **Course**: STQD6324 Data Management    
> **Submission Date**: June 2026
