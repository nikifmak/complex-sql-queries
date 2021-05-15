SELECT
	SSN,
	patient.Name,
	e.totalStays,
	e.totalCost
FROM
	patient
	INNER JOIN (
		SELECT
			patient,
			sum(
				COST) AS totalCost,
			totalStays
		FROM (
			SELECT
				treatment.Cost AS
				COST,
				c.Patient AS patient,
				totalStays
			FROM
				treatment
				INNER JOIN (
					SELECT
						undergoes.Patient,
						undergoes.Treatment,
						totalStays
					FROM
						undergoes
						JOIN (
							SELECT
								stay.StayID,
								stay.Patient,
								stay.Room AS room,
								a.totalStays
							FROM
								stay
								INNER JOIN (
									SELECT
										patient,
										COUNT(*) AS totalStays
									FROM
										stay
									GROUP BY
										patient
									HAVING
										totalStays > 1) AS a ON stay.Patient = a.patient) AS b ON undergoes.Patient = b.Patient
								AND undergoes.Stay = b.StayID) AS c ON treatment.Code = c.Treatment) AS d
					GROUP BY
						patient) AS e ON patient.SSN = e.patient
WHERE
	Age BETWEEN 30 AND 40
