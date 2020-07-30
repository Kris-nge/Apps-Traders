/*
/*
Is there correlation between review_count and install_count in play_store
No correlation between either rating and install_count OR review_count and install_count.
*/
SELECT name, review_count, install_count, content_rating, genres
FROM play_store_apps
WHERE review_count > 50000
ORDER BY review_count DESC;

SELECT name, review_count, install_count, content_rating, genres
FROM play_store_apps
WHERE review_count < 5000
ORDER BY review_count DESC;
=====================================================================



/*
=====================================================================
1st Method:
Findings based on 'app_store' dataset. Conclusion made based on projected earning.
Top 10 apps from app_store that are also available in play_store:
 1. PewDiePie's Tuber Simulator <$0, 9+, Games>
 2. ASOS 						<$0, 4+, shopping>
 3. The Guardian 				<$0, 12+, News>
 4. Domino's Pizza USA 			<$0, 4+, Food&Drink>
 5. Egg,Inc						<$0, 4+, Games>
 6. Geometry Dash Life			<$0, 4+, Games>
 7. Cytus						<$1.99, 4+, Games>
 8. Cooking Fever				<$0, 4+, Games>
 9. Fallout Shelter				<$0, 12+, Games>
 10. PES CLUB MANAGER			<$0, 4+, Games>
 
 Price range: $ 0 to $1.99,
 content rating: 4+,9+,12+ Basically everyone
 genre: Games, shopping, News, food&Drink
=====================================================================
1.	Based on the deliverable requirement, price, content_rating and genres columns are selected.
*/

SELECT DISTINCT sub.name, 
		sub.price, 
		sub.rating, 
		sub.life_span, 
		sub.a_revenue, 
		sub.app_cost, 
		sub.a_ebt, 
		sub.content_rating, 
		sub.primary_genre
FROM(
	SELECT DISTINCT s.name,	
			s.price, 
			s.rating, 
			s.life_span,
			ROUND(s.life_span*(5000*12)) AS a_revenue, --to calcuate revenue based on average monthly amount receive
			ROUND(s.app_cost) AS app_cost,
			ROUND(s.life_span*(5000*12) - (s.app_cost)) AS a_ebt, -- to calculate earning before tax (Revenue - cost)
			s.content_rating,s.primary_genre
	
	FROM(
		SELECT DISTINCT name, price,
 			CASE WHEN price = 0.00 OR price <= 0.99 THEN 10000+(1000*12)*((rating*2)+1)--to calculate app costs for app price $0 to $1
 				 WHEN price > 0.99 THEN (price*10000)+(1000*12)*((rating*2)+1) -- to calculate app costs for app price above $1
				 END AS app_cost,				 
 				 rating,
				(rating*2)+1 AS life_span,	--life span in term of year			
				content_rating,	
				primary_genre
		
		FROM app_store_apps) AS s
ORDER BY a_ebt DESC) AS sub
INNER JOIN play_store_apps AS p
ON sub.name = p.name
ORDER BY a_ebt DESC;

/*
========================================================================================
2nd Method:
Finding based on data from 'play_store' that are also available in app_store_apps table
TOP 10:
1. Fernanfloo				<$0, everyone 10+, Arcade/Games>
2. PewDiePie's simulator 	<$0, Teen, Casual/Games>
3. H*nest Meditation		<$1.99, Mature 17+, Lifestyle/Entertainment>
4. Adobe Illustrator Draw	<$0, Everyone, Photography/Productivity>
5. ADP Mobile Solutions		<$0, Everyone, Business>
6. Afterlight				<$0, Everyone, photography/photo & video>
7. Airbnb					<$0, Everyone, Travel>
8. Allreceipes Dinner Spinner<$0, Everyone, Food & Drink>
9. Alto's Adventure			<$0, Everyone, Action/Games>
10.Amex Mobile				<$0, Everyone, Finance>
=========================================================================================
-- Categorize rating to find projected life for apps in play_store
--Original data has 10840 rows
--After selecting distinct name, the play_store has 9679 unique apps
-- To round down or up half point -> ROUND(rating / 0.5, 1)* 0.5
==============================================================================
ALTER TABLE play_store_apps
ALTER COLUMN price TYPE numeric USING price::numeric;
--It doesn't work. invalid input syntax for type numeric: "$4.99". $ is the issue.
--ALTER TABLE play_store_apps
--ALTER COLUMN new_price TYPE numeric USING new_price::numeric;

select rating, 
	ROUND(ROUND(COALESCE(rating,0)*2)/2,1), --To round down or round up half point        <- both give the same answers
	ROUND(COALESCE(rating,0)/.5)*0.5 -- another way to round down or round up half point
from play_store_apps
===============================================================================
*/


SELECT DISTINCT sq.name, 
			--a.price, 
		    sq.new_price,
		    sq.round_rating, 
			--a.rating,
			sq.longevity,
			sq.p_revenue,
			ROUND(sq.play_app_cost),
			ROUND(sq.p_revenue - sq.play_app_cost) AS p_ebt, --earning before tax
			sq.install_count,
			sq.content_rating,
			genres,
			Primary_genre
FROM	
	(SELECT DISTINCT p.name, new_price, round_rating,(round_rating*2)+1 AS longevity,
	   	ROUND(((round_rating*2)+1)*(5000*12)) AS p_revenue, 
	   	CASE WHEN new_price = 0.00 OR new_price <= 0.99 THEN 10000+(1000*12)*((round_rating*2)+1)
	   		 WHEN new_price > 0.99 THEN (new_price*10000)+(1000*12)*((round_rating*2)+1)
			 END AS play_app_cost,
	 	install_count, content_rating, genres	   
	   
		FROM(
		SELECT DISTINCT name,
			CAST(REPLACE(price,'$','') AS numeric(5,2)) AS new_price,
			ROUND(COALESCE(rating, 0) / 0.5, 0)* 0.5 AS round_rating, -- to round down or round up by half point
			install_count,
 			content_rating, 
			genres
		FROM play_store_apps) AS p
ORDER BY round_rating DESC) AS sq
JOIN app_store_apps As a
ON sq.name = a.name
ORDER BY p_ebt DESC;



/*
=============================================================================================
3rd Method:
Findings by JOINING query results from the two tables and based on average earning before tax
TOP 10 apps:
1. PewDiePie's Tuber Simulator <$0, Teen, Games>
2. ASOS						   <$0, Everyone, Shopping>
3. Domino's Pizza USA		   <$0, Everyone, food & Drink>
4. Egg, Inc					   <$0, Everyone, Games>
5. Fernanfloo				   <$0, Everyone 10+, Games>
6. Geometry Dash Lite		   <$0, Everyone, Games>
7. The Guardian				   <$0, Teen, News>
8. Cytus					   <$0, Everyone, Games>
9. H*nest Meditation		   <$1.99, Everyone, Entertainment>
10. Adobe Illustrator Draw	   <$0, Productivity, Games>
===============================================================================================
*/
/*
SELECT 	--mfinding.primary_genre, 
		mfinding.new_price,
		SUM(avg_ebt) OVER(PARTITION BY mfinding.new_price) AS sum_avg_overall,
		AVG(avg_ebt) OVER(PARTITION BY mfinding.new_price) AS avg_overall
FROM(
	*/
	*/
WITH cte1 AS (SELECT DISTINCT s.name, 
 				price, 
 				rating, 
				currency,
				s.life_span,
				ROUND(s.life_span*(5000/2*12)) AS a_revenue, 
				ROUND(s.app_cost) AS app_cost,
				ROUND(s.life_span*(5000/2*12) - (s.app_cost)) AS a_ebt,
				content_rating,
				primary_genre
			FROM(
				SELECT DISTINCT name, price, currency,
 				CASE WHEN price = 0.00 OR price <= 0.99 THEN 10000+(1000*12)*((rating*2)+1)
 					 WHEN price > 0.99 THEN (price*10000)+(1000*12)*((rating*2)+1)
				END AS app_cost,				 
 				rating,
				(rating*2)+1 AS life_span,	--life span in term of year			
				content_rating,
				primary_genre
		FROM app_store_apps) AS s
		ORDER BY a_ebt DESC), --;
		

cte2 AS	(SELECT DISTINCT sq.name, 
			--	a.price, 
				sq.new_price,
				sq.round_rating, 
			--	a.rating,
				sq.longevity,sq.p_revenue,
				ROUND(sq.play_app_cost) AS play_app_cost,
				ROUND(sq.p_revenue - sq.play_app_cost) AS p_ebt,
				--sq.install_count,
				sq.content_rating,
				genres
		FROM	
			(SELECT DISTINCT p.name,
	   			new_price,
	   			round_rating,
	   			(round_rating*2)+1 AS longevity,
	   			ROUND(((round_rating*2)+1)*(5000/2*12)) AS p_revenue, 
	   			CASE WHEN new_price = 0.00 OR new_price <= 0.99 THEN 10000+(1000*12)*((round_rating*2)+1)
	   				 WHEN new_price > 0.99 THEN (new_price*10000)+(1000*12)*((round_rating*2)+1)
					 END AS play_app_cost,
	 			--install_count,
				content_rating,
				genres	   
	   
		FROM(
			SELECT DISTINCT name,
				CAST(REPLACE(price,'$','') AS numeric(5,2)) AS new_price,
				ROUND(COALESCE(rating, 0) / 0.5)* 0.5 AS round_rating, -- to round down or round up by half point
				--install_count,
 				content_rating, 
				genres
			FROM play_store_apps)As p
		ORDER BY round_rating DESC) AS sq
ORDER BY p_ebt DESC) --;


SELECT cte1.name, cte1.rating, cte2.round_rating, MAX(a_ebt) AS max_app_profit, MAX(p_ebt) AS max_play_profit
FROM cte1
JOIN cte2 ON
cte1.name = cte2.name
WHERE cte1.rating =5 OR cte2.round_rating = 5
--cte1.a_ebt > cte2.p_ebt OR cte2.p_ebt > cte1.a_ebt AND cte1.rating> cte2.round_rating OR cte2.round_rating > cte1.rating
GROUP BY cte1.rating,cte2.round_rating, cte1.name
ORDER BY max_app_profit DESC, max_play_profit DESC;
--LIMIT 10;


/*
SELECT DISTINCT a.name, 
				cte2.new_price,
				cte1.rating,
				cte2.round_rating, 
				
				a_ebt, p_ebt, 
				ROUND((a_ebt + p_ebt)/2) as Avg_ebt, 
				cte2.content_rating, 
				cte1.primary_genre
				--ROUND(SUM(AVG(ROUND((a_ebt + p_ebt)/2)) OVER() )) AS avg_profit_genre
FROM app_store_apps AS a
INNER JOIN cte1
ON a.name = cte1.name
INNER JOIN cte2
ON a.name = cte2.name
ORDER BY avg_ebt DESC;
/*
--) as mfinding
--GROUP BY mfinding.primary_genre
ORDER BY new_price, avg_overall DESC;
--LIMIT 20;
*/
*/