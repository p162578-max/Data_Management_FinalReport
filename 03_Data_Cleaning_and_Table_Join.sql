-- Since per-game player statistics datasets contain many data categories and null values,
-- data cleaning is required for both large datasets before analysis

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

-- Create cleaned advanced player statistics table for 2025-26 season
CREATE TABLE IF NOT EXISTS nba_players_clean_2526
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
  CASE WHEN gameType = 'Regular Season' THEN 'Regular'
       WHEN gameType = 'Playoffs' THEN 'Playoffs'
       ELSE 'Other'
  END AS season_phase,
  win AS is_win,
  home AS is_home,
  CASE WHEN numMinutes IS NULL OR comment LIKE 'DNP%' THEN 0.0 ELSE numMinutes END AS minutes_played,
  points AS pts,
  assists AS ast,
  blocks AS blk,
  steals AS stl,
  reboundsTotal AS reb,
  reboundsOffensive AS oreb,
  reboundsDefensive AS dreb,
  fieldGoalsMade AS fgm,
  fieldGoalsAttempted AS fga,
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
  CASE WHEN fieldGoalsAttempted > 0
       THEN ROUND((fieldGoalsMade + 0.5 * threePointersMade) / fieldGoalsAttempted, 3)
       ELSE NULL
  END AS efg_pct,
  CASE WHEN fieldGoalsAttempted + freeThrowsAttempted > 0
       THEN ROUND(points / (2.0 * (fieldGoalsAttempted + 0.44 * freeThrowsAttempted)), 3)
       ELSE NULL
  END AS ts_pct,
  CASE WHEN (CASE WHEN numMinutes IS NULL OR comment LIKE 'DNP%' THEN 0.0 ELSE numMinutes END) > 0
       THEN ROUND((points + reboundsTotal + assists + steals + blocks - (fieldGoalsAttempted - fieldGoalsMade) - (freeThrowsAttempted - freeThrowsMade) - turnovers) / (CASE WHEN numMinutes IS NULL OR comment LIKE 'DNP%' THEN 0.0 ELSE numMinutes END), 2)
       ELSE NULL
  END AS gm_score_per_min,
  gameDate AS game_date
FROM nba_player_stats_2526;

-- Second data cleaning: clean team game data by removing symbols, standardizing labels,
-- then merge all four game log tables into one unified table
USE nba_db;

DROP TABLE IF EXISTS nba_team_games_clean;
CREATE TABLE nba_team_games_clean
STORED AS TEXTFILE
AS
SELECT
    '2024-25' AS season, 'Regular' AS game_type,
    team_abbreviation AS team, team_name AS team_name, game_date AS game_date,
    CASE WHEN matchup LIKE '%@%' THEN 'Away' ELSE 'Home' END AS location,
    CASE WHEN matchup LIKE '%@%' THEN CONCAT('vs. ', SUBSTR(matchup, 7)) 
         ELSE SUBSTR(matchup, 5) 
    END AS opponent,
    CASE WHEN wl = 'W' THEN 1 ELSE 0 END AS is_win,
    pts AS team_pts, fgm, fga,
    CASE WHEN fga > 0 THEN ROUND(fgm / fga, 3) ELSE NULL END AS fg_pct,
    fg3m, fg3a,
    CASE WHEN fg3a > 0 THEN ROUND(fg3m / fg3a, 3) ELSE NULL END AS fg3_pct,
    ftm, fta,
    CASE WHEN fta > 0 THEN ROUND(ftm / fta, 3) ELSE NULL END AS ft_pct,
    oreb, dreb, reb, ast, stl, blk, tov, pf, plus_minus
FROM nba_regular_team_games_2425
WHERE wl IS NOT NULL

UNION ALL

SELECT
    '2024-25', 'Playoffs',
    team_abbreviation, team_name, game_date,
    CASE WHEN matchup LIKE '%@%' THEN 'Away' ELSE 'Home' END,
    CASE WHEN matchup LIKE '%@%' THEN CONCAT('vs. ', SUBSTR(matchup, 7)) ELSE SUBSTR(matchup, 5) END,
    CASE WHEN wl = 'W' THEN 1 ELSE 0 END,
    pts, fgm, fga,
    CASE WHEN fga > 0 THEN ROUND(fgm / fga, 3) ELSE NULL END,
    fg3m, fg3a,
    CASE WHEN fg3a > 0 THEN ROUND(fg3m / fg3a, 3) ELSE NULL END,
    ftm, fta,
    CASE WHEN fta > 0 THEN ROUND(ftm / fta, 3) ELSE NULL END,
    oreb, dreb, reb, ast, stl, blk, tov, pf, plus_minus
FROM nba_playoffs_team_games_2425
WHERE wl IS NOT NULL

UNION ALL

SELECT
    '2025-26', 'Regular',
    team_abbreviation, team_name, game_date,
    CASE WHEN matchup LIKE '%@%' THEN 'Away' ELSE 'Home' END,
    CASE WHEN matchup LIKE '%@%' THEN CONCAT('vs. ', SUBSTR(matchup, 7)) ELSE SUBSTR(matchup, 5) END,
    CASE WHEN wl = 'W' THEN 1 ELSE 0 END,
    pts, fgm, fga,
    CASE WHEN fga > 0 THEN ROUND(fgm / fga, 3) ELSE NULL END,
    fg3m, fg3a,
    CASE WHEN fg3a > 0 THEN ROUND(fg3m / fg3a, 3) ELSE NULL END,
    ftm, fta,
    CASE WHEN fta > 0 THEN ROUND(ftm / fta, 3) ELSE NULL END,
    oreb, dreb, reb, ast, stl, blk, tov, pf, plus_minus
FROM nba_regular_team_games_2526
WHERE wl IS NOT NULL

UNION ALL

SELECT
    '2025-26', 'Playoffs',
    team_abbreviation, team_name, game_date,
    CASE WHEN matchup LIKE '%@%' THEN 'Away' ELSE 'Home' END,
    CASE WHEN matchup LIKE '%@%' THEN CONCAT('vs. ', SUBSTR(matchup, 7)) ELSE SUBSTR(matchup, 5) END,
    CASE WHEN wl = 'W' THEN 1 ELSE 0 END,
    pts, fgm, fga,
    CASE WHEN fga > 0 THEN ROUND(fgm / fga, 3) ELSE NULL END,
    fg3m, fg3a,
    CASE WHEN fg3a > 0 THEN ROUND(fg3m / fg3a, 3) ELSE NULL END,
    ftm, fta,
    CASE WHEN fta > 0 THEN ROUND(ftm / fta, 3) ELSE NULL END,
    oreb, dreb, reb, ast, stl, blk, tov, pf, plus_minus
FROM nba_playoffs_team_games_2526
WHERE wl IS NOT NULL;

-- Validation query
SELECT season, game_type, team, location, opponent, is_win FROM nba_team_games_clean LIMIT 5;

USE nba_db;

SELECT
    season AS season,
    game_date AS game_date,
    game_type AS game_type,
    team AS team,
    location AS location,
    opponent AS opponent,
    team_pts AS pts,
    fg3m AS fg3m,
    fg3a AS fg3a,
    fg3_pct AS fg3_pct,
    plus_minus AS plus_minus
FROM nba_team_games_clean
WHERE team_pts >= 140 OR fg3m >= 20  -- Filter: Points >= 140 or 3PM >= 20
ORDER BY team_pts DESC
LIMIT 10;

-- Preliminary computation and aggregation on cleaned tables
-- The core tables are the following three:
-- nba_team_games_clean;
-- nba_players_clean_2425;
-- nba_players_clean_2526

-- Create Unified View for Players (Merging Both Seasons)
CREATE VIEW IF NOT EXISTS nba_players_all AS
SELECT '2024-25' AS season, * FROM nba_players_clean_2425
UNION ALL
SELECT '2025-26' AS season, * FROM nba_players_clean_2526;

-- Create Team-Level Season Summary Table (Granularity: Team + Season + Stage)
CREATE TABLE IF NOT EXISTS nba_team_season_summary
STORED AS TEXTFILE
AS
SELECT
  season,
  CASE WHEN game_type = 'Regular' THEN 'Regular Season' 
       WHEN game_type = 'Playoffs' THEN 'Playoffs' 
       ELSE game_type 
  END AS game_type,
  team_name,
  COUNT(*) AS games_played,
  ROUND(AVG(team_pts), 1) AS avg_pts,
  ROUND(AVG(AST), 1) AS avg_ast,
  ROUND(AVG(REB), 1) AS avg_reb,
  ROUND(AVG(PLUS_MINUS), 1) AS avg_plus_minus
FROM nba_team_games_clean
GROUP BY season, game_type, team_name;

-- Create Player-Level Season Summary Table (Granularity: Player + Season + Stage)
CREATE TABLE IF NOT EXISTS nba_player_season_summary
STORED AS TEXTFILE
AS
SELECT
  season, fullName, team_name, game_type,
  COUNT(*) AS games_played,
  ROUND(AVG(minutes_played), 1) AS avg_min,
  ROUND(AVG(pts), 1) AS avg_pts,
  ROUND(AVG(ast), 1) AS avg_ast,
  ROUND(AVG(reb), 1) AS avg_reb,
  ROUND(AVG(stl), 1) AS avg_stl,
  ROUND(AVG(blk), 1) AS avg_blk,
  ROUND(AVG(plus_minus), 1) AS avg_plus_minus,
  ROUND(SUM(pts), 0) AS total_pts,
  ROUND(SUM(ast), 0) AS total_ast,
  ROUND(SUM(reb), 0) AS total_reb,
  ROUND(SUM(fgm) / SUM(fga), 3) AS season_fg_pct,
  ROUND(SUM(fg3m) / SUM(fg3a), 3) AS season_fg3_pct,
  ROUND(SUM(ftm) / SUM(fta), 3) AS season_ft_pct,
  ROUND(SUM(fg3a), 0) AS total_fg3a,
  ROUND(SUM(fga), 0) AS total_fga
FROM nba_players_all
WHERE minutes_played > 0
GROUP BY season, fullName, team_name, game_type;
