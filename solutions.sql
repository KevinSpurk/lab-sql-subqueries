USE sakila;

-- 1- How many copies of the film Hunchback Impossible exist in the inventory system?
SELECT film_id, COUNT(inventory_id) as copy_count 
FROM inventory
WHERE film_id = (
	SELECT film_id FROM film
    WHERE title = 'Hunchback Impossible'
    )
GROUP BY film_id;
-- alternative with subquery in select statement
SELECT i.film_id, f.title, i.copy_count
FROM (
	SELECT film_id, COUNT(inventory_id) as copy_count
	FROM inventory
	GROUP BY film_id
	) i
JOIN film f
ON i.film_id = f.film_id
WHERE title = 'Hunchback Impossible';

-- 2- List all films whose length is longer than the average of all the films.
SELECT * FROM film
WHERE length > (
	SELECT AVG(length) as avg_length FROM film
    );

-- 3- Use subqueries to display all actors who appear in the film Alone Trip.
SELECT fa.actor_id, first_name, last_name, film_id FROM film_actor fa
JOIN actor a
ON fa.actor_id = a.actor_id
WHERE film_id = (
	SELECT film_id FROM film
	WHERE title = 'Alone Trip'
    );

-- 4- Sales have been lagging among young families, and you wish to target all family movies for a promotion. Identify all movies categorized as family films.
SELECT fcc.film_id, f.title, fcc.name as category
FROM (
	SELECT fc.film_id, c.category_id, c.name
	FROM category c
	JOIN film_category fc
	ON c.category_id = fc.category_id
	WHERE c.name = 'Family'
    ) fcc
JOIN film f
ON fcc.film_id = f.film_id;

-- 5 - Get name and email from customers from Canada using subqueries. Do the same with joins. Note that to create a join, you will have to identify the correct tables with their primary keys and foreign keys, that will help you get the relevant information.
-- with subqueries
SELECT first_name, last_name, email
FROM customer
WHERE address_id IN (
	SELECT * 
	FROM (
		SELECT address_id 
		FROM address
		WHERE city_id IN (
			SELECT *
			FROM (
				SELECT city_id AS cnc_id
				FROM city
				WHERE country_id = (SELECT *
					FROM (
						SELECT country_id as can_id 
						FROM ( 
							SELECT country_id
							FROM country
							WHERE country = 'Canada'
							) cn
						) cn2
					) 
				) cy
			)
		) ad
	);

-- with joins
SELECT c.first_name, c.last_name, c.email, country
FROM city cy
JOIN country cn
ON cy.country_id = cn.country_id
JOIN address ad
ON cy.city_id = ad.city_id
JOIN customer c
ON ad.address_id = c.address_id
WHERE country = 'Canada';

-- 6- Which are films starred by the most prolific actor? Most prolific actor is defined as the actor that has acted in the most number of films. First you will have to find the most prolific actor and then use that actor_id to find the different films that he/she starred.
SELECT a1.actor_id, a.first_name, a.last_name, f.title, film_count
FROM (
	SELECT actor_id, film_count 
	FROM (
		SELECT actor_id, COUNT(film_id) AS film_count, RANK() OVER (ORDER BY COUNT(film_id) DESC) AS actor_rank
		FROM film_actor
		GROUP BY actor_id
		) a_rank
	WHERE actor_rank = 1
    ) a1
JOIN film_actor fa
ON a1.actor_id = fa.actor_id
JOIN film f
ON fa.film_id = f.film_id
JOIN actor a
ON a1.actor_id = a.actor_id;

-- 7- Films rented by most profitable customer. You can use the customer table and payment table to find the most profitable customer ie the customer that has made the largest sum of payments
SELECT c1.customer_id, c.first_name, c.last_name, c1.total_amount, f.title
FROM (
	SELECT customer_id, total_amount
	FROM (
		SELECT customer_id, SUM(amount) AS total_amount, RANK() OVER (ORDER BY SUM(amount) DESC) AS amount_rank
		FROM payment
		GROUP BY customer_id
		) c_rank
	WHERE amount_rank = 1
    ) c1
JOIN rental r
ON c1.customer_id = r.customer_id
JOIN customer c
ON c1.customer_id = c.customer_id
JOIN inventory i
ON r.inventory_id = i.inventory_id
JOIN film f
ON i.film_id = f.film_id;

-- 8- Customers who spent more than the average payments.
SELECT p.customer_id, c.first_name, c.last_name, SUM(amount) AS customer_total
FROM payment p
JOIN customer c
ON p.customer_id = c.customer_id
GROUP BY p.customer_id
HAVING customer_total > (
	SELECT p_avg AS payment_avg
	FROM (
		SELECT AVG(customer_total) AS p_avg
		FROM 
			(SELECT customer_id, SUM(amount) AS customer_total
			FROM payment
			GROUP BY customer_id
			) ct
		) p
	)
ORDER BY customer_total DESC;