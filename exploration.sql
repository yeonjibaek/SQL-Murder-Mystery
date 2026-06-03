-- https://www.kaggle.com/datasets/johnp47/sql-murder-mystery-database
-- https://github.com/NUKnightLab/sql-mysteries

-- SQL Murder Mystery

-- A crime has taken place and the detective needs your help. The detective gave you the crime scene report, but you somehow lost it. You vaguely remember that the crime was a ​murder​ that occurred sometime on ​Jan.15, 2018​ and that it took place in ​SQL City​. Start by retrieving the corresponding crime scene report from the police department’s database. If you want to get the most out of this mystery, try to work through it only using your SQL environment and refrain from using a notepad.


----------------------- STARTS HERE -----------------------

SELECT *
FROM crime_scene_report
WHERE date IS 20180115 
    AND city IS "SQL City"
    AND type IS 'murder';

-- Part 1: There is one specific murder type on January 15, 2018. First witness live at the last house on "Northwestern Dr" while Annabel (the second witness) lives somewhere on "Franklin Ave". I should look for these streets & name!


-- Beginner Method: This method uses two separate queries to search for the two witnesses.
SELECT *
FROM person
WHERE address_street_name IS "Northwestern Dr"
ORDER BY address_number DESC
LIMIT 1;

SELECT *
FROM person
WHERE address_street_name IS "Franklin Ave"
    AND name LIKE '%Annabel%';

-- Intermediate Method: This method uses CTE (Common Table Expressions) to combine the two queries into one.
WITH witness1 AS (
    SELECT *
    FROM person
    WHERE address_street_name = 'Northwestern Dr'
    ORDER BY address_number DESC
    LIMIT 1
),
witness2 AS (
    SELECT *
    FROM person
    WHERE address_street_name = 'Franklin Ave'
        AND name LIKE '%Annabel%'
)

SELECT * FROM witness1
UNION ALL
SELECT * FROM witness2;

-- Advanced Method: WINDOW FUNCTION!!! YAY!!!
WITH ranked_addy AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY address_street_name
            ORDER BY address_number DESC
        ) AS street_rank
    FROM person
    WHERE address_street_name IN ('Northwestern Dr', 'Franklin Ave')
)

SELECT *
FROM ranked_addy
WHERE (address_street_name = 'Northwestern Dr' AND street_rank = 1)
    OR (address_street_name = 'Franklin Ave' AND name LIKE '%Annabel%');

-- Part 2: I tried exploring different methods to show the results for this section. In real world, running a query costs money based on bytes processed. Because of that, I wanted to make sure I could think of different ways to solve this more cost-efficiently. Anyways, it seems like I got the two witnesses (Morty Schapiro #16371 & Annabel Miller #14887)! Maybe it's time to look at the interviews from them.


SELECT id, name, transcript
FROM person p
LEFT JOIN interview i ON p.id = i.person_id
WHERE id IN (16371, 14887);

-- Part 3: For this query, I could've just directly selected from interview table, but I decided I wanted to try out join statement. We got that the murderer was at the "Get Fit Now Gym" on Jan. 9th with membership number starting with "48Z". The suspect is a gold member and has a car with a plate that includes "H42W". (Thanks, Morth and Annabel!) We will first run the license plate and move onto the gym information!


SELECT *
FROM drivers_license d
LEFT JOIN person p 
    ON d.id = p.license_id
WHERE plate_number LIKE '%H42W%'
    AND d.gender = 'male';

-- Part 4: It seems like there is It seems like there is two matches (Jeremy Bowers and Tushar Chandra). We will also check out the gym information to narrow down the murderer.


SELECT *
FROM get_fit_now_member
WHERE membership_status = 'gold'
    AND person_id IN (67318, 51739);

SELECT *
FROM get_fit_now_check_in
WHERE membership_id = '48Z55';

-- Part 5: We found that Jeremy Bowers is a gold member, but not Tushar Chandra! Also, we made sure that we have the right person by checking whether Jeremy Bowers checked into the gym on January 9th. It seems like he did.


SELECT *
FROM interview
WHERE person_id = 67318;

-- Part 6: I checked out if Jeremy Bowers had an interview, and it seems like he did. He says that he was hired by a rich woman and gave lots of information about her appearance. Let's start looking for these clues from the drivers_license table.
-- I was hired by a woman with a lot of money. I don't know her name but I know she's around 5'5" (65") or 5'7" (67"). She has red hair and she drives a Tesla Model S. I know that she attended the SQL Symphony Concert 3 times in December 2017.

SELECT *
FROM drivers_license
WHERE height BETWEEN 65 AND 67
    AND hair_color = 'red'
    AND car_make = 'Tesla'
    AND car_model = 'Model S';

-- Part 7: From here, we got three suspects who all match the description. We will check the income of all three of these women to see if they have higher income and check the events.


SELECT
    id,
    name,
    license_id,
    p.ssn AS ssn,
    annual_income
FROM person p
LEFT JOIN income i ON p.ssn = i.ssn
WHERE license_id IN (202298, 291182, 918773);

SELECT
    *,
    COUNT(person_id) AS count
FROM facebook_event_checkin
WHERE event_name = 'SQL Symphony Concert'
    AND date BETWEEN 20171201 AND 20171231
GROUP BY person_id
ORDER BY count DESC;

SELECT *
FROM person
WHERE id = 99716;

-- Part 8: We found our suspect, Miranda Priestly, who attended SQL Symphony Concert 3 times in December 2017 and has the most income out of the three suspects!


INSERT INTO solution VALUES (1, 'Miranda Priestly');
SELECT value FROM solution;

-- Yay! Mystery solved.