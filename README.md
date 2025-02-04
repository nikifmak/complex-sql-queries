# Complex-sql-queries

## Select district values from array type field
```sql
select DISTINCT unnest(textures) as texture from items order by texture
```

## Upsert (insert or update if exists)
```sql
INSERT INTO vendors(name, domain, airtable_id, logo_url)
VALUES ($1, $2, $3, $4)
ON CONFLICT (airtable_id)
DO 
UPDATE 
SET name = $1, domain = $2, logo_url = $4
```

## Use case to create a temp array with helping fields
```sql
SELECT
	pr_month || '-' || area_id as key,
	booked_price,
	cuisine,
	CASE when cuisine <> '' then 'cuisine' else 'all_day' end as type	
FROM
promoted_restaurants
WHERE
pr_restaurant_id = $1
	AND is_morning = FALSE
AND platform_id = 1
and pr_month = ANY($2)
AND deleted_at IS NULL
```


## Inner Joins with STRING_AGG
```sql
SELECT
	area.area_id,
	area.area_name,
	zip_codes_aggr.zip_codes
FROM
	area_restaurant
INNER JOIN area
ON area_restaurant.area_id = area.area_id
INNER JOIN (
select area_id, STRING_AGG(zip_id::VARCHAR, ', ') as zip_codes
from area_zip 
GROUP BY area_id
) as zip_codes_aggr ON zip_codes_aggr.area_id = area.area_id
WHERE
	platform_id = 1
	AND rest_id = 897796
ORDER BY
	area.area_name
```

## Add unique constraint
```sql
ALTER TABLE users 
ADD CONSTRAINT uninque_user_token UNIQUE (user_token);
```

## Delete everything but 
```sql
DELETE FROM users 
WHERE id not in (select id from users where id = ANY('{1,2,3,4,5,6,7}') )
```

## Aggregate and concatenate into string
```sql
select sales_id, STRING_AGG(name, ', ')
from flags
where value = TRUE
group by sales_id
```

## Array Intersect or else check if an array has any common elements matched against a columns of type array
```sql
select sales_id, cuisines_array from total_shops 
where '{Σουβλάκια,Pizza}'&& cuisines_array
```
Returns at every record that at its cuisines_array has at least one of the {Σουβλάκια,Pizza} values


## Not empty string field constraint (check)
```sql
CREATE TABLE emails (
    id serial PRIMARY KEY,
    value VARCHAR (255) NOT NULL UNIQUE CHECK (value <> '')
);
```

## Unique Compound key
```sql
CREATE TABLE contacts (
    id serial PRIMARY KEY,
    phone VARCHAR (255),
    name VARCHAR (255),
    UNIQUE(phone, name),
    CONSTRAINT phone_or_name_not_null CHECK (
        NOT (
            ( phone IS NULL  OR  phone = '' )
                AND
            ( name IS NULL  OR  name = '' )
        )
    )
);
```

## Postgresql Any 1
https://stackoverflow.com/questions/34627026/in-vs-any-operator-in-postgresql

Any can be used instead of where in clause
Here it means : `find all shops that have shop_state either lost or active`
```sql
SELECT * FROM shops where shop_state = ANY('{lost, active}');

```
## Postgresql Any 2
https://stackoverflow.com/questions/39643454/postgres-check-if-array-field-contains-value/39643544

Here it means: `find all shops that 'σουβλακία' is a value inside cuisines array or 
find all shops that their cuisines array contains the value 'σουβλάκια'.`
```sql
select * from total_shops 
where 'Σουβλάκια' = ANY (total_shops.cuisines_array) 
```


## Insert 2 separate entries to different tables, get their foreign keys and create the intermediatate tables 
```sql
WITH email_id AS (
	INSERT INTO emails(value)
	VALUES ('nikifmak@gmail.com')
	ON CONFLICT(value)  DO UPDATE SET value = 'nikifmak@gmail.com'
	RETURNING id
), contact_id AS (
	INSERT INTO contacts(phone, name)
	VALUES ('6984673040', 'Nikiforos Makrynakis')
	ON CONFLICT(phone, name)  DO UPDATE SET name = 'Nikiforos Makrynakis'
	RETURNING id
)

INSERT INTO emails_contacts(email_id, contact_id)
SELECT e.id,
	(SELECT c.id 
	 FROM contact_id c
	) 
FROM email_id e

INSERT INTO shops_emails(sales_id, email_id)
SELECT 'LD12192445350', e.id 
from email_id e

INSERT INTO roles (sales_id, contact_id, type)
SELECT
	'LD12192445350',
	c.id,
	'shop_owner'
FROM
	contact_id c
	
---- ALTERNATIVE ------
INSERT INTO emails(value)
VALUES ('nikifmak@gmail.com')
ON CONFLICT DO NOTHING


INSERT INTO contacts(phone, name)
VALUES ('6984673040', 'Nikiforos Makrynakis')
ON CONFLICT DO NOTHING



INSERT INTO emails_contacts(email_id, contact_id)
SELECT e.id, (SELECT c.id
			  FROM contacts c
			  WHERE c.phone = '6984673040' and c.name = 'Nikiforos Makrynakis')
FROM emails e where e.value = 'nikifmak@gmail.com'

INSERT INTO shops_emails(sales_id, email_id)
SELECT 'LD12192445350', (SELECT e.id
			  FROM emails e
			  WHERE e.value = 'nikifmak@gmail.com')

INSERT INTO roles (sales_id, contact_id, type)
SELECT
	'LD12192445350',
	id,
	'shop_owner'
FROM
	contacts
WHERE 
	phone = '6984673040' and name = 'Nikiforos Makrynakis'

	
```


## Either fields cannot be null
https://www.postgresqltutorial.com/postgresql-not-null-constraint/

https://stackoverflow.com/questions/21021102/not-null-constraint-over-a-set-of-columns
```sql
CREATE TABLE users (
 ID serial PRIMARY KEY,
 username VARCHAR (50),
 PASSWORD VARCHAR (50),
 email VARCHAR (50),
 CONSTRAINT username_email_notnull CHECK (
   NOT (
     ( username IS NULL  OR  username = '' )
     AND
     ( email IS NULL  OR  email = '' )
   )
 )
);
```

## Enable crosstab on psql
```sql
CREATE EXTENSION IF NOT EXISTS tablefunc;
```

## Crosstab safe with specifying columns as values
https://stackoverflow.com/questions/3002499/postgresql-crosstab-query
```sql
select * from crosstab(
'SELECT sales_id, service, user_token from assignees GROUP BY sales_id, service, user_token ORDER BY sales_id, service',
$$VALUES ('am'), ('fs'), ('menu'), ('peinata') , ('promoted')$$)
as ct (
	"sales_id" VARCHAR,
	"am" VARCHAR,
	"fs" VARCHAR,
	"menu" VARCHAR,
	"peinata" VARCHAR,
	"promoted" VARCHAR
) 
```


## Insert a record and get the id in order to save it as foreign key
```sql
WITH result AS (
INSERT INTO contacts (sales_id,
		name,
		phone,
		email)
		VALUES($1,
			$2,
			$3,
			$4)
	RETURNING
		id
) INSERT INTO roles (sales_id, contact_id, TYPE)
SELECT
	$1,
	id,
	'shop_owner'
FROM
	result
```

## select count distinct 
Count how many distinst sales_id exist in the table
```sql
select count(distinct(sales_id))
 from assignees
```

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

### Overall
```sql
CREATE EXTENSION IF NOT EXISTS tablefunc;

 SELECT * FROM crosstab( 
   'SELECT sales_id, name, status
    FROM competitors GROUP BY sales_id, name, status ORDER BY sales_id, name',
   -- query to generate the horizontal header
    'SELECT DISTINCT name  FROM competitors ORDER BY name limit 10'
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

### [!]
Lets add a new value into competitors
```sql
insert into competitors (sales_id, name, status ) 
values ('LD01181514885092', 'test', 'ACTIVE')
```
then if we run the same query, we gonna get the error 
```
Query 1 ERROR: ERROR:  invalid return type
DETAIL:  Query-specified return tuple has 11 columns but crosstab returns 12.
```
because we added a new category value that is not included in the crosstab query so its better to limit the query ?

### Lets see what happens if we ommit the second query
```sql
 SELECT * FROM crosstab( 
   -- category query that returns 
   -- 1. rowid
   -- 2. category 
   -- 3. values
   'SELECT sales_id, name, status
    FROM competitors GROUP BY sales_id, name, status ORDER BY sales_id, name'
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

| sales_id         | box       | clickdelivery | deliveras | deliverygr | fagi   | fasterfood | giaola | skroutzfood | vrisko | wolt |
|------------------|-----------|---------------|-----------|------------|--------|------------|--------|-------------|--------|------|
| LD01181514885092 | ACTIVE    | ACTIVE        | ACTIVE    | SUSPENDED  | ACTIVE | ACTIVE     |        |             |        |      |
| LD01181514887676 | SUSPENDED | ACTIVE        |           |            |        |            |        |             |        |      |
| LD01181514929369 | SUSPENDED | SUSPENDED     |           |            |        |            |        |             |        |      |
| LD01181514933165 | SUSPENDED | SUSPENDED     | SUSPENDED |            |        |            |        |             |        |      |
| LD01181514967232 | SUSPENDED | SUSPENDED     |           |            |        |            |        |             |        |      |
| LD01181514967870 | SUSPENDED | SUSPENDED     | SUSPENDED | SUSPENDED  |        |            |        |             |        |      |
| LD01181514968278 | ACTIVE    | ACTIVE        | ACTIVE    | ACTIVE     | ACTIVE | ACTIVE     |        |             |        |      |

as we can we see the values from the first query 

| sales_id         | name          | status    |
|------------------|---------------|-----------|
| LD01181514885092 | box           | ACTIVE    |
| LD01181514885092 | clickdelivery | ACTIVE    |
| LD01181514885092 | deliveras     | ACTIVE    |
| LD01181514885092 | deliverygr    | SUSPENDED |
| LD01181514885092 | skroutzfood   | ACTIVE    |
| LD01181514887676 | clickdelivery | SUSPENDED |
| LD01181514887676 | deliveras     | ACTIVE    |
| LD01181514929369 | clickdelivery | SUSPENDED |
| LD01181514929369 | deliveras     | SUSPENDED |
| LD01181514933165 | clickdelivery | SUSPENDED |
| LD01181514933165 | deliveras     | SUSPENDED |
| LD01181514933165 | deliverygr    | SUSPENDED |
| LD01181514967232 | clickdelivery | SUSPENDED |
| LD01181514967232 | deliveras     | SUSPENDED |
| LD01181514967870 | box           | SUSPENDED |
| LD01181514967870 | clickdelivery | SUSPENDED |
| LD01181514967870 | deliveras     | SUSPENDED |
| LD01181514967870 | giaola        | SUSPENDED |

are not matched correctly with their respective `name` column but are matched in order. So if a shop has 
| sales_id         | name          | status    |
|------------------|---------------|-----------|
| LD01181514929369 | clickdelivery | SUSPENDED |
| LD01181514929369 | deliveras     | SUSPENDED |

the crosstable will add the results to its fields with given order so incorrectly:
| sales_id         | box       | clickdelivery | deliveras | deliverygr | fagi   | fasterfood | giaola | skroutzfood | vrisko | wolt |
|------------------|-----------|---------------|-----------|------------|--------|------------|--------|-------------|--------|------|
| LD01181514929369 | SUSPENDED | SUSPENDED     |           |            |        |            |        |             |        |      |

instead of having clickdelivery = SUSPENDED and deliveras = clickdelivery, it has box and clickdelivery SUSPENDED !!

## Crosstab example 2 
https://postgresql.verite.pro/blog/2018/06/19/crosstab-pivot.html
In this case we have as columns the years and as value the aggregate sum for each city for every month.
We know that every city has records for every year and every month so there is one to one matching with categories fields.
In other words, postgresql get the first query 

```slq
select city, year, sum(raindays) 
FROM rainfall
GROUP BY city, year 
ORDER BY city
```
with output 
| city     | year | sum |
|----------|------|-----|
| Ajaccio  | 2017 |  51 |
| Ajaccio  | 2015 |  48 |
| Ajaccio  | 2016 |  81 |
| Ajaccio  | 2014 |  78 |
| Ajaccio  | 2012 |  69 |
| Ajaccio  | 2013 |  91 |
| Bordeaux | 2016 | 117 |
| Bordeaux | 2014 | 137 |
| Bordeaux | 2012 | 116 |
| Bordeaux | 2013 | 138 |
| Bordeaux | 2015 | 101 |
| Bordeaux | 2017 | 110 |

and match the category field (year) with the next query and get the value.
```sql
SELECT DISTINCT year FROM rainfall ORDER BY year
```
and pass the results to 

```sql
 ct("city" text,
	"2012" int,
	"2013" int,
	"2014" int,
	"2015" int,
	"2016" int,
	"2017" int
```


### Overall
```sql
select * from crosstab(
'select city, year, sum(raindays) 
FROM rainfall
GROUP BY city, year 
ORDER BY city',
 'SELECT DISTINCT year FROM rainfall ORDER BY year'
) AS ct("city" text,
	"2012" int,
	"2013" int,
	"2014" int,
	"2015" int,
	"2016" int,
	"2017" int
)
```

| city      | 2012 | 2013 | 2014 | 2015 | 2016 | 2017 |
|-----------|------|------|------|------|------|------|
| Ajaccio   |   69 |   91 |   78 |   48 |   81 |   51 |
| Bordeaux  |  116 |  138 |  137 |  101 |  117 |  110 |
| Brest     |  178 |  161 |  180 |  160 |  165 |  144 |
| Dijon     |  114 |  124 |  116 |   93 |  116 |  103 |
| Lille     |  153 |  120 |  136 |  128 |  138 |  113 |
| Lyon      |  112 |  116 |  111 |   80 |  110 |  102 |
| Marseille |   47 |   63 |   68 |   53 |   54 |   43 |
| Metz      |   98 |  120 |  110 |   93 |  122 |  115 |
| Nantes    |  124 |  132 |  142 |  111 |  106 |  110 |
| Nice      |   53 |   77 |   78 |   50 |   52 |   43 |
| Paris     |  114 |  111 |  113 |   85 |  120 |  110 |
| Perpignan |   48 |   56 |   54 |   48 |   69 |   48 |
| Toulouse  |   86 |  116 |  111 |   83 |  102 |   89 |

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

## Above other way with nested select !
```sql
SELECT
	cuisines_aggregated.sales_id,
	cuisines_aggregated.cuisines,
	cuisines.name AS main_cuisine
FROM
	(
	SELECT
	sales_id,
	ARRAY_AGG(name) AS cuisines
FROM
	cuisines
GROUP BY
	sales_id
) as cuisines_aggregated
	
LEFT JOIN cuisines ON cuisines.sales_id = cuisines_aggregated.sales_id
WHERE cuisines.main = TRUE
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

## Joining Multiple tables into one view
```sql
SELECT * FROM shops 
LEFT JOIN hq_info on shops.sales_id = hq_info.sales_id
LEFT JOIN legal_entities on shops.sales_id = legal_entities.sales_id
LEFT JOIN locations on shops.sales_id = locations.sales_id
LEFT JOIN (
	SELECT sales_id, ARRAY_AGG(name) as flags_array
	FROM flags
	WHERE value = TRUE
	GROUP BY sales_id
) as flags_aggr  ON flags_aggr.sales_id = shops.sales_id
LEFT JOIN (
	SELECT
		cuisines_aggregated.sales_id,
		cuisines_aggregated.cuisines_array,
		cuisines.name AS main_cuisine
	FROM	
		(
			SELECT sales_id, ARRAY_AGG(name) AS cuisines_array
			FROM cuisines
			GROUP BY sales_id
		) as cuisines_aggregated
		
	LEFT JOIN cuisines ON cuisines.sales_id = cuisines_aggregated.sales_id
	WHERE cuisines.main = TRUE
) as cuisines_aggr ON cuisines_aggr.sales_id = shops.sales_id
	
```

## Enormous view
```sql
CREATE VIEW total_new as (
 SELECT
     shops.sales_id, shops.shop_state,
     shops.shop_name, shops.is_lead, shops.is_archived,
     shops.own_delivery, shops.commission_rate, shops.cable_phone,

     hq_info.hq_id, hq_info.status, hq_info.live_date, hq_info.suspend_date, hq_info.suspend_reason,
     bi_info.shop_tier, bi_info.gmv_group,
     legal_entities.vat_number, legal_entities.business_name, legal_entities.business_type,
     legal_entities.tax_office,

     (locations.city || '-' || locations.area) as region, locations.address, locations.area, locations.city, locations.zip,
     flags_aggr.flags_array,
     cuisines_aggr.cuisines_array, cuisines_aggr.main_cuisine,
     competitors_aggr.*,
     assignees_aggr.*

 FROM
     shops
         LEFT JOIN hq_info ON shops.sales_id = hq_info.sales_id
         LEFT JOIN bi_info ON shops.sales_id = bi_info.sales_id
         LEFT JOIN legal_entities ON shops.sales_id = legal_entities.sales_id
         LEFT JOIN locations ON shops.sales_id = locations.sales_id
         LEFT JOIN (
         SELECT
             sales_id,
             STRING_AGG(name, ',') AS flags_array
         FROM
             flags
         WHERE
                 value = TRUE
         GROUP BY
             sales_id) AS flags_aggr ON flags_aggr.sales_id = shops.sales_id
         LEFT JOIN (
         SELECT
             cuisines_aggregated.sales_id,
             cuisines_aggregated.cuisines_array,
             cuisines.name AS main_cuisine
         FROM (
                  SELECT
                      sales_id,
                      STRING_AGG(name, ',') AS cuisines_array
                  FROM
                      cuisines
                  GROUP BY
                      sales_id) AS cuisines_aggregated
                  LEFT JOIN cuisines ON cuisines.sales_id = cuisines_aggregated.sales_id
         WHERE
                 cuisines.main = TRUE) AS cuisines_aggr ON cuisines_aggr.sales_id = shops.sales_id
         LEFT JOIN (
         SELECT
             sales_id as comp_saled_id, box, clickdelivery, deliveras, deliverygr, fagi, fasterfood, giaola, skroutzfood, vrisko, wolt
         FROM
             crosstab ('SELECT sales_id, name, status ' ||
                       'FROM competitors GROUP BY sales_id, name, status ORDER BY sales_id, name',
                       'SELECT DISTINCT name  FROM competitors ORDER BY name limit 10')
                 AS ct (
                        "sales_id" VARCHAR,
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
                 )) AS competitors_aggr ON competitors_aggr.comp_saled_id = shops.sales_id
         LEFT JOIN (
         SELECT
             sales_id AS ass_saled_id,
             split_part(am, '-', 1) am_assignee,
             split_part(am, '-', 2) am_assignee_name,
             split_part(fs, '-', 1) fs_assignee,
             split_part(fs, '-', 2) fs_assignee_name,
             split_part(menu, '-', 1) menu_assignee,
             split_part(menu, '-', 2) menu_assignee_name,
             split_part(peinata, '-', 1) peinata_assignee,
             split_part(peinata, '-', 2) peinata_assignee_name,
             split_part(promoted, '-', 1) promoted_assignee,
             split_part(promoted, '-', 2) promoted_assignee_name
         FROM
             crosstab ('SELECT a.sales_id, a.service, a.user_id || ''-'' ||  u.name as assignee
                FROM assignees as a
                INNER JOIN users u
                ON u.id = a.user_id
                GROUP BY
                    a.sales_id,
                    a.service,
                    a.user_id,
                    u.name
                ORDER BY a.sales_id, a.service',
                                       $$
                    VALUES('am'),
                    ('fs'),
                    ('menu'),
                    ('peinata'),
                    ('promoted') $$) AS ct ("sales_id" VARCHAR,
                                            "am" VARCHAR,
                            "fs" VARCHAR,
                            "menu" VARCHAR,
                            "peinata" VARCHAR,
                            "promoted" VARCHAR))
         AS assignees_aggr ON assignees_aggr.ass_saled_id = shops.sales_id
);

ALTER VIEW total RENAME TO total_old;
ALTER VIEW total_new RENAME TO total;
DROP VIEW total_old;



```


