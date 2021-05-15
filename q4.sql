SELECT
	medication.Name,
	medication.Brand,
	patientsPerMedication.Patients
FROM (
	SELECT
		medication,
		count(*) AS Patients
	FROM
		prescribes
	GROUP BY
		medication
	HAVING
		Patients > 1) AS patientsPerMedication
	LEFT JOIN medication ON patientsPerMedication.medication = medication.code
