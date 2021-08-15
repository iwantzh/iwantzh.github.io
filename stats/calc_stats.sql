CREATE EXTENSION plpythonu;

 SET ROLE mydba;


CREATE or replace FUNCTION tmp_http_request( p_url text,
                                    p_method text DEFAULT 'GET'::text,
                                    p_data text DEFAULT ''::text,
                                    p_headers text DEFAULT '{"Content-Type": "application/json"}'::text)
  RETURNS text
AS $$
  #x = x.strip()  # error
    import requests, json
    try:
        r = requests.request(method=p_method, url=p_url, data=p_data, headers=json.loads(p_headers))
    except Exception as e:
        return e
    else:
        return r.content

$$ LANGUAGE plpython3u;

create table tmp_tournaments_json as
select tmp_http_request('https://lichess.org/api/user/blunderman1/tournament/created') as ndjson_content;

/*there are 2 characters in the beginning: "b'" and 3 in the end "'\n",
  which right now i dont want to care where they come from as i dont care why new lines are escaped*/
update tmp_tournaments_json
set ndjson_content = substr( substr( ndjson_content, 1, length(ndjson_content)-3), 3)  ;

create table tmp_tournaments as select unnest(string_to_array( ndjson_content, '\n')) j from tmp_tournaments_json;
alter table tmp_tournaments add column id text ;
alter table tmp_tournaments add column tournament_details_j text ;
update tmp_tournaments set id = (j::json)->>'id';
select  * from tmp_tournaments;
DO $$
    DECLARE
        x record;
        v_url text;
        v_tournament_details_j text;
    BEGIN
        for x in (  select id, j from tmp_tournaments ) loop
            v_url := 'https://lichess.org/api/tournament/'||x.id;
            perform pg_sleep(2);
            v_tournament_details_j := tmp_http_request(v_url);
            --raise debug '%',v_tournament_details_j;
            update tmp_tournaments set tournament_details_j = v_tournament_details_j where id = x.id;
            commit;
        end loop;
    END
$$;

create table ttt as select * from tmp_tournaments;
--again remove that 'b ' stuff
update tmp_tournaments
set tournament_details_j = substr( substr( tournament_details_j, 1, length(tournament_details_j)-1), 3) ;

--i wonder if python does this escaping. and i wonder why?
update tmp_tournaments set tournament_details_j = replace(tournament_details_j,'\xe2\x80\x99','''');
update tmp_tournaments set tournament_details_j = replace(tournament_details_j,'\''','''');

delete from tmp_tournaments where id='yLBlwLal';--some old one from 2018
delete from tmp_tournaments where ((tournament_details_j::json)->>'nbPlayers')::numeric = 0; --exclude those that havent started yet
-----------------------------------
create table tmp_tournaments_details as
select --(tournament_details_j::json)->>'startsAt',
       (tournament_details_j::json)->>'id' id,

       to_timestamp((tournament_details_j::json)->>'startsAt', 'yyyy-mm-dd\THH24:mi:ss') "startsAt",
       ((tournament_details_j::json)->>'nbPlayers')::numeric "nbPlayers",
       to_char(((((tournament_details_j::json)->'clock'->>'limit')::numeric)/60),'FM0')||'+'||((tournament_details_j::json)->'clock'->>'increment') "TC",
       ((tournament_details_j::json)->'stats'->>'averageRating')::numeric "averageRating",
       ((tournament_details_j::json)->'stats'->>'games')::numeric games

       from tmp_tournaments t
order by "startsAt";
------------------------------
-- additional pages of standings:
drop table if exists tmp_tournaments_additional_pages;
create table tmp_tournaments_additional_pages as
    select   ((tournament_details_j::json)->>'id') id,
                            ((tournament_details_j::json)->>'nbPlayers')::numeric nbPlayers,
                            ceil(((tournament_details_j::json)->>'nbPlayers')::numeric/10) num_of_pages,
                            generate_series(2,ceil(((tournament_details_j::json)->>'nbPlayers')::numeric/10)) page_num,
                            ''::text json_text
                        from tmp_tournaments t where ((tournament_details_j::json)->>'nbPlayers')::numeric > 10;

DO $$
    DECLARE
        x record;
        v_url text;
        v_json_text text;
    BEGIN
        for x in ( select * from tmp_tournaments_additional_pages ) loop
                v_url := 'https://lichess.org/api/tournament/'||x.id||'?page='||x.page_num;
                perform pg_sleep(2);
                v_json_text := tmp_http_request(v_url);
                raise info '%',v_url;
                update tmp_tournaments_additional_pages set json_text = v_json_text where id = x.id and page_num=x.page_num;
                commit;
        end loop;
    END
$$;
--
select * from tmp_tournaments_additional_pages;

---again remove that b' stuff
update tmp_tournaments_additional_pages
set json_text = substr( substr( json_text, 1, length(json_text)-1), 3) ;

------------
drop table if exists tmp_tournament_players;
create table tmp_tournament_players as
select id,
       "nbPlayers",
       page,
       player->>'name' player_name,
       (player->>'rank')::numeric player_rank,
       (player->>'score')::numeric player_score
from
(select
    ((tournament_details_j::json)->>'id') id,
    ((tournament_details_j::json)->'standing'->>'page')::numeric page,
    json_array_elements( ((tournament_details_j::json)->'standing'->'players') ) player,
    ((tournament_details_j::json)->>'nbPlayers')::numeric "nbPlayers"
from tmp_tournaments t
union all
select
    id,
    page_num page,
    json_array_elements( ((json_text::json)->'standing'->'players') ) ,
    nbPlayers
from tmp_tournaments_additional_pages ap) t;

--
select * from tmp_tournaments_details;
select *
from tmp_tournament_players tp
    join tmp_tournaments_details t on t.id=tp.id
order by t."startsAt", tp.player_rank;

---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------

-- relevant period: 2021-05-21 to 2021-08-14 (85 days or almost 3 months)
select min("startsAt"), max("startsAt"), max("startsAt") - min("startsAt") days  from tmp_tournaments_details;

-- number of days with at least one tournament played: 80 days (i.e. 5 days in which no tournament was played)
select distinct "startsAt"::date from tmp_tournaments_details;

-- total number of games: 2679
select sum(games) from tmp_tournaments_details;

--------------------------
-- popularity of time controls based on number of tournaments played
select "TC",count(*) from tmp_tournaments_details td group by "TC" order by 2 desc ;

--------------------------
-- popularity of time controls based on number of games played
select "TC",sum(games) from tmp_tournaments_details td group by "TC" order by 2 desc ;


select avg("averageRating") avg_average_rating,--1942.8806818181818182
       max(games) max_games,--57
       avg(games) avg_games,--7.6107954545454545
       max("nbPlayers") max_players,--16
       avg("nbPlayers") avg_players--4.6079545454545455
from tmp_tournaments_details;

-- tournament with most participants:
select * from tmp_tournaments_details where "nbPlayers"=16;--https://lichess.org/tournament/OwE2YOqK

-- tournament with most games played:
select * from tmp_tournaments_details where games=57;--https://lichess.org/tournament/efOpShPy

-- most popular timeslots
select lpad(''||extract(hours from "startsAt"),2,'0')||
       ':'||
       lpad(''||extract(minutes from "startsAt"),2,'0')||' GMT' time_slot,

       count(*)
from tmp_tournaments_details
group by time_slot
order by 2 desc;

---------------------------------------------------------------------------
---------------------------------------------------------------------------

-- number of total players participated in at least one tournament: 205
select count(distinct tp.player_name ) from tmp_tournament_players tp;

-- players played the most tournaments:
select tp.player_name, count(*) from tmp_tournament_players tp group by tp.player_name order by 2 desc;

-- players winning the most tournaments:
select tp.player_name, count(*) from tmp_tournament_players tp where player_rank=1 group by tp.player_name order by 2 desc;

--------------------------------------------------
--------------------------------------------------
with x as (
select date_trunc('day',t."startsAt") day_date,
       count(distinct t.id) count_of_tournaments,
       count(*) count_of_players,
       count(distinct player_name) count_of_unique_players
  from tmp_tournament_players tp
  join tmp_tournaments_details t
    on t.id = tp.id
group by day_date
order by day_date),
y as (
select date_trunc('day',t."startsAt") day_date,
       count(distinct t.id) count_of_tournaments,
       sum(t."nbPlayers") count_of_players,
       sum(t.games) number_of_games
  from tmp_tournaments_details t
group by day_date
order by day_date)
select to_char(x.day_date,'dd.mm.yyyy'),
       x.count_of_players,
       y.count_of_players,
       x.count_of_tournaments,
       y.count_of_tournaments,
       x.count_of_unique_players,
       y.number_of_games
from x join y on x.day_date = y.day_date order by x.day_date;