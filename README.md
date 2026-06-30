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

I'm a big fan of the NBA and have a strong interest in player and team statistics. That's why, for this project, I decided to use NBA game data from the last two seasons as my analytical dataset. I collected data from Basketball-Reference.com and the official stats.nba.com website. To enrich the dataset, I also downloaded the "NBA Dataset: Box Scores and Stats (1947 – Today)" from Kaggle and extracted game records from the most recent two seasons. After processing, I compiled 10 raw datasets in total. All these raw files have been uploaded to this repository and stored in the dataset folder for easy access and further use.

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
    <img src="Hive%20screenshot/nba_db.png">
</div>

## 4. Analysis Workflow

### 4.1 Phase 1: Data Collection and HDFS Upload

Clone the dataset repository onto the VM:

```bash
## Step 1: After logging in via PuTTY, clone the repository and navigate to the download directory

mkdir -p ~/nba_project

cd ~/nba_project

git clone https://github.com/p162578-max/Data_Management_FinalReport.git  # Clone the dataset from GitHub

cd Data_Management_FinalReport/dataset  # Navigate to the directory containing the 10 CSV files

ls -l *.csv  # List all CSV files

Step 2: One‑click creation of HDFS directories and data upload

# Create a temporary folder to store data without headers
mkdir -p ./no_header_data

# Remove the header (first line) from each CSV file
tail -n +2 nba_2024-25_player_statistics.csv > ./no_header_data/nba_2024-25_player_statistics.csv
tail -n +2 nba_2025-26_player_statistics.csv > ./no_header_data/nba_2025-26_player_statistics.csv
tail -n +2 nba_2024-25_playoffs_players.csv > ./no_header_data/nba_2024-25_playoffs_players.csv
tail -n +2 nba_2025-26_playoffs_players.csv > ./no_header_data/nba_2025-26_playoffs_players.csv
tail -n +2 nba_2024-25_playoffs_team_games.csv > ./no_header_data/nba_2024-25_playoffs_team_games.csv
tail -n +2 nba_2025-26_playoffs_team_games.csv > ./no_header_data/nba_2025-26_playoffs_team_games.csv
tail -n +2 nba_2024-25_regular_players.csv > ./no_header_data/nba_2024-25_regular_players.csv
tail -n +2 nba_2025-26_regular_players.csv > ./no_header_data/nba_2025-26_regular_players.csv
tail -n +2 nba_2024-25_regular_team_games.csv > ./no_header_data/nba_2024-25_regular_team_games.csv
tail -n +2 nba_2025-26_regular_team_games.csv > ./no_header_data/nba_2025-26_regular_team_games.csv

# Create HDFS directories for each dataset
hdfs dfs -mkdir -p /nba_data/nba_2024-25_player_statistics
hdfs dfs -mkdir -p /nba_data/nba_2025-26_player_statistics
hdfs dfs -put -f ./no_header_data/nba_2024-25_player_statistics.csv /nba_data/nba_2024-25_player_statistics/
hdfs dfs -put -f ./no_header_data/nba_2025-26_player_statistics.csv /nba_data/nba_2025-26_player_statistics/

hdfs dfs -mkdir -p /nba_data/nba_2024-25_playoffs_players
hdfs dfs -mkdir -p /nba_data/nba_2025-26_playoffs_players
hdfs dfs -put -f ./no_header_data/nba_2024-25_playoffs_players.csv /nba_data/nba_2024-25_playoffs_players/
hdfs dfs -put -f ./no_header_data/nba_2025-26_playoffs_players.csv /nba_data/nba_2025-26_playoffs_players/

hdfs dfs -mkdir -p /nba_data/nba_2024-25_playoffs_team_games
hdfs dfs -mkdir -p /nba_data/nba_2025-26_playoffs_team_games
hdfs dfs -put -f ./no_header_data/nba_2024-25_playoffs_team_games.csv /nba_data/nba_2024-25_playoffs_team_games/
hdfs dfs -put -f ./no_header_data/nba_2025-26_playoffs_team_games.csv /nba_data/nba_2025-26_playoffs_team_games/

hdfs dfs -mkdir -p /nba_data/nba_2024-25_regular_players
hdfs dfs -mkdir -p /nba_data/nba_2025-26_regular_players
hdfs dfs -put -f ./no_header_data/nba_2024-25_regular_players.csv /nba_data/nba_2024-25_regular_players/
hdfs dfs -put -f ./no_header_data/nba_2025-26_regular_players.csv /nba_data/nba_2025-26_regular_players/

hdfs dfs -mkdir -p /nba_data/nba_2024-25_regular_team_games
hdfs dfs -mkdir -p /nba_data/nba_2025-26_regular_team_games
hdfs dfs -put -f ./no_header_data/nba_2024-25_regular_team_games.csv /nba_data/nba_2024-25_regular_team_games/
hdfs dfs -put -f ./no_header_data/nba_2025-26_regular_team_games.csv /nba_data/nba_2025-26_regular_team_games/

# Check the created directories (also visible in Hadoop's file view)
hdfs dfs -ls /nba_data
```

### 4.2 Phase 2: Hive Table Creation

Create 10 external tables corresponding to each CSV file, covering player statistics, regular/playoff player summaries, and regular/playoff team game logs for both seasons.I've saved the commands and details for creating external tables in the Hive interface in  **02_HIVE_CREATE_TABLE.sql** .  You can refer to this file if you want to reproduce the table creation process, paying attention to the corresponding data types.

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

Perform ETL to clean raw data and create unified views，create 5 tables and 1 view：
- 01 nba_players_clean_2425
- 02 nba_players_clean_2526	
- 03 nba_team_games_clean
- 04 nba_team_season_summary
- 05 nba_player_season_summary
- 06 nba_players_all(View for Players)

I have compiled and saved the cleaning functions and table join functions in the file  **03_Data_Cleaning_and_Table_Join.sql** .  You can refer to it for details.

For example：

```sql
-- Create cleaned advanced player statistics table for 2024-25 season
CREATE TABLE IF NOT EXISTS nba_players_clean_2425
STORED AS TEXTFILE
AS
SELECT
  firstName,
  lastName,
  CONCAT(firstName, ' ', lastName) AS fullName,
  personId,
  playerteamName AS team_name,
  opponentteamName AS opponent,
  gameType AS game_type,
  -- Mark season phase
  CASE WHEN gameType = 'Regular Season' THEN 'Regular'
       WHEN gameType = 'Playoffs' THEN 'Playoffs'
       ELSE 'Other'
  END AS season_phase,
  win AS is_win,
  home AS is_home,
  -- Minutes played: set DNP (Did Not Play) absent players to 0
  CASE WHEN numMinutes IS NULL OR comment LIKE 'DNP%' THEN 0.0
       ELSE numMinutes
  END AS minutes_played,
  points AS pts,
  assists AS ast,
  blocks AS blk,
  steals AS stl,
  reboundsTotal AS reb,
  reboundsOffensive AS oreb,
  reboundsDefensive AS dreb,
  fieldGoalsMade AS fgm,
  fieldGoalsAttempted AS fga,
  -- Use NULL for percentage when no attempts, preventing division by zero errors
  CASE WHEN fieldGoalsAttempted > 0 THEN fieldGoalsPercentage ELSE NULL END AS fg_pct,
  threePointersMade AS fg3m,
  threePointersAttempted AS fg3a,
  CASE WHEN threePointersAttempted > 0 THEN threePointersPercentage ELSE NULL END AS fg3_pct,
  freeThrowsMade AS ftm,
  freeThrowsAttempted AS fta,
  CASE WHEN freeThrowsAttempted > 0 THEN freeThrowsPercentage ELSE NULL END AS ft_pct,
  foulsPersonal AS pf,
  turnovers AS tov,
  plusMinusPoints AS plus_minus,
  -- Advanced feature engineering: Effective Field Goal % eFG% = (FGM + 0.5*3PM) / FGA
  CASE WHEN fieldGoalsAttempted > 0
       THEN ROUND((fieldGoalsMade + 0.5 * threePointersMade) / fieldGoalsAttempted, 3)
       ELSE NULL
  END AS efg_pct,
  -- Advanced feature engineering: True Shooting % TS% = PTS / (2 * (FGA + 0.44*FTA))
  CASE WHEN fieldGoalsAttempted + freeThrowsAttempted > 0
       THEN ROUND(points / (2.0 * (fieldGoalsAttempted + 0.44 * freeThrowsAttempted)), 3)
       ELSE NULL
  END AS ts_pct,
  -- Advanced feature engineering: Player efficiency per minute metric (simplified contribution)
  CASE WHEN (CASE WHEN numMinutes IS NULL OR comment LIKE 'DNP%' THEN 0.0 ELSE numMinutes END) > 0
       THEN ROUND((points + reboundsTotal + assists + steals + blocks - (fieldGoalsAttempted - fieldGoalsMade) - (freeThrowsAttempted - freeThrowsMade) - turnovers) / (CASE WHEN numMinutes IS NULL OR comment LIKE 'DNP%' THEN 0.0 ELSE numMinutes END), 2)
       ELSE NULL
  END AS gm_score_per_min,
  gameDate AS game_date
FROM nba_player_stats_2425;
```

### 4.4 Phase 4: Data Analysis

The project produces **16+ business analysis indicators** across two dimensions:

#### Player Dimension (10 indicators)
- 01	Total Points Leaders TOP 20
- 02	Scoring Leaders by AVG TOP 20
- 03	Regular Season vs Playoffs Differential
- 04	MIP Year-over-Year Growth Tracker
- 05	All-Around Leaders TOP 20
- 06	Postseason MVP Candidates Tracker
- 07	Three-Point Precision Shooting Ranking
- 08	Individual Average Plus-Minus Leaders
- 09	The five best players of each team this season
- 10	Comparison of the top 4 scorers

#### Team Dimension (6 indicators)
- 01	Team Offensive Rankings with FG Details
- 02	Home vs Away Strategic Split
- 03	Team Offensive Rankings
- 04	Postseason Playoff Team Offensive Rankings
- 05	Defensive and Net Margin Elite Tier Rankings
- 06	Maximum Team Single-Game Scoring Milestones

I have compiled and saved the query functions in the file **04_HIVE_Query_Commands.sql**. 

For example, create a query function in Hive and display the query results. I’ve included a screenshot of the results in the Hive screenshot section below:

```sql
-- 01 Total Points Leaders TOP 20
SELECT fullName, team_name, games_played, total_pts, avg_pts, avg_ast, avg_reb
FROM nba_player_season_summary
WHERE season = '2025-26' AND game_type = 'Regular Season' AND games_played >= 20
ORDER BY total_pts DESC LIMIT 20;
```

<div align="center">
    <img src="Hive%20screenshot/Players_01.png" width="600" />
</div>

<details>
  <summary style="font-weight: bold; font-size: 1.2em;"> 📸📸 Click to expand – other 15 screenshots</summary>
  <br>

  <!-- Players -->
  <p><b>Players Screenshot：</b></p>
  <div style="display: flex; flex-direction: column; gap: 10px; align-items: flex-start;">
    <img src="Hive%20screenshot/Players_02.png" width="600" />
    <img src="Hive%20screenshot/Players_03.png" width="600" />
    <img src="Hive%20screenshot/Players_04.png" width="600" />
    <img src="Hive%20screenshot/Players_05.png" width="600" />
    <img src="Hive%20screenshot/Players_06.png" width="600" />
    <img src="Hive%20screenshot/Players_07.png" width="600" />
    <img src="Hive%20screenshot/Players_08.png" width="600" />
    <img src="Hive%20screenshot/Players_09.png" width="600" />
    <img src="Hive%20screenshot/Players_10.png" width="600" />
  </div>

  <br>

  <!-- Teams -->
  <p><b>Teams Screenshot：</b></p>
  <div style="display: flex; flex-direction: column; gap: 10px; align-items: flex-start;">
    <img src="Hive%20screenshot/Teams_01.png" width="600" />
    <img src="Hive%20screenshot/Teams_02.png" width="600" />
    <img src="Hive%20screenshot/Teams_03.png" width="600" />
    <img src="Hive%20screenshot/Teams_04.png" width="600" />
    <img src="Hive%20screenshot/Teams_05.png" width="600" />
    <img src="Hive%20screenshot/Teams_06.png" width="600" />
  </div>

</details>

After querying relevant metrics and content on Hive, I combined the Zeppelin usage I learned in class and reproduced the query commands on Zeppelin. I used the JDBC interpreter configured on Zeppelin to connect to the Hive data warehouse. The specific code segment starts with %jdbc(hive) and queries 16 metrics related to players and teams.

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

This horizontal bar chart illustrates the top 20 scorers of the 2025-26 NBA season, ranked by Points Per Game (PPG), alongside their average assists (ast) and rebounds (reb).

- Luka Doncic (Lakers) leads the league with an incredible 33.5 PPG, alongside near triple-double averages of 8.3 AST and 7.7 REB. He is followed by Shai Gilgeous-Alexander (Thunder, 31.1 PPG) and Anthony Edwards (Timberwolves, 29.2 PPG). Only two players crossed the 30 PPG threshold: Luka Doncic (33.5) and Shai Gilgeous-Alexander (31.1).

- Jokic once again stands out for his absurd efficiency and versatility, ranking 9th in scoring (27.7 pts) while nearly averaging a 28-point triple-double with 10.7 ast and 12.9 reb.

<p align="center">
  <img src="Data%20visualizations/02_team_scoring.png" alt="Team Scoring" width="70%">
</p>

This bar chart illustrates the Points Per Game (PPG) for all 30 NBA teams during the 2025-26 season, sorted from highest to lowest. Additionally, the percentage inside each bar indicates the team's Win Percentage, which is color-coded by performance tiers.

- The chart categorizes teams into three performance tiers based on their win percentage:
  - Red (Elite / Contenders): High win percentages (typically $>60\%$). These teams possess elite offensive power paired with winning records.
  - Orange (Mid-Tier / Play-In ): Balanced win percentages (around $45\% - 60\%$). Solid offensive teams fighting for playoff positions.
  - Gray (Rebuilding / Lottery): Low win percentages (typically $<40\%$). Despite some high scoring averages, these teams struggle to convert offense into wins.

- The Denver Nuggets lead the entire league with a blistering 122.1 PPG, maintaining an elite 65.9% win rate.
- The Utah Jazz rank 9th in scoring with an impressive 117.6 PPG, yet they are in the gray tier with a meager 26.8% win rate, suggesting severe defensive struggles.
- The Brooklyn Nets rank dead last in offensive output, averaging only 105.9 PPG with a 24.4% win rate, sitting nearly 16 points per game behind the Nuggets.

<p align="center">
  <img src="Data%20visualizations/03_reg_vs_playoffs.png" alt="Regular vs Playoffs" width="70%">
</p>

This clustered bar chart demonstrates how the scoring outputs (Points Per Game) of key NBA players changed between the Regular Season (Blue) and the Playoffs (Red) during the 2025-26 season.

- Players like Paolo Banchero, Dillon Brooks, Scottie Barnes, and RJ Barrett saw substantial increases in their scoring averages when the postseason arrived, showing they thrive under higher defensive pressure.
- Conversely, league superstars like Shai Gilgeous-Alexander, Jaylen Brown, and Tyrese Maxey experienced notable dips in their PPG during the playoffs, likely due to targeted defensive scheming and slower game pacing.

<p align="center">
    <img src="Data%20visualizations/04_improvement.png" alt="Most Improved" width="70%">
</p>

This clustered bar chart compares the scoring progression (Points Per Game) of the league's most improved players between the 2024-25 season (Gray) and the 2025-26 season (Green). The green numeric labels above the bars represent the exact PPG increase for each player.

- Nickeil Alexander-Walker achieved the largest scoring jump in the league, exploding by +11.4 PPG to elevate his average from a single-digit role player (9.4 PPG) into a verified 20+ point scoring threat (20.8 PPG).
- Some scoring explosions are due to roster changes and unexpected situations. For example, Lauri Markkanen's surge (+7.7 PPG) might be related to the team's player configuration; in order to get draft picks, the team traded away players with high scoring explosive power on the roster, forcing Markkanen to take on more shots and scoring. On the other hand, Jaylen Brown's increase (+6.5 PPG) was because the team's other core player, Tatum, got injured, so he had to shoulder the team's offensive firepower and score more points.
- Young players like Reed Sheppard (+7.4) and Keyonte George (+6.9) showed immense developmental leaps, securing expanded roles and turning into major focal points for their teams' offenses.

<p align="center">
  <img src="Data%20visualizations/05_efficiency.png" alt="Scoring Efficiency" width="70%">
</p>

This bubble chart maps player performance across four distinct dimensions during the 2025-26 NBA season:
 - - X-Axis: Points Per Game (PPG)
 - - Y-Axis: True Shooting Percentage (TS%)
 - - Bubble Size: Games Played
 - - Color Bar: Average Plus/Minus Value (+/-)

- Players in the far right are the league's primary offensive options. Nikola Jokic and Shai Gilgeous-Alexander stand out in the upper right, combining elite volume ($\ge 27\text{ PPG}$) with hyper-efficiency (TS% near or above $68\%$). Their deep green bubbles confirm their massive positive impact on winning.
- Luka Doncic occupies the extreme far-right position alone ($\sim 33.5\text{ PPG}$), representing the league's highest offensive load, while maintaining a very solid $61\%$ TS%.
- The color gradient clearly highlights that high efficiency (TS%) and high volume generally correlate with a strongly positive average plus/minus (dark green), whereas low-efficiency high-volume players or lower-quadrant players skew towards orange and red.

<p align="center">
  <img src="Data%20visualizations/06_all_around.png" alt="All-Around Players" width="70%">
</p>

This stacked bar chart shows the league's top 20 players based on their cumulative box-score impact, calculated by adding Points (Red), Rebounds (Orange), and Assists (Green). The total value at the end of each bar represents their combined per-game statistical contribution.

- Nikola Jokic captures the absolute top spot with a staggering 51.3 combined statistic, driven by balanced elite metrics across all three categories. Luka Doncic follows closely at 49.5, fueled by his massive scoring volume (the largest red bar in the chart).
- The chart beautifully highlights contrasting playstyles. For example, Victor Wembanyama (39.6 total) relies heavily on points and rebounds (large orange bar) with less playmaking, whereas James Harden (38.3 total) features a much larger assist slice (green bar) relative to his rebounding.
- Jalen Johnson of the Hawks makes a phenomenal appearance in the top 5 with a 41.2 total rating, cementing his status as one of the elite versatile forwards in this simulated data landscape.

<p align="center">
  <img src="Data%20visualizations/07_home_away.png" alt="Home vs Away" width="70%">
</p>

This analysis investigates the impact of home court advantage during the 2025-26 NBA season, utilizing two key visualizations: a Game Distribution Pie Chart and a Home vs. Away Win Rate Bar Chart.

- Significant Win Rate Discrepancy: Teams playing on their home court experience a 10.8% bump in win probability compared to playing on the road. In the context of an NBA season, this is a massive statistical edge.

- Elevated Offensive Efficiency: Teams score an average of 1.7 more points per game at home. This boost in offensive production can likely be attributed to familiar shooting backdrops, the energy of the home crowd, and the absence of travel fatigue.

- The data from the 2025-26 season strongly confirms that home-court advantage remains a critical factor in determining game outcomes, substantially boosting both a team's offensive output and their overall likelihood of winning.

<p align="center">
  <img src="Data%20visualizations/08_three_pointers.png" alt="Three-Point Accuracy" width="70%">
</p>

This horizontal bar chart ranks the top 15 individual three-point shooters of the 2025-26 season who met the minimum qualification threshold of 100 three-point attempts (3PA).

- Luke Kennard (Hawks) absolute dominates the efficiency leaderboard, shooting a historic 49.7% on 149 attempts, nearly breaching the legendary 50% threshold.
- While Kennard leads in efficiency, players like Jamal Murray (561 3PA at 43.7%) and Isaiah Joe (416 3PA at 42.5%) showcase extraordinary elite volume while maintaining elite, sniper-level efficiency.

<p align="center">
   <img src="Data%20visualizations/09_star_radar.png" alt="Star Radar" width="70%">
</p>

This radar chart provides a normalized, multi-dimensional comparison between the league's top two MVP candidates of the 2025-26 season: Luka Doncic (Green) and Shai Gilgeous-Alexander (Orange). The metrics include Rebounds (REB), Assists (AST), Points (PTS), Plus/Minus (+/-), Blocks (BLK), and Steals (STL).

- Doncic dominates the upper half of the radar chart, achieving maximum normalized scores ($1.0$) in Points (PTS), Assists (AST), Rebounds (REB), and Steals (STL). This highlights his massive, elite offensive workload and playmaking engine.
- While slightly trailing Doncic in raw counting volume for passing and rebounding, SGA dominates the bottom half of the chart. He hits a perfect $1.0$ in Plus/Minus (+/-) and Blocks (BLK), underscoring his superior rim protection for a guard and his elite translation of individual production into team success.

<p align="center">
  <img src="Data%20visualizations/10_team_boxplot.png" alt="Team Boxplot" width="70%">
</p>

This boxplot with overlaid individual game data points (stripplot) visualizes the scoring consistency, floor, ceiling, and offensive variance for all 30 NBA teams during the 2025-26 season, ordered by their median scoring output.
- Key Statistical Reading Guide
  - Box Center Line: Median scoring performance per game.
  - Box Length (Interquartile Range): Represents the middle 50% of games played. Shorter boxes mean high consistency, while longer boxes mean high unpredictability.
  - Outliers (Dots outside whiskers): Games with extreme blowout scores or defensive gridlocks.

- The Denver Nuggets not only boast the highest median scoring output (aligning with their #1 ranking in total PPG), but their tight box profile shows remarkable offensive stability, consistently hovering between 115 and 130 points per game.
- Teams like the Philadelphia 76ers, New York Knicks, and Atlanta Hawks feature exceptionally long vertical whiskers and prominent outlier circles. This indicates high offensive volatility, capable of exploding for 150+ points or crashing to sub-90 performances depending on game pacing and hot shooting nights.
- The Brooklyn Nets sit squarely at the bottom of the distribution chart. Their entire box is shifted downward, with their median sitting below 110 points and recording the single lowest scoring game outlier of the season (under 70 points).


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
