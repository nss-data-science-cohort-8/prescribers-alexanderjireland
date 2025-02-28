-- 1. How many npi numbers appear in the prescriber table but not in the prescription table?
SELECT COUNT(*)
FROM
	(
	SELECT DISTINCT npi
	FROM prescriber
	EXCEPT
	SELECT DISTINCT npi
	FROM prescription
	);

-- 2.
--     a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

SELECT prescription.drug_name, SUM(total_claim_count) AS total_claim_count_by_drug
FROM prescriber
FULL JOIN prescription
USING(npi)
WHERE specialty_description = 'Family Practice'
	AND prescription.drug_name IS NOT NULL
GROUP BY prescription.drug_name
ORDER BY total_claim_count_by_drug DESC
LIMIT 5;

--     b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

SELECT prescription.drug_name, SUM(total_claim_count) AS total_claim_count_by_drug
FROM prescriber
FULL JOIN prescription
USING(npi)
WHERE specialty_description = 'Cardiology'
	AND prescription.drug_name IS NOT NULL
GROUP BY prescription.drug_name
ORDER BY total_claim_count_by_drug DESC
LIMIT 5;

--     c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.

SELECT prescription.drug_name, SUM(total_claim_count) AS total_claim_count_by_drug
FROM prescriber
FULL JOIN prescription
USING(npi)
WHERE specialty_description IN ('Family Practice', 'Cardiology')
	AND prescription.drug_name IS NOT NULL
GROUP BY prescription.drug_name
ORDER BY total_claim_count_by_drug DESC
LIMIT 5;

-- 3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
--     a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.

SELECT prescriber.npi, SUM(prescription.total_claim_count) AS total_claims_across_all_drugs, nppes_provider_city AS city
FROM prescriber
FULL JOIN prescription
USING(npi)
WHERE nppes_provider_city = 'NASHVILLE'
	AND prescription.total_claim_count IS NOT NULL
GROUP BY prescriber.npi, city
ORDER BY total_claims_across_all_drugs DESC
LIMIT 5;
	
--     b. Now, report the same for Memphis.

SELECT prescriber.npi, SUM(prescription.total_claim_count) AS total_claims_across_all_drugs, nppes_provider_city AS city
FROM prescriber
FULL JOIN prescription
USING(npi)
WHERE nppes_provider_city = 'MEMPHIS'
	AND prescription.total_claim_count IS NOT NULL
GROUP BY prescriber.npi, city
ORDER BY total_claims_across_all_drugs DESC
LIMIT 5;
    
--     c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.

SELECT prescriber.npi, SUM(prescription.total_claim_count) AS total_claims_across_all_drugs, nppes_provider_city AS city
FROM prescriber
FULL JOIN prescription
USING(npi)
WHERE nppes_provider_city IN ('NASHVILLE', 'MEMPHIS', 'KNOXVILLE', 'CHATTANOOGA')
	AND prescription.total_claim_count IS NOT NULL
GROUP BY prescriber.npi, city
ORDER BY total_claims_across_all_drugs DESC
LIMIT 5;

-- 4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.
SELECT AVG(total_overdoses_by_county)
FROM (
	SELECT SUM(overdose_deaths) as total_overdoses_by_county
	FROM overdose_deaths
	GROUP BY fipscounty
	);

SELECT fipscounty, SUM(overdose_deaths) as total_overdoses_by_county
FROM overdose_deaths
GROUP BY fipscounty
HAVING SUM(overdose_deaths) > (
	SELECT AVG(total_overdoses_by_county)
		FROM (
			SELECT SUM(overdose_deaths) as total_overdoses_by_county
			FROM overdose_deaths
			GROUP BY fipscounty
		)
	)
ORDER BY total_overdoses_by_county DESC;

-- 5.
--     a. Write a query that finds the total population of Tennessee.

SELECT SUM(population) AS total_tn_pop
FROM population
LEFT JOIN fips_county
USING (fipscounty)
WHERE state = 'TN';
	
--     b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, 
--  its population, and the percentage of the total population of Tennessee that is contained in that county.

SELECT 
	fips_county.county, 
	population.population, 
	(100 * population.population / (SELECT SUM(population)
									FROM population
									LEFT JOIN fips_county
									USING (fipscounty)
									WHERE state = 'TN')) AS percent_of_total_tn_pop
FROM population
LEFT JOIN fips_county
USING (fipscounty)
WHERE state = 'TN'
ORDER BY percent_of_total_tn_pop DESC;