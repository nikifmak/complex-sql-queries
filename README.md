# Complex-sql-queries

## Aggregate table and table all values in array field

```sql
SELECT
	s.sales_id,
	ARRAY_AGG(c.name) AS cuisines
FROM
	shops s
	LEFT JOIN cuisines c ON c.sales_id = s.sales_id
GROUP BY
	s.sales_id
```
| sales_id | cuisines |
|---|---|
|LD01181514885092 |	"{Kebab,Burgers,""Ψητά - Grill""}" |
|LD01181514887676 |	"{Σουβλάκια,""Ψητά - Grill""}" |
|LD01181514929369 |	{Καφέδες,Κρέπες,Sandwich} |
|LD01181514933165 |	{Βάφλες,Παγωτό,Καφέδες} |

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
