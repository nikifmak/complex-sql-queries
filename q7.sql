SELECT
	physician.EmployeeID,
	physician.Name,
	numOfPatientsPerPhysician.numOfpatient
FROM (
	SELECT
		pathologyPhysicians.Physician,
		ifNull(appointmentsPerPhysician.totalAppointments, 0) AS numOfpatient
	FROM (
		SELECT
			*
		FROM
			trained_in
		WHERE
			Speciality in(
				SELECT
					code FROM treatment
				WHERE
					treatment.Name = 'PATHOLOGY')) AS pathologyPhysicians
	LEFT JOIN (
		SELECT
			physician, count(*) AS totalAppointments
		FROM
			appointment
		GROUP BY
			physician) AS appointmentsPerPhysician ON pathologyPhysicians.Physician = appointmentsPerPhysician.physician) AS numOfPatientsPerPhysician
	INNER JOIN physician ON numOfPatientsPerPhysician.Physician = physician.EmployeeID
