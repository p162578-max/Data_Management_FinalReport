-- Players-Centric Analytics

-- 01 Total Points Leaders TOP 20
SELECT fullName, team_name, games_played, total_pts, avg_pts, avg_ast, avg_reb
FROM nba_player_season_summary
WHERE season = '2025-26' AND game_type = 'Regular Season' AND games_played >= 20
ORDER BY total_pts DESC LIMIT 20;

-- 02 Scoring Leaders by AVG TOP 20
SELECT fullName, team_name, games_played, avg_pts, avg_ast, avg_reb, avg_min
FROM nba_player_season_summary
WHERE season = '2025-26' AND game_type = 'Regular Season' AND games_played >= 30
ORDER BY avg_pts DESC LIMIT 20;

-- 03 Regular Season vs Playoffs Differential
SELECT a.fullName, a.team_name, a.avg_pts AS reg_pts, b.avg_pts AS playoff_pts,
  ROUND(b.avg_pts - a.avg_pts, 1) AS pts_diff, a.avg_min AS reg_min, b.avg_min AS playoff_min
FROM nba_player_season_summary a
JOIN nba_player_season_summary b ON a.fullName = b.fullName AND a.team_name = b.team_name
WHERE a.season = '2025-26' 
  AND b.season = '2025-26'
  AND a.game_type = 'Regular Season' 
  AND b.game_type = 'Playoffs'
  AND a.games_played >= 30 
  AND b.games_played >= 3
ORDER BY pts_diff DESC 
LIMIT 15;

-- 04 MIP Year-over-Year Growth Tracker
SELECT a.fullName, a.team_name AS team_2425, b.team_name AS team_2526,
  a.avg_pts AS pts_2425, b.avg_pts AS pts_2526, ROUND(b.avg_pts - a.avg_pts, 1) AS improvement     
FROM nba_player_season_summary a
JOIN nba_player_season_summary b ON a.fullName = b.fullName
WHERE a.season = '2024-25' 
  AND b.season = '2025-26'
  AND a.game_type = 'Regular Season' 
  AND b.game_type = 'Regular Season'
  AND a.games_played >= 30 
  AND b.games_played >= 30
ORDER BY improvement DESC 
LIMIT 15;

-- 05 All-Around Leaders TOP 20
SELECT fullName, team_name, avg_pts, avg_reb, avg_ast,
       ROUND(avg_pts + avg_reb + avg_ast, 1) AS pts_reb_ast
FROM nba_player_season_summary
WHERE season = '2025-26' 
  AND game_type = 'Regular Season' 
  AND games_played >= 30
ORDER BY pts_reb_ast DESC LIMIT 20;

-- 06 Postseason MVP Candidates Tracker
SELECT fullName, team_name, games_played, avg_pts, avg_reb, avg_ast, avg_plus_minus
FROM nba_player_season_summary
WHERE season = '2025-26' 
  AND game_type = 'Playoffs' 
  AND games_played >= 5
ORDER BY avg_pts DESC 
LIMIT 10;

-- 07 Three-Point Precision Shooting Ranking
SELECT fullName, team_name, season_fg3_pct, total_fg3a, total_pts
FROM nba_player_season_summary
WHERE season = '2025-26' 
  AND game_type = 'Regular Season' 
  AND total_fg3a >= 100
ORDER BY season_fg3_pct DESC 
LIMIT 20;


-- 08 Individual Average Plus-Minus Leaders
SELECT fullName, team_name, avg_plus_minus, avg_pts, games_played
FROM nba_player_season_summary
WHERE season = '2025-26' AND game_type = 'Regular Season' AND games_played >= 30
ORDER BY avg_plus_minus DESC LIMIT 15;

-- 09 The five best players of each team this season
SELECT t.team_name, t.fullName, t.games_played, t.avg_pts, t.avg_ast, t.avg_reb
FROM (
  SELECT team_name, fullName, games_played, avg_pts, avg_ast, avg_reb,
         ROW_NUMBER() OVER (PARTITION BY team_name ORDER BY avg_pts DESC) AS rnk
  FROM nba_player_season_summary
  WHERE team_name = 'Lakers'
  AND season = '2025-26' 
  AND game_type = 'Regular Season'
  AND games_played >= 20
) t
WHERE t.rnk <= 5;

-- 10 Comparison of the top 4 scorers
WITH all_player_scoring AS (
  SELECT fullName, team_name, season, game_type,
         ROUND(SUM(pts), 0) AS total_pts,
         ROUND(SUM(fg3m) * 3, 0) AS total_fg3_pts,
         ROUND(SUM(ftm) * 1, 0) AS total_ft_pts,
         ROUND((SUM(fgm) - SUM(fg3m)) * 2, 0) AS total_fg2_pts
  FROM nba_players_all
  WHERE minutes_played > 0 
    AND season = '2025-26' 
    AND game_type = 'Regular Season'
  GROUP BY fullName, team_name, season, game_type
)
SELECT 
  fullName, 
  team_name,
  season,
  game_type,
  total_pts, 
  ROUND((total_fg2_pts / total_pts) * 100, 1) AS pct_2pt_score,
  ROUND((total_fg3_pts / total_pts) * 100, 1) AS pct_3pt_score,
  ROUND((total_ft_pts / total_pts) * 100, 1) AS pct_ft_score
FROM all_player_scoring
WHERE total_pts > 0
ORDER BY total_pts DESC 
LIMIT 4;


-- Team-Centric Analytics

-- 01 Team Offensive Rankings with FG Details
SELECT team, team_name, COUNT(*) AS games_played,
    ROUND(AVG(team_pts), 1) AS avg_pts_scored, 
	ROUND(AVG(fgm), 1) AS avg_fg_made,
    ROUND(AVG(fg3m), 1) AS avg_3pm_made, 
	ROUND(AVG(reb), 1) AS avg_rebounds, 
	ROUND(AVG(ast), 1) AS avg_assists
FROM nba_team_games_clean
WHERE season = '2025-26' 
  AND game_type = 'Regular'
GROUP BY team, team_name 
ORDER BY avg_pts_scored DESC 
LIMIT 15;

-- 02 Home vs Away Strategic Split
SELECT season, CASE WHEN game_type = 'Regular' THEN 'Regular Season' WHEN game_type = 'Playoffs' THEN 'Playoffs' ELSE game_type END AS stage,
    location, COUNT(*) AS total_games, 
	ROUND(AVG(is_win) * 100, 1) AS win_percentage,
    ROUND(AVG(team_pts), 1) AS avg_pts_scored, 
	ROUND(AVG(plus_minus), 1) AS avg_net_margin
FROM nba_team_games_clean
GROUP BY season, CASE WHEN game_type = 'Regular' THEN 'Regular Season' 
WHEN game_type = 'Playoffs' THEN 'Playoffs' ELSE game_type END, location
ORDER BY season, stage, location;


-- 03 Team Offensive Rankings with FG Details (Take the Thunder as an example)
SELECT opponent, COUNT(*) AS total_matchups, SUM(is_win) AS total_wins,
    COUNT(*) - SUM(is_win) AS total_losses, ROUND(AVG(is_win) * 100, 1) AS matchup_win_percentage
FROM nba_team_games_clean
WHERE team = 'OKC' AND season = '2025-26' AND game_type = 'Regular'
GROUP BY opponent ORDER BY matchup_win_percentage DESC, total_matchups DESC;

-- 04 Postseason Playoff Team Offensive Rankings
SELECT team, team_name, 
	COUNT(*) AS playoff_games_played,
    ROUND(AVG(team_pts), 1) AS playoff_avg_pts, 
	ROUND(AVG(ast), 1) AS playoff_avg_ast, 
	ROUND(AVG(reb), 1) AS playoff_avg_reb
FROM nba_team_games_clean
WHERE season = '2025-26' 
  AND game_type = 'Playoffs'
GROUP BY team, team_name 
ORDER BY playoff_avg_pts DESC;

-- 05 Defensive and Net Margin Elite Tier Rankings
SELECT team, team_name, 
	ROUND(AVG(plus_minus), 1) AS avg_net_margin,
    ROUND(AVG(is_win) * 100, 1) AS season_win_percentage, 
	ROUND(AVG(team_pts), 1) AS avg_points_scored
FROM nba_team_games_clean
WHERE season = '2025-26' 
  AND game_type = 'Regular'
GROUP BY team, team_name 
ORDER BY avg_net_margin DESC
LIMIT 15;


-- 06 Maximum Team Single-Game Scoring Milestones
SELECT team, team_name, game_type, game_date, team_pts AS single_game_points,
    fgm AS field_goals_made, 
	fg3m AS three_pointers_made, 
	ast AS total_assists, 
	plus_minus AS point_differential
FROM nba_team_games_clean
WHERE season = '2025-26'
ORDER BY single_game_points DESC 
LIMIT 10;
