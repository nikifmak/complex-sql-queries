SELECT
	nurse.EmployeeID,
	nurse.Name
FROM (
	SELECT
		Nurse,
		count(*) AS totalBlocks
	FROM
		on_call
	WHERE
		BlockFloor BETWEEN 4 AND 7
		AND OnCallStart >= CAST('2008-04-20 23:22:00' AS DATETIME)
		AND OnCallEnd <= CAST('2009-06-04 11:00:00' AS DATETIME)
	GROUP BY
		Nurse
	HAVING
		totalBlocks > 1) AS nursesOverOneOnCall
	INNER JOIN nurse ON nursesOverOneOnCall.Nurse = nurse.EmployeeID
