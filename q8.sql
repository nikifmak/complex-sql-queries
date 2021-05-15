SELECT
	patient.Name
FROM
	patient
WHERE
	SSN NOT IN(
		SELECT
			patient_SSN FROM (
				SELECT
					patient_SSN, vaccines_vax_name, count(*) AS doneShots FROM vaccination
				GROUP BY
					patient_SSN, vaccines_vax_name) AS dTable
				INNER JOIN vaccines ON dTable.vaccines_vax_name = vaccines.vax_name
					AND dTable.doneShots = vaccines.num_of_doses)
