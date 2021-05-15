SELECT
	patient_SSN
FROM (
	SELECT
		patient_SSN,
		count(*) AS total
	FROM (
		SELECT
			patient_SSN,
			physician_EmployeeID,
			vaccines_vax_name,
			count(*)
		FROM
			vaccination
		GROUP BY
			patient_SSN,
			physician_EmployeeID,
			vaccines_vax_name) c
	GROUP BY
		patient_SSN
	HAVING
		total = 1) result
