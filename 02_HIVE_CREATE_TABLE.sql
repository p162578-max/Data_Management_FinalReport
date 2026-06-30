-- Create and enter the final project database
CREATE DATABASE IF NOT EXISTS nba_db;
USE nba_db;

-- Set Hive dynamic partition compatibility mode
SET hive.exec.dynamic.partition = true;
SET hive.exec.dynamic.partition.mode = nonstrict;
SET hive.mapred.mode = nonstrict;

-- Player per-game statistics (imported from player_statistics table)
-- Create 2024-25 season external table
CREATE EXTERNAL TABLE IF NOT EXISTS nba_player_stats_2425 (
    firstName        STRING,
    lastName         STRING,
    personId         BIGINT,
    gameId           BIGINT,
    gameDateTimeEst  STRING,
    playerteamCity   STRING,
    playerteamName   STRING,
    opponentteamCity STRING,
    opponentteamName STRING,
    gameType         STRING,
    gameLabel        STRING,
    gameSubLabel     STRING,
    seriesGameNumber INT,
    win              INT,
    home             INT,
    numMinutes       FLOAT,
    points           INT,
    assists          INT,
    blocks           INT,
    steals           INT,
    fieldGoalsAttempted  INT,
    fieldGoalsMade       INT,
    fieldGoalsPercentage FLOAT,
    threePointersAttempted  INT,
    threePointersMade       INT,
    threePointersPercentage FLOAT,
    freeThrowsAttempted  INT,
    freeThrowsMade       INT,
    freeThrowsPercentage FLOAT,
    reboundsDefensive    INT,
    reboundsOffensive    INT,
    reboundsTotal        INT,
    foulsPersonal        INT,
    turnovers            INT,
    plusMinusPoints      INT,
    playerteamId         BIGINT,
    opponentteamId       BIGINT,
    comment              STRING,
    startingPosition     STRING,
    gameDate             STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' STORED AS TEXTFILE
LOCATION '/nba_data/nba_2024-25_player_statistics'
TBLPROPERTIES ("skip.header.line.count"="0");

-- Create 2025-26 season external table
CREATE EXTERNAL TABLE IF NOT EXISTS nba_player_stats_2526 (
    firstName        STRING,
    lastName         STRING,
    personId         BIGINT,
    gameId           BIGINT,
    gameDateTimeEst  STRING,
    playerteamCity   STRING,
    playerteamName   STRING,
    opponentteamCity STRING,
    opponentteamName STRING,
    gameType         STRING,
    gameLabel        STRING,
    gameSubLabel     STRING,
    seriesGameNumber INT,
    win              INT,
    home             INT,
    numMinutes       FLOAT,
    points           INT,
    assists          INT,
    blocks           INT,
    steals           INT,
    fieldGoalsAttempted  INT,
    fieldGoalsMade       INT,
    fieldGoalsPercentage FLOAT,
    threePointersAttempted  INT,
    threePointersMade       INT,
    threePointersPercentage FLOAT,
    freeThrowsAttempted  INT,
    freeThrowsMade       INT,
    freeThrowsPercentage FLOAT,
    reboundsDefensive    INT,
    reboundsOffensive    INT,
    reboundsTotal        INT,
    foulsPersonal        INT,
    turnovers            INT,
    plusMinusPoints      INT,
    playerteamId         BIGINT,
    opponentteamId       BIGINT,
    comment              STRING,
    startingPosition     STRING,
    gameDate             STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' STORED AS TEXTFILE
LOCATION '/nba_data/nba_2025-26_player_statistics'
TBLPROPERTIES ("skip.header.line.count"="0");


-- 2024-25 season playoffs player statistics table
DROP TABLE IF EXISTS nba_playoffs_players_2425;
CREATE EXTERNAL TABLE IF NOT EXISTS nba_playoffs_players_2425 (
    player STRING,
    age DOUBLE,
    team STRING,
    pos STRING,
    g DOUBLE,
    gs DOUBLE,
    mp DOUBLE,
    fg DOUBLE,
    fga DOUBLE,
    fg_pct DOUBLE,
    three_p DOUBLE,
    three_pa DOUBLE,
    three_p_pct DOUBLE,
    two_p DOUBLE,
    two_pa DOUBLE,
    two_p_pct DOUBLE,
    efg_pct DOUBLE,
    ft DOUBLE,
    fta DOUBLE,
    ft_pct DOUBLE,
    orb DOUBLE,
    drb DOUBLE,
    trb DOUBLE,
    ast DOUBLE,
    stl DOUBLE,
    blk DOUBLE,
    tov DOUBLE,
    pf DOUBLE,
    pts DOUBLE
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' STORED AS TEXTFILE
LOCATION '/nba_data/nba_2024-25_playoffs_players'
TBLPROPERTIES ("skip.header.line.count"="0");

-- 2025-26 season playoffs player statistics table
DROP TABLE IF EXISTS nba_playoffs_players_2526;
CREATE EXTERNAL TABLE IF NOT EXISTS nba_playoffs_players_2526 (
    player STRING,
    age DOUBLE,
    team STRING,
    pos STRING,
    g DOUBLE,
    gs DOUBLE,
    mp DOUBLE,
    fg DOUBLE,
    fga DOUBLE,
    fg_pct DOUBLE,
    three_p DOUBLE,
    three_pa DOUBLE,
    three_p_pct DOUBLE,
    two_p DOUBLE,
    two_pa DOUBLE,
    two_p_pct DOUBLE,
    efg_pct DOUBLE,
    ft DOUBLE,
    fta DOUBLE,
    ft_pct DOUBLE,
    orb DOUBLE,
    drb DOUBLE,
    trb DOUBLE,
    ast DOUBLE,
    stl DOUBLE,
    blk DOUBLE,
    tov DOUBLE,
    pf DOUBLE,
    pts DOUBLE
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' STORED AS TEXTFILE
LOCATION '/nba_data/nba_2025-26_playoffs_players'
TBLPROPERTIES ("skip.header.line.count"="0");

-- 2024-25 season regular season player statistics table
DROP TABLE IF EXISTS nba_regular_players_2425;
CREATE EXTERNAL TABLE IF NOT EXISTS nba_regular_players_2425 (
    player STRING,
    age DOUBLE,
    team STRING,
    pos STRING,
    g DOUBLE,
    gs DOUBLE,
    mp DOUBLE,
    fg DOUBLE,
    fga DOUBLE,
    fg_pct DOUBLE,
    three_p DOUBLE,
    three_pa DOUBLE,
    three_p_pct DOUBLE,
    two_p DOUBLE,
    two_pa DOUBLE,
    two_p_pct DOUBLE,
    efg_pct DOUBLE,
    ft DOUBLE,
    fta DOUBLE,
    ft_pct DOUBLE,
    orb DOUBLE,
    drb DOUBLE,
    trb DOUBLE,
    ast DOUBLE,
    stl DOUBLE,
    blk DOUBLE,
    tov DOUBLE,
    pf DOUBLE,
    pts DOUBLE
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' STORED AS TEXTFILE
LOCATION '/nba_data/nba_2024-25_regular_players'
TBLPROPERTIES ("skip.header.line.count"="0");

-- 2025-26 season regular season player statistics table
DROP TABLE IF EXISTS nba_regular_players_2526;
CREATE EXTERNAL TABLE IF NOT EXISTS nba_regular_players_2526 (
    player STRING,
    age DOUBLE,
    team STRING,
    pos STRING,
    g DOUBLE,
    gs DOUBLE,
    mp DOUBLE,
    fg DOUBLE,
    fga DOUBLE,
    fg_pct DOUBLE,
    three_p DOUBLE,
    three_pa DOUBLE,
    three_p_pct DOUBLE,
    two_p DOUBLE,
    two_pa DOUBLE,
    two_p_pct DOUBLE,
    efg_pct DOUBLE,
    ft DOUBLE,
    fta DOUBLE,
    ft_pct DOUBLE,
    orb DOUBLE,
    drb DOUBLE,
    trb DOUBLE,
    ast DOUBLE,
    stl DOUBLE,
    blk DOUBLE,
    tov DOUBLE,
    pf DOUBLE,
    pts DOUBLE
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' STORED AS TEXTFILE
LOCATION '/nba_data/nba_2025-26_regular_players'
TBLPROPERTIES ("skip.header.line.count"="0");


-- 2024-25 season playoffs team per-game table
DROP TABLE IF EXISTS nba_playoffs_team_games_2425;
CREATE EXTERNAL TABLE IF NOT EXISTS nba_playoffs_team_games_2425 (
    season_id INT,
    team_id BIGINT,
    team_abbreviation STRING,
    team_name STRING,
    game_id STRING,
    game_date STRING,
    matchup STRING,
    wl STRING,
    min INT,
    pts INT,
    fgm INT,
    fga INT,
    fg_pct DOUBLE,
    fg3m INT,
    fg3a INT,
    fg3_pct DOUBLE,
    ftm INT,
    fta INT,
    ft_pct DOUBLE,
    oreb INT,
    dreb INT,
    reb INT,
    ast INT,
    stl INT,
    blk INT,
    tov INT,
    pf INT,
    plus_minus DOUBLE
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' STORED AS TEXTFILE
LOCATION '/nba_data/nba_2024-25_playoffs_team_games'
TBLPROPERTIES ("skip.header.line.count"="0");


-- 2025-26 season playoffs team per-game table
DROP TABLE IF EXISTS nba_playoffs_team_games_2526;
CREATE EXTERNAL TABLE IF NOT EXISTS nba_playoffs_team_games_2526 (
    season_id INT,
    team_id BIGINT,
    team_abbreviation STRING,
    team_name STRING,
    game_id STRING,
    game_date STRING,
    matchup STRING,
    wl STRING,
    min INT,
    pts INT,
    fgm INT,
    fga INT,
    fg_pct DOUBLE,
    fg3m INT,
    fg3a INT,
    fg3_pct DOUBLE,
    ftm INT,
    fta INT,
    ft_pct DOUBLE,
    oreb INT,
    dreb INT,
    reb INT,
    ast INT,
    stl INT,
    blk INT,
    tov INT,
    pf INT,
    plus_minus DOUBLE
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' STORED AS TEXTFILE
LOCATION '/nba_data/nba_2025-26_playoffs_team_games'
TBLPROPERTIES ("skip.header.line.count"="0");


-- 2024-25 season regular season team per-game table
DROP TABLE IF EXISTS nba_regular_team_games_2425;
CREATE EXTERNAL TABLE IF NOT EXISTS nba_regular_team_games_2425 (
    season_id INT,
    team_id BIGINT,
    team_abbreviation STRING,
    team_name STRING,
    game_id STRING,
    game_date STRING,
    matchup STRING,
    wl STRING,
    min INT,
    pts INT,
    fgm INT,
    fga INT,
    fg_pct DOUBLE,
    fg3m INT,
    fg3a INT,
    fg3_pct DOUBLE,
    ftm INT,
    fta INT,
    ft_pct DOUBLE,
    oreb INT,
    dreb INT,
    reb INT,
    ast INT,
    stl INT,
    blk INT,
    tov INT,
    pf INT,
    plus_minus DOUBLE
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' STORED AS TEXTFILE
LOCATION '/nba_data/nba_2024-25_regular_team_games'
TBLPROPERTIES ("skip.header.line.count"="0");

-- 2025-26 season regular season team per-game table
DROP TABLE IF EXISTS nba_regular_team_games_2526;
CREATE EXTERNAL TABLE IF NOT EXISTS nba_regular_team_games_2526 (
    season_id INT,
    team_id BIGINT,
    team_abbreviation STRING,
    team_name STRING,
    game_id STRING,
    game_date STRING,
    matchup STRING,
    wl STRING,
    min INT,
    pts INT,
    fgm INT,
    fga INT,
    fg_pct DOUBLE,
    fg3m INT,
    fg3a INT,
    fg3_pct DOUBLE,
    ftm INT,
    fta INT,
    ft_pct DOUBLE,
    oreb INT,
    dreb INT,
    reb INT,
    ast INT,
    stl INT,
    blk INT,
    tov INT,
    pf INT,
    plus_minus DOUBLE
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' STORED AS TEXTFILE
LOCATION '/nba_data/nba_2025-26_regular_team_games'
TBLPROPERTIES ("skip.header.line.count"="0");
