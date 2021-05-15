SELECT
	vaccines_vax_name
FROM (
	SELECT
		vaccines_vax_name,
		count(*) AS total
	FROM
		vaccination
	GROUP BY
		vaccines_vax_name
	ORDER BY
		total DESC
	LIMIT 1) AS vaccines_vax_name
