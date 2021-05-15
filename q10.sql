SELECT DISTINCT
	(physician.Name)
FROM
	physician
	INNER JOIN (
		SELECT
			trained_in.Physician
		FROM
			trained_in
			INNER JOIN (
				SELECT
					*
				FROM
					treatment
				WHERE
					treatment.Name = 'RADIATION ONCOLOGY') AS radiationList ON trained_in.Speciality = radiationList.Code) AS raditionPhysicians ON physician.EmployeeID = raditionPhysicians.Physician
