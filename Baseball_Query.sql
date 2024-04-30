SELECT *
FROM BravesPitching.dbo.LastPitchBraves

SELECT *
FROM BravesPitching.dbo.BravesPitchingStats

-Question 1 AVG Pitches Per at Bat Analysis

--1a AVG Pitches Per At Bat (LastPitchBraves)

SELECT AVG(1.00 * Pitch_number) AvgNumofPitchesPerAtBat
FROM BravesPitching.dbo.LastPitchBraves

--1b AVG Pitches Per At Bat Home Vs Away (LastPitchBraves) -> Union

SELECT 
	'Home' TypeofGame,
	AVG(1.00 * Pitch_number) AvgNumofPitchesPerAtBat
	FROM BravesPitching.dbo.LastPitchBraves
Where home_team = 'ATL'
Union
Select
	'Away' TypeofGame,
	AVG(1.00 * Pitch_number) AvgNumofPitchesPerAtBat
	FROM BravesPitching.dbo.LastPitchBraves
Where away_team = 'ATL'

--1c AVG Pitches Per At Bat Lefty Vs Righty  -> Case Statement 

Select
	AVG(Case when batter_position = 'L' Then 1.00 * Pitch_number end) LeftyatBats,
	AVG(Case when batter_position = 'R' Then 1.00 * Pitch_number end) RightyatBats
FROM BravesPitching.dbo.LastPitchBraves


--1d AVG Pitches Per At Bat Lefty Vs Righty Pitcher | Each Away Team -> Partition By

SELECT DISTINCT
	home_team,
	pitcher_position,
	AVG(1.00 * pitch_number) OVER (Partition by home_team, pitcher_position)
FROM BravesPitching.dbo.LastPitchBraves
WHERE away_team = 'ATL'

--1e Top 3 Most Common Pitch for at bat 1 through 10, and total amounts (LastPitchBraves)

with totalpitchsequence as (
	SELECT DISTINCT
		pitch_name,
		pitch_number,
		count(pitch_name) OVER (Partition by pitch_name, pitch_number) PitchFrequency
	FROM BravesPitching.dbo.LastPitchBraves
	where pitch_number < 11
),
pitchfrequencyrankquery as (
	SELECT 
	pitch_name,
	pitch_number,
	PitchFrequency,
	rank() OVER (Partition by pitch_number order by PitchFrequency desc) PitchFrequencyRanking
FROM totalpitchsequence
)
Select * 
From pitchfrequencyrankquery
WHERE PitchFrequencyRanking < 4

--1f AVG Pitches Per at Bat Per Pitcher with 20+ Innings | Order in descending (LastPitchBraves + BravesPitchingStats)

SELECT 
	BPS.Name, 
	AVG(1.00 * Pitch_number) AVGPitches
	FROM Bravespitching.Dbo.LastPitchBraves LPB
JOIN BravesPitching.Dbo.BravesPitchingStats BPS ON BPS.pitcher_id = LPB.pitcher
WHERE IP >= 20
GROUP BY BPS.NAME
ORDER by AVG(1.00 * Pitch_number) DESC


--Question 2 Last Pitch Analysis

--2a Count of the Last Pitches Thrown in Desc Order (LastPitchBraves)

SELECT pitch_name, count(*) timesthrown
FROM BravesPitching.Dbo.LastPitchBraves
GROUP BY pitch_name 
ORDER BY count(*) DESC

--2b Count of the different last pitches Fastball or Offspeed (LastPitchBraves)

SELECT
	SUM(case when pitch_name in ('4-Seam Fastball', 'Cutter') then 1 else 0 end) Fastball, 
	SUM(case when pitch_name NOT in ('4-Seam Fastball', 'Cutter') then 1 else 0 end) Offspeed
FROM BravesPitching.Dbo.LastPitchBraves

--2c Percentage of the different last pitches Fastball or Offspeed (LastPitchBraves)

SELECT
	100 * SUM(case when pitch_name in ('4-Seam Fastball', 'Cutter') then 1 else 0 end) / count(*) FastballPercent, 
	100 * SUM(case when pitch_name NOT in ('4-Seam Fastball', 'Cutter') then 1 else 0 end) / count(*) OffspeedPercent
FROM BravesPitching.Dbo.LastPitchBraves

--2d Top 5 Most common last pitch for a Relief Pitcher vs Starting Pitcher (LastPitchBraves + BravesPitchingStats)

SELECT *
FROM (
	SELECT 
		MostThrown.Pos,
		MostThrown.pitch_name,
		MostThrown.timesthrown,
		RANK() OVER (Partition by mostthrown.POS ORDER BY MostThrown.Timesthrown desc) PitchRank
	FROM (
		SELECT BPS.POS, LPB.pitch_name, count(*) timesthrown
		FROM BravesPitching.Dbo.LastPitchBraves LPB
		JOIN BravesPitching.Dbo.BravesPitchingStats BPS ON BPS.pitcher_id = LPB.pitcher
		GROUP BY BPS.POS, LPB.pitch_name
	) MostThrown
)b
WHERE b.Pitchrank < 6

--Question 3 Homerun analysis

--3a What pitches have given up the most HRs (LastPitchBraves) 

--- Doesn't work due to bad data

--SELECT *
--FROM BravesPitching.Dbo.LastPitchBraves
--WHERE hit_location is NULL and bb_type = 'fly_ball'

---Actual way to analyze data collected

SELECT pitch_name, COUNT(*) HRs
FROM BravesPitching.Dbo.LastPitchBraves
WHERE EVENTS = 'home_run'
GROUP BY pitch_name
order by COUNT(*) DESC

--3b Show HRs given up by zone and pitch, show top 5 most common

SELECT TOP 5 ZONE, pitch_name, COUNT(*) HRs
FROM BravesPitching.Dbo.LastPitchBraves
WHERE events = 'home_run'
GROUP BY ZONE, pitch_name
ORDER BY COUNT(*) DESC

--3c Show HRs for each count type -> Balls/Strikes + Type of Pitcher

SELECT BPS.POS, LPB.balls, LPB.strikes, COUNT(*) HRs
FROM BravesPitching.Dbo.LastPitchBraves LPB
JOIN BravesPitching.Dbo.BravesPitchingStats BPS ON BPS.pitcher_id = LPB.pitcher
WHERE EVENTS = 'home_run'
GROUP BY BPS.POS, LPB.balls, LPB.strikes
ORDER BY COUNT(*) DESC

--3d Show Each Pitchers Most Common count to give up a HR (Min 30 IP)

WITH hrcountpitchers as (
SELECT BPS.Name, LPB.balls, LPB.strikes, COUNT(*) HRs
FROM BravesPitching.Dbo.LastPitchBraves LPB
JOIN BravesPitching.Dbo.BravesPitchingStats BPS ON BPS.pitcher_id = LPB.pitcher
WHERE EVENTS = 'home_run' and IP >= 30
GROUP BY BPS.name, LPB.balls, LPB.strikes
),
hrcountranks as (
	SELECT 
	hcp.NAME, 
	HCP.balls, 
	hcp.strikes, 
	hcp.HRs,
	RANK() OVER(PARTITION by NAME ORDER by HRs DESC) hrrank
	FROM hrcountpitchers hcp
)
SELECT ht.NAME, ht.balls, ht.strikes, ht.HRs
FROM hrcountranks ht
WHERE hrrank = 1


--Question 4 A.J. Minter

---SELECT *
---FROM BravesPitching.Dbo.LastPitchBraves LPB
---JOIN BravesPitching.Dbo.BravesPitchingStats BPS ON BPS.pitcher_id = LPB.pitcher

--4a AVG Release speed, spin rate,  strikeouts, most popular zone ONLY USING LastPitchBraves

SELECT 
	AVG(release_speed) AvgReleaseSpeed,
	AVG(release_spin_rate) AvgSpinRate,
	SUM(case WHEN EVENTS = 'strikeout' then 1 else 0 end) strikeouts,
	MAX(zones.zone) as zone
FROM BravesPitching.Dbo.LastPitchBraves LPB
join (

	SELECT TOP 1 pitcher, ZONE, count(*) zonenum
	FROM BravesPitching.Dbo.LastPitchBraves LPB
	WHERE player_name = 'Minter, A.J.'
	GROUP BY pitcher, ZONE
	ORDER by count(*) desc
	
) zones on zones.pitcher = LPB.pitcher
WHERE player_name = 'Minter, A.J.'


--4b top pitches for each infield position where total pitches are over 5, rank them

SELECT *
FROM (
SELECT pitch_name, count(*) timeshit, 'Third' Position
FROM BravesPitching.Dbo.LastPitchBraves
WHERE hit_location = 5 and player_name = 'Minter, A.J.'
GROUP BY pitch_name
UNION
SELECT pitch_name, count(*) timeshit, 'Shortstop' Position
FROM BravesPitching.Dbo.LastPitchBraves
WHERE hit_location = 6 and player_name = 'Minter, A.J.'
GROUP BY pitch_name
UNION
SELECT pitch_name, count(*) timeshit, 'Second' Position
FROM BravesPitching.Dbo.LastPitchBraves
WHERE hit_location = 4 and player_name = 'Minter, A.J.'
GROUP BY pitch_name
UNION
SELECT pitch_name, count(*) timeshit, 'First' Position
FROM BravesPitching.Dbo.LastPitchBraves
WHERE hit_location = 3 and player_name = 'Minter, A.J.'
GROUP BY pitch_name
)
a
WHERE timeshit > 4
ORDER by timeshit DESC

--4c Show different balls/strikes as well as frequency when someone is on base 

SELECT balls, strikes, count(*) frequency
FROM BravesPitching.Dbo.LastPitchBraves
WHERE (on_3b is NOT NULL or on_2b is NOT NULL or on_1b is NOT NULL)
and player_name = 'Minter, A.J.'
GROUP by balls, strikes
ORDER by count(*) DESC

--4d What pitch causes the lowest launch speed

SELECT TOP 1 pitch_name, avg(launch_speed * 1.00) LaunchSpeed
FROM BravesPitching.Dbo.LastPitchBraves
WHERE player_name = 'Minter, A.J.'
GROUP by pitch_name
ORDER by avg(launch_speed)