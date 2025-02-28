-- 1. a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
SELECT npi, COUNT(npi) AS npi_frequency
FROM prescription
GROUP BY npi
ORDER BY npi_frequency DESC;

SELECT prescriber.npi, COUNT(prescription.npi) AS npi_frequency
FROM prescriber
FULL JOIN prescription ON prescriber.npi = prescription.npi
GROUP BY prescriber.npi
ORDER BY npi_frequency DESC;

-- b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.

SELECT prescriber.nppes_provider_first_name, prescriber.nppes_provider_last_org_name, prescriber.specialty_description, npi_count.npi_frequency AS total_num_claims
FROM(
	SELECT prescriber.npi, COUNT(prescription.npi) AS npi_frequency
	FROM prescriber
	FULL JOIN prescription ON prescriber.npi = prescription.npi
	GROUP BY prescriber.npi
	ORDER BY npi_frequency DESC
	) AS npi_count
FULL JOIN prescriber ON npi_count.npi = prescriber.npi
ORDER BY npi_frequency DESC;

-- 2. a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT specialty_description, SUM(total_num_claims) as specialty_total_num_claims
FROM(
	SELECT prescriber.nppes_provider_first_name, prescriber.nppes_provider_last_org_name, prescriber.specialty_description, npi_count.npi_frequency AS total_num_claims
	FROM(
		SELECT prescriber.npi, COUNT(prescription.npi) AS npi_frequency
		FROM prescriber
		FULL JOIN prescription ON prescriber.npi = prescription.npi
		GROUP BY prescriber.npi
		ORDER BY npi_frequency DESC
		) AS npi_count
	FULL JOIN prescriber ON npi_count.npi = prescriber.npi
	ORDER BY npi_frequency DESC
	) AS prescriber_total_claims
GROUP BY specialty_description
ORDER BY specialty_total_num_claims DESC;

-- b. Which specialty had the most total number of claims for opioids?

SELECT specialty_description, COUNT(specialty_description) AS specialty_total_opioid_claims
FROM (
	SELECT prescription.npi, prescription.drug_name, drug.opioid_drug_flag, prescriber.specialty_description
	FROM prescriber
	LEFT JOIN prescription ON prescriber.npi = prescription.npi
	LEFT JOIN drug ON prescription.drug_name = drug.generic_name
	WHERE opioid_drug_flag = 'Y'
	) AS specialty_opioid_claims
GROUP BY specialty_description
ORDER BY specialty_total_opioid_claims DESC;

-- c. Challenge Question: Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

-- Come back!
SELECT prescriber.npi, prescriber.specialty_description, prescriptions_specialties.specialty_description
FROM prescriber
LEFT JOIN (
	SELECT prescription.npi, prescriber.specialty_description
	FROM prescriber
	INNER JOIN prescription ON prescriber.npi = prescription.npi
	) AS prescriptions_specialties
	ON prescriber.npi = prescriptions_specialties.npi
WHERE prescriptions_specialties.npi IS NULL;

-- d. Difficult Bonus: Do not attempt until you have solved all other problems! For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

-- 3. a. Which drug (generic_name) had the highest total drug cost?

SELECT DISTINCT drug_name, total_drug_cost_ge65
FROM prescription
WHERE total_drug_cost_ge65 IS NOT NULL
ORDER BY total_drug_cost_ge65 DESC;

-- b. Which drug (generic_name) has the hightest total cost per day? Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.

SELECT drug_name, ROUND((total_drug_cost / total_day_supply), 2) as total_cost_per_day
FROM prescription
ORDER BY total_cost_per_day DESC;

-- 4. a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. Hint: You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/

SELECT generic_name,
CASE
	WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither' END drug_type
FROM drug;

-- b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT drug_type, SUM(total_drug_cost) AS total_drug_cost_by_type 
FROM prescription
INNER JOIN (
	SELECT generic_name,
	CASE
		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' END drug_type
	FROM drug
) AS drug_types
ON prescription.drug_name = drug_types.generic_name
GROUP BY drug_type
ORDER BY total_drug_cost_by_type DESC;

-- 5. a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee.

SELECT COUNT(cbsa) as cbsa_tn_count
FROM cbsa
WHERE cbsaname LIKE '%, TN';

-- b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

(SELECT cbsa, cbsaname, SUM(population) AS min_and_max_cbsa_population
FROM cbsa
LEFT JOIN population
ON cbsa.fipscounty = population.fipscounty
WHERE population IS NOT NULL
GROUP BY cbsa, cbsaname
ORDER BY min_and_max_cbsa_population DESC
LIMIT 1)
UNION
(SELECT cbsa, cbsaname, SUM(population) AS min_and_max_cbsa_population
FROM cbsa
LEFT JOIN population
ON cbsa.fipscounty = population.fipscounty
WHERE population IS NOT NULL
GROUP BY cbsa, cbsaname
ORDER BY min_and_max_cbsa_population
LIMIT 1);

-- c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT fipscounty, population
FROM population
LEFT JOIN cbsa
USING(fipscounty)
WHERE cbsa IS NULL
ORDER BY population DESC
LIMIT 1;

-- 6. a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000;

-- b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT prescription.drug_name, prescription.total_claim_count, drug.opioid_drug_flag
FROM prescription
LEFT JOIN drug
ON prescription.drug_name = drug.generic_name
WHERE prescription.total_claim_count >= 3000;

-- c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT prescription.npi, prescription.drug_name, prescription.total_claim_count, drug.opioid_drug_flag, CONCAT(prescriber.nppes_provider_first_name, ' ', prescriber.nppes_provider_last_org_name) AS prescriber_name
FROM prescription
LEFT JOIN drug
ON prescription.drug_name = drug.generic_name
LEFT JOIN prescriber
ON prescription.npi = prescriber.npi
WHERE prescription.total_claim_count >= 3000;

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. Hint: The results from all 3 parts will have 637 rows.

-- a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) 
-- in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). 
-- Warning: Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.


SELECT prescriber.npi, CONCAT(prescriber.nppes_provider_first_name, ' ', prescriber.nppes_provider_last_org_name) AS prescriber_name, drug.generic_name, drug.opioid_drug_flag
FROM prescriber
CROSS JOIN drug
WHERE prescriber.nppes_provider_city = 'NASHVILLE'
	AND specialty_description = 'Pain Management'
	AND drug.opioid_drug_flag = 'Y';


-- b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
SELECT 
	prescriber.npi, 
	CONCAT(prescriber.nppes_provider_first_name, ' ', prescriber.nppes_provider_last_org_name) AS prescriber_name, 
	drug.generic_name, 
	SUM(prescription.total_claim_count) AS total_claim_count
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
ON drug.generic_name = prescription.drug_name 
	AND prescriber.npi = prescription.npi
WHERE prescriber.nppes_provider_city = 'NASHVILLE'
	AND specialty_description = 'Pain Management'
	AND drug.opioid_drug_flag = 'Y'
GROUP BY prescriber.npi, prescriber_name, drug.generic_name;

-- c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

SELECT 
	prescriber.npi, 
	CONCAT(prescriber.nppes_provider_first_name, ' ', prescriber.nppes_provider_last_org_name) AS prescriber_name, 
	drug.generic_name, 
	COALESCE(SUM(prescription.total_claim_count), 0) AS total_claim_count
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
ON drug.generic_name = prescription.drug_name 
	AND prescriber.npi = prescription.npi
WHERE prescriber.nppes_provider_city = 'NASHVILLE'
	AND specialty_description = 'Pain Management'
	AND drug.opioid_drug_flag = 'Y'
GROUP BY prescriber.npi, prescriber_name, drug.generic_name
ORDER BY total_claim_count DESC;