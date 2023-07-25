/*First table creation*/
create table ipl_ball_data (id int, inning int, over_num int, ball int, batsman varchar, non_striker varchar, bowler varchar, batsman_runs int, extra_runs int, total_runs int, is_wicket int, dismissal_kind varchar, player_dismissed varchar, fielder varchar, extras_type varchar, batting_team varchar, bowling_team varchar);

copy ipl_ball_data from 'E:\postgre\IPL_Ball.csv'delimiter ',' csv header;

select*from ipl_ball_data;

/*batsmen*/
/*aggressive batsman*/
select distinct batsman, count(ball) as total_ball, (cast(sum(case when extras_type<>'wides'then batsman_runs else 0 end)as decimal)/count(case when extras_type<>'wides' then ball else 0 end))*100 as strike_rate_batsman from ipl_ball_data group by batsman having count(ball)>500 order by strike_rate_batsman desc limit 10; 

/*Anchor batsman*//*since the total number of match ids is 816, and one season on a average has 62 matches, it can be said that any player who has played more than 124 matches has probably played in more than two seasons.*/
select batsman, count(distinct id)as total_match_id, sum(batsman_runs) as total_runs, count(case when is_wicket = 1 then 1 end) as total_dismissals, sum(batsman_runs)/nullif(count(case when is_wicket = 1 then 1 end), 0) as batting_average from ipl_ball_data group by batsman having count(distinct id)>124 order by batting_average desc 10;

/*hard hitters*/
select distinct batsman, count(distinct id)as total_match_id, count(case when batsman_runs=4 or batsman_runs=6 then 1 end)as fours_sixes from ipl_ball_data group by batsman having count(distinct id)>124 order by fours_sixes desc limit 10; 

/*bowlers*/
/*economical bowlers*/
select distinct bowler, count(ball) as total_ball,cast(sum(total_runs)as decimal)/count(over_num) as bowler_economy from ipl_ball_data group by bowler having count(ball)>500 order by bowler_economy asc limit 10;

/*wicket taking bowlers*/
select distinct bowler, count(ball) as total_ball, cast(count(ball)as decimal)/nullif(count(case when is_wicket=1 then 1 end),0) as strike_rate_bowler from ipl_ball_data group by bowler having count(ball)>500 order by strike_rate_bowler asc limit 10;

/*All rounders*/
select distinct batsman as all_rounder, count(ball) as total_ball, cast(count(ball)as decimal)/nullif(count(case when is_wicket=1 then 1 end),0) as strike_rate_bowler, (cast(sum(case when extras_type<>'wides'then batsman_runs else 0 end)as decimal)/count(case when extras_type<>'wides' then ball else 0 end))*100 as strike_rate_batsman 
from ipl_ball_data 
where batsman in (select distinct bowler from ipl_ball_data) group by all_rounder having count(ball)>500 and cast(count(ball)as decimal)/nullif(count(case when is_wicket=1 then 1 end),0)<15 order by strike_rate_batsman desc, strike_rate_bowler asc nulls last;

/*wicket keepers*/
select batsman as wicket_keeper, count(ball) as total_ball, count(case when dismissal_kind='run out' or dismissal_kind='caught' then 1 end) as caught_stumped, sum(batsman_runs) as total_runs from ipl_ball_data where batsman in (select distinct bowler from ipl_ball_data) group by batsman having count(ball)>500 order by caught_stumped desc nulls last; 

/*additional questions*/
create table matches(id int, city varchar, match_date date, player_of_match varchar, venue varchar, neutral_venue int, team1 varchar, team2 varchar, toss_winner varchar, toss_decision varchar, winner varchar, "result" varchar, result_margin int, eliminator varchar, "method" varchar, umpire1 varchar, umpire2 varchar );
copy matches from 'E:\postgre\IPL_matches.csv'delimiter ',' csv header;

select * from matches limit 10;

/*q1*/
select count(distinct city) as total_cities from matches; --33

/*q2*/
select id, inning, over_num, ball, batsman, non_striker, bowler, batsman_runs, extra_runs, total_runs, is_wicket, dismissal_kind, player_dismissed, fielder, extras_type, batting_team, bowling_team, case when batsman_runs=0 then 'dot' when batsman_runs>4 then 'boundary' else 'other' end as ball_result from ipl_ball_data; 

create table deliveries_v02 as (select id, inning, over_num, ball, batsman, non_striker, bowler, batsman_runs, extra_runs, total_runs, is_wicket, dismissal_kind, player_dismissed, fielder, extras_type, batting_team, bowling_team, case when batsman_runs=0 then 'dot' when batsman_runs>4 then 'boundary' else 'other' end as ball_result from ipl_ball_data);

select * from deliveries_v02 limit 10;

/*q3*/
select count(case when ball_result='dot' then 1 end) as total_dots, count(case when ball_result='boundary' then 1 end) as total_boundaries from deliveries_v02;

/*q4*/
select distinct batting_team, count(case when ball_result = 'boundary' then 1 end) as total_boundaries from deliveries_v02 group by batting_team order by total_boundaries desc;

/*q5*/
select distinct bowling_team, count(case when ball_result = 'dot' then 1 end) as total_dots from deliveries_v02 group by bowling_team order by total_dots desc;

/*q6*/
select count(case when dismissal_kind='caught' then 1 end) as "caught", count(case when dismissal_kind='run out' then 1 end) as run_out, count(case when dismissal_kind='bowled' then 1 end) as "bowled" from deliveries_v02;

/*q7*/
select distinct bowler, sum(total_runs) as runs_conceded from ipl_ball_data group by bowler order by runs_conceded desc limit 10;

/*q8*/
create table deliveries_v03 as 
select
a.*, b.venue, b.match_date
from deliveries_v02 as a join matches as b on a.id=b.id;

select * from deliveries_v03 limit 10;

/*q9*/
select distinct venue, sum(total_runs) as runs_total_venue from deliveries_v03 group by venue order by runs_total_venue desc nulls last; 

/*q10*/
select extract(year from match_date) as "year", sum(total_runs) eden_total_runs from deliveries_v03 where venue = 'Eden Gardens' group by "year" order by eden_total_runs desc;