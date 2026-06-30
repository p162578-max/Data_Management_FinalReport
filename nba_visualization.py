
# NBA Data Visualization — Hive Direct Connection Version.

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib
import seaborn as sns
import os, warnings
warnings.filterwarnings('ignore')

# Configuration
HIVE_HOST = '127.0.0.1'   # ← Change to your VM IP address
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

#  Top Scorers TOP 20 
print('Top Scorers')
df = query("""
    SELECT fullName, team_name,
           ROUND(AVG(pts),1) AS avg_pts,
           ROUND(AVG(ast),1) AS avg_ast,
           ROUND(AVG(reb),1) AS avg_reb,
           ROUND(AVG(plus_minus),1) AS avg_pm,
           COUNT(*) AS gp
    FROM nba_players_clean_2526
    WHERE game_type = 'Regular Season' AND minutes_played > 10
    GROUP BY fullName, team_name
    HAVING gp >= 30
    ORDER BY avg_pts DESC
    LIMIT 20
""")
fig, ax = plt.subplots(figsize=(12, 8))
colors = sns.color_palette('OrRd_r', len(df))
ax.barh(range(len(df)), df['avg_pts'], color=colors[::-1])
ax.set_yticks(range(len(df)))
ax.set_yticklabels([f'{n} ({t})' for n, t in zip(df['fullname'], df['team_name'])])
ax.set_xlabel('PPG (Points Per Game)')
ax.set_title('2025-26 NBA Top 20 Scorers', fontsize=16, fontweight='bold')
for i, (v, a, r) in enumerate(zip(df['avg_pts'], df['avg_ast'], df['avg_reb'])):
    ax.text(v+0.3, i, f'{v:.1f} pts | {a:.1f} ast | {r:.1f} reb', va='center', fontsize=8)
ax.invert_yaxis()
sns.despine()
plt.tight_layout()
save_chart(fig, '01_top_scorers.png')
plt.close()

# Team Scoring Rankings
print('Team Scoring')
df = query("""
    SELECT team_name, ROUND(AVG(team_pts),1) AS avg_pts,
           ROUND(AVG(is_win)*100,1) AS win_pct
    FROM nba_team_games_clean
    WHERE season = '2025-26' AND game_type = 'Regular'
    GROUP BY team_name
    ORDER BY avg_pts DESC
""")
fig, ax = plt.subplots(figsize=(14, 8))
colors_bar = ['#e74c3c' if wp >= 60 else ('#f39c12' if wp >= 45 else '#95a5a6') for wp in df['win_pct']]
bars = ax.bar(df['team_name'], df['avg_pts'], color=colors_bar, edgecolor='white')
ax.set_xlabel('Teams')
ax.set_ylabel('Points Per Game')
ax.set_title('2025-26 NBA Team Offensive Power Rankings', fontsize=16, fontweight='bold')
ax.set_xticklabels(df['team_name'], rotation=45, ha='right')
for bar, pts, wp in zip(bars, df['avg_pts'], df['win_pct']):
    ax.text(bar.get_x()+bar.get_width()/2, bar.get_height()+0.5, f'{pts}', ha='center', fontsize=8)
    ax.text(bar.get_x()+bar.get_width()/2, bar.get_height()-3, f'{wp}%', ha='center', fontsize=7, color='white', fontweight='bold')
plt.tight_layout()
save_chart(fig, '02_team_scoring.png')
plt.close()

# Regular Season vs Playoffs
print('Regular vs Playoffs')
df = query("""
    SELECT a.fullName AS fullname, a.team_name AS team_name,
           ROUND(a.avg_pts,1) AS reg_pts,
           ROUND(b.avg_pts,1) AS playoff_pts
    FROM
      (SELECT fullName, team_name, AVG(pts) AS avg_pts
       FROM nba_players_clean_2526
       WHERE game_type='Regular Season' AND minutes_played>10
       GROUP BY fullName, team_name HAVING COUNT(*)>=30) a
    JOIN
      (SELECT fullName, AVG(pts) AS avg_pts
       FROM nba_players_clean_2526
       WHERE game_type='Playoffs' AND minutes_played>10
       GROUP BY fullName HAVING COUNT(*)>=3) b
       ON a.fullName=b.fullName
    ORDER BY playoff_pts DESC
    LIMIT 15
""")
fig, ax = plt.subplots(figsize=(12, 7))
x = range(len(df))
ax.bar([i-0.175 for i in x], df['reg_pts'], 0.35, label='Regular Season', color='#3498db')
ax.bar([i+0.175 for i in x], df['playoff_pts'], 0.35, label='Playoffs', color='#e74c3c')
ax.set_xticks(x)
ax.set_xticklabels([f'{n}\n({t})' for n, t in zip(df['fullname'], df['team_name'])], fontsize=8,rotation=45,    # 旋转45度
    ha='right')
ax.set_ylabel('Points Per Game')
ax.set_title('2025-26 Regular Season vs Playoffs PPG Comparison', fontsize=14, fontweight='bold')
ax.legend()
plt.tight_layout()
save_chart(fig, '03_reg_vs_playoffs.png')
plt.close()

#  Cross-Season Improvement
print('Season Improvement')
df = query("""
    SELECT a.fullName AS fullname,
           ROUND(a.avg_pts,1) AS pts_2425,
           ROUND(b.avg_pts,1) AS pts_2526
    FROM
      (SELECT fullName, AVG(pts) AS avg_pts FROM nba_players_clean_2425
       WHERE game_type='Regular Season' AND minutes_played>10
       GROUP BY fullName HAVING COUNT(*)>=30) a
    JOIN
      (SELECT fullName, AVG(pts) AS avg_pts FROM nba_players_clean_2526
       WHERE game_type='Regular Season' AND minutes_played>10
       GROUP BY fullName HAVING COUNT(*)>=30) b
       ON a.fullName=b.fullName
    ORDER BY (pts_2526 - pts_2425) DESC
    LIMIT 15
""")
df['improvement'] = df['pts_2526'] - df['pts_2425']
fig, ax = plt.subplots(figsize=(12, 7))
x = range(len(df))
ax.bar([i-0.175 for i in x], df['pts_2425'], 0.35, label='2024-25', color='#95a5a6')
ax.bar([i+0.175 for i in x], df['pts_2526'], 0.35, label='2025-26', color='#2ecc71')
ax.set_xticks(x) 
ax.set_xticklabels(df['fullname'], rotation=30, ha='right', fontsize=9)
ax.set_ylabel('Points Per Game')
ax.set_title('Most Improved Players (Points Per Game)', fontsize=14, fontweight='bold')
ax.legend()
for i, imp in enumerate(df['improvement']):
    ax.annotate(f'+{imp:.1f}', xy=(i, max(df['pts_2425'].iloc[i], df['pts_2526'].iloc[i])+1), ha='center', fontsize=9, color='#27ae60', fontweight='bold')
plt.tight_layout()
save_chart(fig, '04_improvement.png')
plt.close()

# Scoring vs Efficiency Scatter Plot
print('Scoring vs Efficiency')
df = query("""
    SELECT fullName, team_name,
           ROUND(AVG(pts),1) AS avg_pts,
           ROUND(AVG(ts_pct),3) AS avg_ts,
           ROUND(AVG(plus_minus),1) AS avg_pm,
           COUNT(*) AS gp
    FROM nba_players_clean_2526
    WHERE game_type='Regular Season' AND minutes_played > 15
    GROUP BY fullName, team_name
    HAVING gp >= 30
""")
fig, ax = plt.subplots(figsize=(12, 8))
sc = ax.scatter(df['avg_pts'], df['avg_ts'], c=df['avg_pm'], s=df['gp']*3, cmap='RdYlGn', alpha=0.7, edgecolors='gray', linewidth=0.5)
plt.colorbar(sc, ax=ax).set_label('Average Plus/Minus Value')
for _, row in df.sort_values('avg_pts', ascending=False).head(15).iterrows():
    ax.annotate(row['fullname'], (row['avg_pts'], row['avg_ts']), fontsize=7, alpha=0.8)
ax.set_xlabel('Points Per Game')
ax.set_ylabel('True Shooting Percentage (TS%)')
ax.set_title('Scoring Volume vs Efficiency (Bubble Size = Games Played)', fontsize=14, fontweight='bold')
plt.tight_layout()
save_chart(fig, '05_efficiency.png')
plt.close()

# All-Around Box Score Leaders
print('All-Around Players')
df = query("""
    SELECT fullName, team_name,
           ROUND(AVG(pts),1) AS avg_pts,
           ROUND(AVG(reb),1) AS avg_reb,
           ROUND(AVG(ast),1) AS avg_ast
    FROM nba_players_clean_2526
    WHERE game_type='Regular Season' AND minutes_played>15
    GROUP BY fullName, team_name
    HAVING COUNT(*)>=30
    ORDER BY (avg_pts+avg_reb+avg_ast) DESC
    LIMIT 20
""")
df['total'] = df['avg_pts'] + df['avg_reb'] + df['avg_ast']
fig, ax = plt.subplots(figsize=(12, 8))
ax.barh(range(len(df)), df['avg_pts'], color='#e74c3c', label='Points')
ax.barh(range(len(df)), df['avg_reb'], color='#f39c12', label='Rebounds', left=df['avg_pts'])
ax.barh(range(len(df)), df['avg_ast'], color='#2ecc71', label='Assists', left=df['avg_pts']+df['avg_reb'])
ax.set_yticks(range(len(df)))
ax.set_yticklabels([f'{n} ({t})' for n, t in zip(df['fullname'], df['team_name'])])
ax.set_xlabel('Total Statistics Combined')
ax.set_title('All-Around Leaders (PTS + REB + AST)', fontsize=14, fontweight='bold')
for i, t in enumerate(df['total']):
    ax.text(t+0.5, i, f'{t:.1f}', va='center', fontsize=8, fontweight='bold')
ax.legend(loc='lower right')
ax.invert_yaxis()
plt.tight_layout()
save_chart(fig, '06_all_around.png')
plt.close()

# Home vs Away Advantage
print('Plotting Team Home vs Away Advantage ...')
df = query("""
    SELECT CASE WHEN location='Home' THEN 'Home' ELSE 'Away' END AS location,
           COUNT(*) AS games,
           ROUND(AVG(is_win)*100,1) AS win_pct,
           ROUND(AVG(team_pts),1) AS avg_pts 
    FROM nba_team_games_clean
    WHERE season='2025-26' AND game_type='Regular'
    GROUP BY location
    ORDER BY location DESC
""")
df.columns = df.columns.str.lower()

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 5))
colors_pie = ["#ec29f3", "#269add"]

ax1.pie(df['games'], labels=df['location'], autopct='%1.1f%%', colors=colors_pie, startangle=90)
ax1.set_title('Game Distribution')

ax2.bar(df['location'], df['win_pct'], color=colors_pie, edgecolor='white', width=0.5)
ax2.set_ylabel('Win Percentage (%)')
ax2.set_title('Home vs Away Win Rate')
ax2.set_ylim(0, 110)

for _, row in df.iterrows():
    ax2.text(row['location'], row['win_pct'] + 2, f"{row['win_pct']}%\n{row['avg_pts']} pts", 
             ha='center', fontsize=11, fontweight='bold')

plt.suptitle('2025-26 Home Court Advantage Analysis', fontsize=14, fontweight='bold')
plt.tight_layout()
save_chart(fig, '07_home_away.png')
plt.close()

# 3PT Shooting Accuracy TOP
print('3PT Leaders...')
df = query("""
    SELECT fullName, team_name,
           ROUND(SUM(fg3m)/SUM(fg3a),3) AS fg3_pct,
           ROUND(SUM(fg3a),0) AS total_3pa,
           ROUND(SUM(pts),0) AS total_pts
    FROM nba_players_clean_2526
    WHERE game_type='Regular Season' AND minutes_played>10
    GROUP BY fullName, team_name
    HAVING SUM(fg3a) >= 100
    ORDER BY fg3_pct DESC
    LIMIT 15
""")
fig, ax = plt.subplots(figsize=(12, 7))
bars = ax.barh(range(len(df)), df['fg3_pct'], color=sns.color_palette('Blues_r', len(df)))
ax.set_yticks(range(len(df)))
ax.set_yticklabels([f'{n} ({t})' for n, t in zip(df['fullname'], df['team_name'])])
ax.set_xlabel('3PT Field Goal Percentage (3P%)')
ax.set_title('2025-26 3PT Accuracy Leaders (Min. 100 Attempts)', fontsize=14, fontweight='bold')
for i, (pct, pa) in enumerate(zip(df['fg3_pct'], df['total_3pa'])):
    ax.text(pct+0.005, i, f'{pct:.3f} ({int(pa)} 3PA)', va='center', fontsize=9, fontweight='bold')
ax.invert_yaxis()
ax.set_xlim(0, 0.7)
plt.tight_layout()
save_chart(fig, '08_three_pointers.png')
plt.close()

# Multi-Dimensional Player Comparison
print('Star Player Radar Chart Comparison')
df_radar = query("""
    SELECT fullName,
           ROUND(AVG(pts),1) AS avg_pts,
           ROUND(AVG(ast),1) AS avg_ast,
           ROUND(AVG(reb),1) AS avg_reb,
           ROUND(AVG(stl),1) AS avg_stl,
           ROUND(AVG(blk),1) AS avg_blk,
           ROUND(AVG(fg_pct),3) AS fg_pct,
           ROUND(AVG(fg3_pct),3) AS fg3_pct,
           ROUND(AVG(plus_minus),1) AS avg_pm,
           COUNT(*) AS gp
    FROM nba_players_clean_2526
    WHERE game_type='Regular Season' AND minutes_played>15
    GROUP BY fullName
    HAVING gp >= 20
""")

# Filter target star players
star_names = ['Gilgeous-Alexander', 'Doncic']
df_stars = df_radar[df_radar['fullname'].str.contains('|'.join(star_names), case=False, na=False)]
print(f'Found {len(df_stars)} star players')

# Select 6 metrics for the radar chart
metrics = ['avg_pts', 'avg_ast', 'avg_reb', 'avg_stl', 'avg_blk', 'avg_pm']
metrics_label = ['PTS', 'AST', 'REB', 'STL', 'BLK', '+/-']

# Normalize metrics to a 0-1 scale
df_norm = df_stars.copy()
for m in metrics:
    max_val = df_norm[m].max()
    df_norm[m + '_norm'] = df_norm[m] / max_val if max_val > 0 else 0
angles = np.linspace(0, 2*np.pi, len(metrics), endpoint=False).tolist()
angles += angles[:1]

fig, ax = plt.subplots(figsize=(10, 10), subplot_kw=dict(polar=True))
colors_radar = sns.color_palette('Set2', len(df_norm))
for idx, (_, row) in enumerate(df_norm.iterrows()):
    values = [row[m+'_norm'] for m in metrics] + [row[metrics[0]+'_norm']]
    ax.fill(angles, values, alpha=0.1, color=colors_radar[idx])
    ax.plot(angles, values, 'o-', linewidth=2, label=row['fullname'], color=colors_radar[idx])
ax.set_xticks(angles[:-1])
ax.set_xticklabels(metrics_label, fontsize=12)
ax.set_title('Multi-Dimensional Player Comparison (Normalized)', fontsize=14, fontweight='bold', pad=20)
ax.legend(loc='upper right', bbox_to_anchor=(1.3, 1.1))
plt.tight_layout()
save_chart(fig, '09_star_radar.png')
plt.close()

# Team Points Distribution (Boxplot)
print('Plotting Team Points Distribution Boxplot ...')
df_team_box = query("""
    SELECT team_name, team_pts
    FROM nba_team_games_clean
    WHERE season='2025-26' AND game_type='Regular'
""")

# Standardize column headers to lowercase to prevent Pandas casing issues
df_team_box.columns = df_team_box.columns.str.lower()

# Sort teams by their median points scored in descending order
team_order = df_team_box.groupby('team_name')['team_pts'].median().sort_values(ascending=False).index.tolist()
fig, ax = plt.subplots(figsize=(16, 8))
sns.boxplot(data=df_team_box, x='team_name', y='team_pts', order=team_order,
            palette='RdYlBu_r', ax=ax, linewidth=1)
sns.stripplot(data=df_team_box, x='team_name', y='team_pts', order=team_order,
              color='black', alpha=0.2, size=2, ax=ax)
ax.set_xlabel('Team')
ax.set_ylabel('Points Scored')
ax.set_title('2025-26 NBA Team Points Distribution (Boxplot)', fontsize=14, fontweight='bold')
ax.set_xticklabels(ax.get_xticklabels(), rotation=45, ha='right')

plt.tight_layout()
save_chart(fig, '10_team_boxplot.png')
plt.close()

# Scoring Composition Comparison for TOP 4 Scorers
print('Plotting Multi-Subplot Pie Charts for Top 4 Scorers...')
# check score top 4 
df_pie_multi = query("""
    SELECT fullName, team_name,
           ROUND(AVG(pts), 1) AS avg_pts,
           ROUND(AVG(fg3m) * 3, 1) AS avg_3p_pts,
           ROUND(AVG(fgm - fg3m) * 2, 1) AS avg_2p_pts,
           ROUND(AVG(ftm), 1) AS avg_ft_pts
    FROM nba_players_clean_2526
    WHERE game_type='Regular Season' AND minutes_played > 15
    GROUP BY fullName, team_name
    HAVING COUNT(*) >= 20
    ORDER BY avg_pts DESC
    LIMIT 4
""")

df_pie_multi.columns = df_pie_multi.columns.str.lower()
fig, axes = plt.subplots(2, 2, figsize=(12, 10))
axes = axes.flatten() 
scoring_labels = ['2PT Points', '3PT Points', 'FT Points']
colors_pie = ["#185fe2", "#1eeec1", "#591ea7"]
# Loop for 4 players
for idx, row in df_pie_multi.iterrows():
    ax = axes[idx]
    shares = [row['avg_2p_pts'], row['avg_3p_pts'], row['avg_ft_pts']]
    if sum(shares) == 0:
        continue
    wedges, texts, autotexts = ax.pie(
        shares, 
        labels=scoring_labels, 
        autopct='%1.1f%%', 
        startangle=140, 
        colors=colors_pie,
        textprops=dict(color="black", fontsize=9)
    )
    for autotext in autotexts:
        autotext.set_fontweight('bold')
    ax.set_title(f"{row['fullname']}\n({row['team_name']})", fontsize=11, fontweight='bold', pad=10)

plt.suptitle('Scoring Composition Comparison for TOP 4 Scorers', fontsize=16, fontweight='bold', y=0.98)
plt.tight_layout()
save_chart(fig, '11_multi_players_pie.png')
plt.close()