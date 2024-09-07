/*

-----------------------------------------------------------------------------------------------------------------------------------
													    Guidelines
-----------------------------------------------------------------------------------------------------------------------------------

Please read the instructions carefully before starting the project.
This is a sql file in which all the instructions and tasks to be performed are mentioned. Read along carefully to complete the project.

Blanks '___' are provided in the notebook that needs to be filled with an appropriate code to get the correct result. Please replace 
the blank with the right code snippet. With every '___' blank.
Identify the task to be performed correctly, and only then proceed to write the required code.
Please run the codes in a sequential manner from the beginning to avoid any unnecessary errors.
Use the results/observations derived from the analysis here to create the business report.

The provided document is a guide for the project. Follow the instructions and take the necessary steps to finish
the project in the SQL file			

-----------------------------------------------------------------------------------------------------------------------------------
                                                         Queries
                                               
-----------------------------------------------------------------------------------------------------------------------------------*/
  USE new_wheels;
/*-- QUESTIONS RELATED TO CUSTOMERS
     [Q1] What is the distribution of customers across states?
     Hint: For each state, count the number of customers.*/

SELECT 
      state, 
      count(*) as no_of_customers
FROM customer_t
GROUP BY state
ORDER BY no_of_customers DESC;

/*--Comments: count(*) function counts the no. of customers for each state and 
groups them using function group by state. The order by function orders(arranges) 
the no. of customers from most to the least by using ORDER BY no_of_customers DESC function.*/

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q2] What is the average rating in each quarter?
-- Very Bad is 1, Bad is 2, Okay is 3, Good is 4, Very Good is 5.

Hint: Use a common table expression and in that CTE, assign numbers to the different customer ratings. 
      Now average the feedback for each quarter. 

Note: For reference, refer to question number 4. Week-2: mls_week-2_gl-beats_solution-1.sql. 
      You'll get an overview of how to use common table expressions from this question.*/


WITH feed_bucket AS
(
    SELECT 
	CASE 
			WHEN customer_feedback = 'Very Good' THEN 5
			WHEN customer_feedback = 'Good' THEN 4
            WHEN customer_feedback = 'Okay' THEN 3
            WHEN customer_feedback = 'Bad' THEN 2
           WHEN customer_feedback = 'Very Bad' THEN 1
			END AS feedback_count,
            quarter_number
	FROM order_t
)
SELECT 
      quarter_number,
      Avg(feedback_count) as avg_feedback
FROM feed_bucket
group by quarter_number
ORDER BY 1;

/*--Comments: This query calculates the average rating for each quarter number based on the feedback obtained*/

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q3] Are customers getting more dissatisfied over time?

Hint: Need the percentage of different types of customer feedback in each quarter. Use a common table expression and
	  determine the number of customer feedback in each category as well as the total number of customer feedback in each quarter.
	  Now use that common table expression to find out the percentage of different types of customer feedback in each quarter.
      Eg: (total number of very good feedback/total customer feedback)* 100 gives you the percentage of very good feedback.
      
Note: For reference, refer to question number 4. Week-2: mls_week-2_gl-beats_solution-1.sql. 
      You'll get an overview of how to use common table expressions from this question.*/
      
WITH cust_feedback AS
(
	SELECT 
		quarter_number,
		SUM(CASE WHEN customer_feedback = 'Very Good' THEN 1 ELSE 0 END) AS very_good,
		SUM(CASE WHEN customer_feedback = 'Good' THEN 1 ELSE 0 END) AS good,
       SUM(CASE WHEN customer_feedback = 'Okay' THEN 1 ELSE 0 END) AS okay,
        SUM(CASE WHEN customer_feedback = 'Bad' THEN 1 ELSE 0 END) AS bad,
       SUM(CASE WHEN customer_feedback = 'Very Bad' THEN 1 ELSE 0 END) AS very_bad,
		COUNT(customer_feedback) AS total_feedbacks
	FROM order_t
	GROUP BY quarter_number
)
SELECT quarter_number,
        (very_good/total_feedbacks)*100 perc_very_good,
        (good/total_feedbacks)*100 perc_good,
        (okay/total_feedbacks)*100 perc_okay,
        (bad/total_feedbacks)*100 perc_bad,
        (very_bad/total_feedbacks)*100 perc_very_bad
FROM cust_feedback
ORDER BY 1;

/* Comments: This query calclates the number of each type of feedback by each quarter and then finds the percentage of each type of feedback--*/

-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q4] Which are the top 5 vehicle makers preferred by the customer.

Hint: For each vehicle make what is the count of the customers.*/


SELECT
      vehicle_maker,
      count(distinct cust.customer_id) number_of_customers  /* counts the unique customers for each vehicle_makers */
FROM product_t pro 
	INNER JOIN order_t ord
	    ON pro.product_id = ord.product_id   /*-- Inner join function joins the product _id with order_id--*/
	INNER JOIN customer_t cust
	    ON ord.customer_id = cust.customer_id /*-- Inner join function joins the order_id with customer_id--*/
GROUP BY vehicle_maker /*-- groups the result by Vehicle_maker--*/
ORDER BY 2 desc 
LIMIT 5;  /*-- limits the top 5 vehicle makers based on number of customers--*/


-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q5] What is the most preferred vehicle make in each state?

Hint: Use the window function RANK() to rank based on the count of customers for each state and vehicle maker. 
After ranking, take the vehicle maker whose rank is 1.*/

SELECT state, vehicle_maker FROM (
	SELECT
		  state,
		  vehicle_maker,
		  count(distinct cust.customer_id) as no_of_cust, /*-- Counts the no. of unique customers for each state and vehicle makers--*/
		  RANK() OVER (partition by state ORDER BY count(distinct cust.customer_id) DESC) AS  rnk /*-- here the vehicle makers are ranked within each state based on the no.of customers in descending order--*/
FROM product_t pro 
	INNER JOIN order_t ord
	    ON pro.product_id = ord.product_id /*-- Inner join function joins the product _id with order_id--*/
	INNER JOIN customer_t cust
	    ON ord.customer_id = cust.customer_id /*-- Inner join function joins the order_id with customer_id--*/
	GROUP BY  state, vehicle_maker) tbl /*-- groups the result by state and vehicle maker--*/
WHERE rnk = 1; /*-- gives only the rank 1 vehicle maker--*/




-- ---------------------------------------------------------------------------------------------------------------------------------

/*QUESTIONS RELATED TO REVENUE and ORDERS 

-- [Q6] What is the trend of number of orders by quarters?

Hint: Count the number of orders for each quarter.*/


SELECT 
	  quarter_number, 
	  COUNT(*) as total_orders
FROM order_t
GROUP BY quarter_number
ORDER BY quarter_number ASC;

/* counts the total no. of orders for each quarter and group the result by quarter number */


-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q7] What is the quarter over quarter % change in revenue? 

Hint: Quarter over Quarter percentage change in revenue means what is the change in revenue from the subsequent quarter to the previous quarter in percentage.
      To calculate you need to use the common table expression to find out the sum of revenue for each quarter.
      Then use that CTE along with the LAG function to calculate the QoQ percentage change in revenue.
*/
      
      
WITH QoQ AS 
(
	SELECT
		  quarter_number,
		 SUM(quantity * (vehicle_price - (discount + shipping))) as revenue
	FROM order_t
	GROUP BY quarter_number
)
SELECT
      quarter_number,
  	  revenue,
     LAG(revenue) OVER (ORDER BY quarter_number) AS previous_revenue,
      ((revenue-LAG(revenue) OVER (ORDER BY quarter_number))/LAG(revenue) OVER (ORDER BY quarter_number))*100 AS qoq_perc_change
FROM QoQ;
      
      
/*--quantity * (vehicle_price - (discount + shipping)) is used to calculate the revenue for each order.
Lag is used to retrieve the revenue from the previous quarter--*/ 
-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q8] What is the trend of revenue and orders by quarters?

Hint: Find out the sum of revenue and count the number of orders for each quarter.*/


SELECT  
      quarter_number,
      SUM(quantity * (vehicle_price - (discount + shipping))) as revenue, /* calculates the sum of revenue from each quarter */
      COUNT(*) AS total_orders
FROM order_t
GROUP BY quarter_number
ORDER BY 1;




-- ---------------------------------------------------------------------------------------------------------------------------------

/* QUESTIONS RELATED TO SHIPPING 
    [Q9] What is the average discount offered for different types of credit cards?

Hint: Find out the average of discount for each credit card type.*/

SELECT 
     credit_card_type, 
     avg(discount) as average_discount
FROM order_t ord 
INNER JOIN customer_t cust
	ON ord.customer_id = cust.customer_id
GROUP BY credit_card_type
ORDER BY 2 DESC;


-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q10] What is the average time taken to ship the placed orders for each quarters?
	Hint: Use the dateiff function to find the difference between the ship date and the order date.
*/

SELECT 
      quarter_number, 
      AVG(DATEDIFF(ship_date, order_date)) as average_shipping_time /* calculates number of days between shipping and order using datediff and later averages for each quarter using average function */
FROM order_t
GROUP BY quarter_number
ORDER BY 1;



-- --------------------------------------------------------Done----------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------
/* ---- Other details to know------
To know the average discounted amount for different credit card type below query can be used.*/

select credit_card_type, avg(discount) as average_discount,
     round(avg((discount/100)* order_t.vehicle_price),2) as average_dicounted_amount
from order_t
inner join product_t 
      on order_t.product_id= product_t.product_id
inner join customer_t
	on order_t.customer_id = customer_t.customer_id
group by credit_card_type
order by 2 desc;


