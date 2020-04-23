# Complex-sql-queries

## Crosstab (PIVOT sql)
`crosstab` is a function that transponses rows to columns.

Let's analyze the query below:

### 1. first input of function crosstab

Its called category query and returns 
1. rowid field (the field that is gonna work as id, in our case sales_id
2. category field (the field that categorizies our input. For example here its : wolt, vrisko, box etc. 
3. value field (the field that containts the values. Here : string -> SUSPENDED, ACTIVE
```sql
SELECT sales_id, name, status
    FROM competitors GROUP BY sales_id, name, status ORDER BY sales_id, name
```
### 2. second input of function crosstab
Return the list of columns that the above set it gonna be tested against: box, clickdelivery, deliveras etc
```sql
SELECT DISTINCT name  FROM competitors ORDER BY name
```

### 3. last part the returning table columns that we want and each values
```sql
 ct("sales_id" VARCHAR,
      "box" VARCHAR,
      "clickdelivery" VARCHAR,
      "deliveras" VARCHAR,
      "deliverygr" VARCHAR,
      "fagi" VARCHAR,
      "fasterfood" VARCHAR,
      "giaola" VARCHAR,
      "skroutzfood" VARCHAR,
      "vrisko" VARCHAR,
      "wolt" VARCHAR
```

```sql
CREATE EXTENSION IF NOT EXISTS tablefunc;

 SELECT * FROM crosstab( 
   'SELECT sales_id, name, status
    FROM competitors GROUP BY sales_id, name, status ORDER BY sales_id, name',
   -- query to generate the horizontal header
    'SELECT DISTINCT name  FROM competitors ORDER BY name'
 )
  AS ct("sales_id" VARCHAR,
      "box" VARCHAR,
      "clickdelivery" VARCHAR,
      "deliveras" VARCHAR,
      "deliverygr" VARCHAR,
      "fagi" VARCHAR,
      "fasterfood" VARCHAR,
      "giaola" VARCHAR,
      "skroutzfood" VARCHAR,
      "vrisko" VARCHAR,
      "wolt" VARCHAR
);
```

## Partition
`row_number()` is a function that returns the corresponding row number over a partition.

`PARTITION BY` (GROYP BY) is clause that divides the result set into partitions (another term for groups of rows). So below, it creates small partitions of the same sales_id. 

```sql
SELECT
	sales_id,
	name,
	ROW_NUMBER() OVER (PARTITION BY sales_id ORDER BY sales_id) AS cuisineNumber
FROM
	cuisines
	
-- The same query with concatinating a prefix 'cuisine'

SELECT
	sales_id,
	name,
	'cuisine' || CAST(ROW_NUMBER() OVER (PARTITION BY sales_id ORDER BY sales_id) AS VARCHAR) cuisineNumber
FROM
	cuisines
	
```

## Self join table with 2 parts. The first one is aggragation and the second one is where query.
```sql
WITH cuisines_aggregated AS (
	SELECT
	sales_id,
	ARRAY_AGG(name) AS cuisines
FROM
	cuisines
GROUP BY
	sales_id
)
SELECT
	cuisines_aggregated.sales_id,
	cuisines_aggregated.cuisines,
	cuisines.name AS main_cuisine
FROM
	cuisines_aggregated
	LEFT JOIN cuisines ON cuisines.sales_id = cuisines_aggregated.sales_id
WHERE
	cuisines.main = TRUE

```

## Aggregate table and table all values in array field

```sql
SELECT
	sales_id,
	ARRAY_AGG(name) AS cuisines
FROM
	cuisines
GROUP BY
	sales_id

```
| sales_id | cuisines |
|---|---|
|LD01181514885092 |	"{Kebab,Burgers,""Ψητά - Grill""}" |
|LD01181514887676 |	"{Σουβλάκια,""Ψητά - Grill""}" |
|LD01181514929369 |	{Καφέδες,Κρέπες,Sandwich} |
|LD01181514933165 |	{Βάφλες,Παγωτό,Καφέδες} |

## Aggregate and join 
```sql
select * from shops 
LEFT JOIN (select sales_id, ARRAY_AGG(name)
from flags
where value = TRUE
group by sales_id) as flags_aggr  
ON flags_aggr.sales_id = shops.sales_id


```

## Select with case
```sql
SELECT
	sales_id,
	CASE WHEN main = TRUE THEN
		name
	ELSE
		NULL
	END AS main_cuisine
FROM
	cuisines
```
result
|sales_id|cuisine  |
|---|---|
|LD12192445350	| Pizza| 
|LD12192445350	|NULL|
|LD12192445350	|NULL|
|LD12192436982	|Καφέδες|
|LD12192436982	|NULL|
|LD12192436982	|NULL|

## Find min value of field
```sql
select MIN(month) from homepage_banners;
```

## Like on integer field => cast as text and LIKE
```sql
 select distinct "rest_id" from "shop_actions" where CAST("rest_id" as text) LIKE '%3' limit 10

```

## Query change sequence id 
```sql 
SELECT
	setval('area_area_id_seq', COALESCE((
			SELECT
				MAX(area_id) + 1 FROM area), 1), FALSE);
```				

## Query 1 - 1
```sql
EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON)
SELECT
booked, visits, asd
FROM (
	SELECT 
	count(
		CASE WHEN action = 'booked' THEN
			1
		END) AS booked,
	count(
		CASE WHEN action = 'booked'
			OR action = 'snoozed'
			OR action = 'rejected' THEN
			1
		END) AS visits,
	to_char(created_at, 'MMYYYY') AS asd
FROM
	shop_actions
WHERE
	user_email = 'nikiforos.makrinakis@e-food.gr'
GROUP BY
	asd
) t
	WHERE t.asd ='092019';

```

## Query 1 - 2 Faster due to initial aggregation (http://tatiyants.com)
```sql
SELECT
	count(
		CASE WHEN action = 'booked' THEN
			1
		END) AS booked,
	count(
		CASE WHEN action = 'booked'
			OR action = 'snoozed'
			OR action = 'rejected' THEN
			1
		END) AS visits,
		dateMMYYYY
FROM (
	SELECT
		action,
		to_char(created_at, 'MMYYYY') AS dateMMYYYY
	FROM
		shop_actions
	WHERE
		user_email = 'nikiforos.makrinakis@e-food.gr'
		AND action IN('booked', 'snoozed', 'rejected')) t
WHERE
	t.dateMMYYYY in('092019', '082019', '072019', '062019', '102019')
GROUP BY
	t.dateMMYYYY
```	
