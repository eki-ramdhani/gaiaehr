SET @Provider = :provider;
SET @StartDate = :begin_date;
SET @EndDate = :end_date;
SET @ProblemCode = :problem_code;
SET @MedicationCode = :medication_code;
SET @MedicationAllergyCode = :allergy_code;
SET @StartDateOrder = :begin_sort;

SELECT patient.*, DATE_FORMAT(patient.DOB, '%d %b %y') as DateOfBirth, Race.option_name as Race, Ethnicity.option_name as Ethnicity
FROM patient

LEFT JOIN (
SELECT distinct(pid) AS pid, code as problem_code
	FROM patient_active_problems
    WHERE CASE
		WHEN @ProblemCode IS NOT NULL
		THEN patient_active_problems.code = @ProblemCode
		ELSE 1=1
	END
    LIMIT 1
) patient_active_problems ON patient.pid = patient_active_problems.pid

LEFT JOIN (
SELECT distinct(pid) as pid, provider_uid, service_date
	FROM encounters
	WHERE CASE
		WHEN (@StartDate IS NOT NULL AND @EndDate IS NULL)
		THEN (encounters.service_date BETWEEN @StartDate AND NOW())
		ELSE 1=1
	END
	AND CASE
		WHEN (@StartDate IS NOT NULL AND @EndDate IS NOT NULL)
		THEN (encounters.service_date BETWEEN @StartDate AND @EndDate)
		ELSE 1=1
	END
	AND CASE
		WHEN (@StartDate IS NULL AND @EndDate IS NOT NULL)
		THEN (encounters.service_date BETWEEN @StartDate AND @EndDate)
		ELSE 1=1
	END
	AND CASE
		WHEN @Provider IS NOT NULL
		THEN encounters.provider_uid = @Provider
		ELSE 1=1
	END
) encounters ON patient.pid = encounters.pid

LEFT JOIN (
SELECT distinct(pid) AS pid, RXCUI as medication_code
	FROM patient_medications
    WHERE CASE
		WHEN @MedicationCode IS NOT NULL
		THEN patient_medications.rxcui = @MedicationCode
    ELSE 1=1
	END
    LIMIT 1
) patient_medications ON patient.pid = patient_medications.pid

LEFT JOIN (
SELECT distinct(pid) AS pid, allergy_code
	FROM patient_allergies
    WHERE CASE
		WHEN @MedicationAllergyCode IS NOT NULL
		THEN patient_allergies.allergy_code = @MedicationAllergyCode
    ELSE 1=1
	END
    LIMIT 1
) patient_allergies ON patient_allergies.pid = patient.pid

LEFT JOIN combo_lists_options as Race ON Race.option_value = patient.race
AND Race.list_id = 14

LEFT JOIN combo_lists_options as Ethnicity ON Ethnicity.option_value = patient.ethnicity
AND Ethnicity.list_id = 59

WHERE CASE
	WHEN @MedicationCode IS NOT NULL
	THEN patient_medications.medication_code = @MedicationCode
	ELSE 1=1
END

AND CASE
	WHEN @Provider IS NOT NULL
	THEN encounters.provider_uid = @Provider
	ELSE 1=1
END

AND CASE
	WHEN (@StartDate IS NOT NULL AND @EndDate IS NULL)
	THEN (encounters.service_date BETWEEN @StartDate AND NOW())
	ELSE 1=1
END
AND CASE
	WHEN (@StartDate IS NOT NULL AND @EndDate IS NOT NULL)
	THEN (encounters.service_date BETWEEN @StartDate AND @EndDate)
	ELSE 1=1
END
AND CASE
	WHEN (@StartDate IS NULL AND @EndDate IS NOT NULL)
	THEN (encounters.service_date BETWEEN @StartDate AND @EndDate)
	ELSE 1=1
END

AND CASE
	WHEN @ProblemCode IS NOT NULL
	THEN patient_active_problems.problem_code = @ProblemCode
	ELSE 1=1
END

AND CASE
	WHEN @MedicationAllergyCode IS NOT NULL
	THEN patient_allergies.allergy_code = @MedicationAllergyCode
	ELSE 1=1
END

ORDER BY
CASE WHEN @StartDateOrder = 'ASC' THEN encounters.service_date END ASC,
CASE WHEN @StartDateOrder = 'DESC' THEN encounters.service_date END DESC

