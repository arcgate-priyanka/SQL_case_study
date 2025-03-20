CREATE DATABASE dannys_diner;

-- Create sales table
CREATE TABLE sales (
    customer_id VARCHAR(10),
    order_date DATE,
    product_id INT
);

-- Create menu table
CREATE TABLE menu (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(50),
    price INT
);

-- Create members table
CREATE TABLE members (
    customer_id VARCHAR(10) PRIMARY KEY,
    join_date DATE
);

-- Insert data into sales table
INSERT INTO sales (customer_id, order_date, product_id) VALUES
('A', '2021-01-01', 1),
('A', '2021-01-01', 2),
('A', '2021-01-07', 2),
('A', '2021-01-10', 3),
('A', '2021-01-11', 3),
('A', '2021-01-11', 3),
('B', '2021-01-01', 2),
('B', '2021-01-02', 2),
('B', '2021-01-04', 1),
('B', '2021-01-11', 1),
('B', '2021-01-16', 3),
('B', '2021-02-01', 3),
('C', '2021-01-01', 3),
('C', '2021-01-01', 3),
('C', '2021-01-07', 3);

-- Insert data into menu table
INSERT INTO menu (product_id, product_name, price) VALUES
(1, 'sushi', 10),
(2, 'curry', 15),
(3, 'ramen', 12);

-- Insert data into members table
INSERT INTO members (customer_id, join_date) VALUES
('A', '2021-01-07'),
('B', '2021-01-09');

Select * from sales;
Select * from menu;
Select * from members;

--Q1 What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(m.price) AS total_amount_spent
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;

--Q2 How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS visit_count
FROM sales
GROUP BY customer_id
ORDER BY customer_id;

--Q3 What was the first item from the menu purchased by each customer?
SELECT DISTINCT ON (s.customer_id) s.customer_id, s.order_date, m.product_name
FROM sales s
JOIN menu m ON s.product_id = m.product_id
ORDER BY s.customer_id, s.order_date;

--Q4 What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT m.product_name, COUNT(s.product_id) AS purchase_count
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY purchase_count DESC
LIMIT 1;

--Q5 Which item was the most popular for each customer?
SELECT customer_id, product_name, purchase_count FROM (
    SELECT s.customer_id, m.product_name, COUNT(s.product_id) AS purchase_count,
           RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS rnk
    FROM sales s
    JOIN menu m ON s.product_id = m.product_id
    GROUP BY s.customer_id, m.product_name
) ranked
WHERE rnk = 1;

--Q6 Which item was purchased first by the customer after they became a member?
SELECT DISTINCT ON (s.customer_id) s.customer_id, s.order_date, m.product_name
FROM sales s
JOIN menu m ON s.product_id = m.product_id
JOIN members mem ON s.customer_id = mem.customer_id
WHERE s.order_date >= mem.join_date
ORDER BY s.customer_id, s.order_date;

--Q7 Which item was purchased just before the customer became a member?
SELECT DISTINCT ON (s.customer_id) s.customer_id, s.order_date, m.product_name
FROM sales s
JOIN menu m ON s.product_id = m.product_id
JOIN members mem ON s.customer_id = mem.customer_id
WHERE s.order_date < mem.join_date
ORDER BY s.customer_id, s.order_date DESC;

--Q8 What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, COUNT(s.product_id) AS total_items, SUM(m.price) AS total_spent
FROM sales s
JOIN menu m ON s.product_id = m.product_id
JOIN members mem ON s.customer_id = mem.customer_id
WHERE s.order_date < mem.join_date
GROUP BY s.customer_id
ORDER BY s.customer_id;

--Q9 If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT s.customer_id, 
       SUM(CASE 
           WHEN m.product_name = 'sushi' THEN m.price * 20 
           ELSE m.price * 10 
       END) AS total_points
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;

--Q10 In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT s.customer_id, 
       SUM(CASE 
           WHEN s.order_date BETWEEN mem.join_date AND mem.join_date + INTERVAL '6 days' 
                THEN m.price * 20  -- 2x multiplier for all items
           WHEN m.product_name = 'sushi' THEN m.price * 20  -- Sushi always gets 2x
           ELSE m.price * 10 
       END) AS total_points
FROM sales s
JOIN menu m ON s.product_id = m.product_id
JOIN members mem ON s.customer_id = mem.customer_id
WHERE s.order_date <= '2021-01-31'
GROUP BY s.customer_id
ORDER BY s.customer_id;

--bonus question Join all things

select s.customer_id,
s.order_date,
m.product_name,
m.price,
case when mem.join_date is not null and s.order_date >= mem.join_date then 'Y'
else 'N'
end AS member
from sales s
join menu m on s.product_id = m.product_id
left join members mem on s.customer_id = mem.customer_id
order by s.customer_id, s.order_date

--bonus question Rank all the things
SELECT s.customer_id, 
       s.order_date, 
       m.product_name, 
       m.price,
	   mem.join_date,
       CASE
           WHEN mem.join_date IS NOT NULL AND s.order_date >= mem.join_date THEN 'Y' 
           ELSE 'N'
       END AS member,
       CASE 
           WHEN mem.join_date IS NOT NULL AND s.order_date >= mem.join_date
           THEN RANK() OVER (PARTITION BY s.customer_id, mem.join_date ORDER BY s.order_date, s.product_id) 
           ELSE NULL 
       END AS ranking
FROM sales s
JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members mem ON s.customer_id = mem.customer_id
ORDER BY s.customer_id, s.order_date;

