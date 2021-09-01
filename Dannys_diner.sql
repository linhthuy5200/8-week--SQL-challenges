-- Q1 What is the total amount each customer spent at the restaurant?

SELECT 
  sales.customer_id,
  SUM(menu.price) AS total_spent
FROM dannys_diner..sales
JOIN dannys_diner..menu
  ON sales.product_id = menu.product_id
GROUP BY customer_id
ORDER BY customer_id;

-- Q2. How many days has each customer visited the restaurant?

SELECT customer_id, 
		COUNT(DISTINCT order_date) as visited_day
FROM dannys_diner..sales
GROUP BY customer_id;

--Q3. What was the first item from the menu purchased by each customer?
SELECT CUSTOMER_ID, PRODUCT_NAME 
FROM(
    SELECT RANK() OVER(PARTITION BY dannys_diner..sales.CUSTOMER_ID ORDER BY ORDER_DATE ASC) AS GIVEN_RANK, CUSTOMER_ID, PRODUCT_NAME
    FROM dannys_diner..sales
	JOIN dannys_diner..menu
    ON sales.product_id = menu.product_id
    ) 
    AS RANKED
WHERE RANKED.GIVEN_RANK = 1;

--Q4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT TOP 1
  menu.product_name,
  COUNT(sales.product_id) AS purchased_count
FROM dannys_diner..sales
INNER JOIN dannys_diner..menu
  ON sales.product_id = menu.product_id
GROUP BY menu.product_name
ORDER BY purchased_count DESC

-- Q5. Which item was the most popular for each customer?
With cte AS(
SELECT RANK() OVER (PARTITION BY customer_id ORDER BY frequency DESC) AS ranking, customer_id, product_name
FROM
	( SELECT  customer_id, product_name, COUNT(*) AS frequency
	 FROM dannys_diner..sales
	 INNER JOIN dannys_diner..menu
	ON sales.product_id = menu.product_id
	GROUP BY customer_id, product_name)
	AS max_orders
)

	SELECT customer_id, product_name
    FROM cte
    WHERE ranking = 1;


-- Q6. Which item was purchased first by the customer after they became a member?

WITH ranked AS(
	SELECT RANK() OVER(PARTITION BY sales.customer_id ORDER BY order_date) AS ranking, sales.customer_id, product_id, order_date
	FROM dannys_diner..sales, dannys_diner..members
	WHERE sales.customer_id=members.customer_id AND sales.order_date >= members.join_date
	)

	SELECT ranked.customer_id, menu.product_name
	FROM ranked, dannys_diner..menu
	WHERE ranking =1 AND ranked.product_id=menu.product_id;

--Q7. Which item was purchased just before the customer became a member?

WITH ranked2 AS(
	SELECT RANK() OVER(PARTITION BY sales.customer_id ORDER BY order_date DESC) AS ranking, sales.customer_id, product_id, order_date
	FROM dannys_diner..sales, dannys_diner..members
	WHERE sales.customer_id=members.customer_id AND sales.order_date < members.join_date
	)

	SELECT ranked2.customer_id, menu.product_name
	FROM ranked2, dannys_diner..menu
	WHERE ranking =1 AND ranked2.product_id=menu.product_id;

--Q8. What is the total items and amount spent for each member before they became a member?

WITH total_spent AS(
	SELECT RANK() OVER(PARTITION BY sales.customer_id ORDER BY order_date DESC) AS ranking, sales.customer_id, product_id, order_date
	FROM dannys_diner..sales, dannys_diner..members
	WHERE sales.customer_id=members.customer_id AND sales.order_date < members.join_date
	)
SELECT total_spent.customer_id, COUNT(total_spent.ranking), SUM(price)
FROM total_spent, dannys_diner..menu
WHERE  total_spent.product_id=menu.product_id
GROUP BY total_spent.customer_id


--Q9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT
  customer_id,
  SUM(
  CASE WHEN product_name = 'sushi'
  THEN (price * 20)
  ELSE (price * 10)
  END
  ) AS total_points
FROM dannys_diner..sales
INNER JOIN dannys_diner..menu
ON sales.product_id=menu.product_id
GROUP BY customer_id
ORDER BY customer_id;
