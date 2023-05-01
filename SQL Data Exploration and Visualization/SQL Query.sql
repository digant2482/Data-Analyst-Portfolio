SELECT Customer_ID, Name, Annual_Income, Num_of_Delayed_Payment, Credit_Utilization_Ratio, Total_EMI_per_month, Num_of_Loan, Credit_Score 
FROM sqlprojects..creditcardcustomers

-- Aggregated Data Insights :

   -- INSIGHT 1 : Median num_of_loans per customer
  
   WITH customer_and_loans AS (
	   SELECT Name, MAX(Num_of_Loan) AS Num_of_Loans
	   FROM sqlprojects..creditcardcustomers
	   WHERE Num_of_Loan BETWEEN 0 AND 25
	   GROUP BY Name
   ), 
   loan_counts AS (
	   SELECT Num_of_loans, COUNT(*) OVER (PARTITION BY Num_of_Loans) AS loan_counts
	   FROM customer_and_loans
   )

   SELECT TOP 1 Num_of_loans AS median_no_of_loans
   FROM loan_counts
   ORDER BY loan_counts DESC

   -- Inference : Company insight on median number of loans of the company's customers

   ------------------------------------------------------------------------------------------------------------------------------

   -- INSIGHT 2 : AVG EMI/In hand ratio for clients missing 3 or more payments

   WITH CTE AS (
	   SELECT MAX(Total_EMI_per_month)/MAX(Monthly_Inhand_Salary) AS emi_in_hand_ratio, ROUND(AVG(Num_of_Delayed_Payment), 0) AS avg_delayed_payment
	   FROM sqlprojects..creditcardcustomers
	   GROUP BY Name
	   HAVING ROUND(AVG(Num_of_Delayed_Payment), 0) >= 3
   )

   SELECT ROUND(AVG(emi_in_hand_ratio),3) AS avg_emi_in_hand_ratio_for_high_default
   FROM CTE
   WHERE emi_in_hand_ratio < 1

   -- Inference : For customer paying debts through EMI if the EMI/in-hand ratio crosses 0.04, the probability of default increase significantly

   ------------------------------------------------------------------------------------------------------------------------------

   -- INSIGHT 3 : Inflection point for debt/income ratio and num_of defaults 
  
   SELECT ROUND(MAX(Outstanding_debt)/MAX(Annual_Income),3) AS debt_to_income_ratio, ROUND(AVG(Num_of_Delayed_Payment), 0) AS Avg_delayed_payments
   FROM sqlprojects..creditcardcustomers
   WHERE Num_of_Delayed_Payment  > 3
   GROUP BY Name
   ORDER BY Avg_delayed_payments, debt_to_income_ratio

   -- Inference : After a little bit of data munging we can conculde, that avg_delayed_payment increase drastically after debt_to_income_ratio crosses 0.001

   -------------------------------------------------------------------------------------------------------------------------------

   -- INSIGHT 4 : % of customers with credit utilization more than 80% 

   WITH CTE AS (
	   SELECT Customer_ID, MAX(Credit_Utilization_Ratio) AS max_credit_utilization_ratio
	   FROM sqlprojects..creditcardcustomers
	   GROUP BY Customer_ID
   )

   SELECT Customer_ID, max_credit_utilization_ratio
   FROM CTE
   WHERE max_credit_utilization_ratio > 50

   -- Inference : Overall portfolio of company should have manageable high risk customers, no customer has more than 50% credit utilization

   ------------------------------------------------------------------------------------------------------------------------------

   -- INSIGHT 5 : % of payments that are Large value

   SELECT COUNT(*)/CAST((SELECT COUNT(*) FROM sqlprojects..creditcardcustomers) AS FLOAT)*100
   FROM sqlprojects..creditcardcustomers
   WHERE Payment_Behaviour LIKE '%Large_value%'

   -- OR if dataset is small
   SELECT COUNT(*)/COUNT(t2.ID)*100
   FROM sqlprojects..creditcardcustomers t1 
   LEFT JOIN sqlprojects..creditcardcustomers t2 
	        ON t1.ID = t2.ID 
			AND t2.Payment_Behaviour LIKE '%Large_value%'

   -- Inference : Since only 24% of payments are large value, we could set up a system where the customer is provided with an extra layer of authentication when anything of large values is purchase 

   ------------------------------------------------------------------------------------------------------------------------------

   -- INSIGHT 6 : Mean salary of our customer

   -- Find and remove outliers (customers with more than 100000 salary)
   
   WITH CTE AS (
	   SELECT Customer_ID, MAX(Annual_income) AS annual_income
	   FROM sqlprojects..creditcardcustomers
	   WHERE Annual_income < 100000
	   GROUP BY Customer_ID
   )

   SELECT AVG(annual_income) AS avg_annual_income_of_all_customers
   FROM CTE

   -- Inference : Average income of the customer is 39k adjusting for high income (100k or more salary).

   ------------------------------------------------------------------------------------------------------------------------------

   -- INSIGHT 7 : % of customers with age less than 25 income greater than 100000

   WITH all_customers AS (
	   SELECT Customer_ID AS num_of_customers, MAX(Annual_Income) AS Annual_Income
	   FROM sqlprojects..creditcardcustomers
	   GROUP BY Customer_ID
   )

   SELECT CAST(SUM(CASE WHEN Annual_Income >= 100000 THEN 1 ELSE 0 END) AS FLOAT)/CAST(COUNT(*) AS FLOAT)
   FROM all_customers

   -- TARGET CLIENTS FOR UPSELLING
   DROP TABLE IF EXISTS #HighIncomeLowAgeClients
   CREATE TABLE #HighIncomeLowAgeClients
   (
   Customer_ID nvarchar(255),
   Age float,
   Occupation nvarchar(255),
   Annual_Income float,
   Num_Credit_Card float,
   Credit_Score nvarchar(255)
   )
   
   INSERT INTO #HighIncomeLowAgeClients
   SELECT Customer_ID, MAX(Age), Occupation, MAX(Annual_Income), Max(Num_Credit_Card), Credit_Score 
   FROM sqlprojects..creditcardcustomers
   GROUP BY Customer_ID, Occupation, Credit_Score

   -- Inference : 19 percent of total customers are below age 25 and earns an annual income of more than 100k (Can be target audience)

   ------------------------------------------------------------------------------------------------------------------------------

-- Data Graphical Insights

   -- INSIGHT 1 : Relation between age and high value transactions (trend viewing)

   SELECT Age, COUNT(*) AS num_large_value_txn
   FROM sqlprojects..creditcardcustomers
   WHERE Age < 100 AND Payment_Behaviour LIKE '%Large_value%' AND AGE > 0
   GROUP BY Age
   ORDER BY Age

  -- Inference : PowerBI trend view

  -------------------------------------------------------------------------------------------------------------------------------

  -- INSIGHT 2 : Relation between Missing payment and In hand/Outstanding Debt ratio (Scatter Plot)

  -- Check for outliers

  --SELECT Customer_ID
  --FROM sqlprojects..creditcardcustomers
  --WHERE Annual_Income < 0 AND Outstanding_debt < 0

  SELECT ROUND(MAX(Outstanding_Debt)/MAX(Annual_Income),2) AS debt_income_ratio, MAX(Num_of_Delayed_Payment) AS Num_of_Delayed_Payments
  FROM sqlprojects..creditcardcustomers
  GROUP BY Customer_ID
  HAVING MAX(Outstanding_Debt)/MAX(Annual_Income) < 20
  ORDER BY Num_of_Delayed_Payments DESC, debt_income_ratio DESC 

  -- CREATE VIEW FOR LATER VISUALIZATION 
  CREATE VIEW MissedPaymentVSInhandtoOutstandingRatio AS
  SELECT ROUND(MAX(Outstanding_Debt)/MAX(Annual_Income),2) AS debt_income_ratio, MAX(Num_of_Delayed_Payment) AS Num_of_Delayed_Payments
  FROM sqlprojects..creditcardcustomers
  GROUP BY Customer_ID
  HAVING MAX(Outstanding_Debt)/MAX(Annual_Income) < 20

  -- Inference : PowerBI scatter plot

  -------------------------------------------------------------------------------------------------------------------------------
   
  -- INSIGHT 3: Relation between interest rate and no of delayed payment (Pareto Diagram)

  SELECT COUNT(*) AS num_of_customers, interest_rate, SUM(num_delayed_payment) AS num_delayed_payments, SUM(num_delayed_payment)/COUNT(*) AS delayed_payments_per_customer
  FROM 
	  (SELECT MAX(Interest_Rate) AS interest_rate, MAX(Num_of_Delayed_Payment)  AS num_delayed_payment
	  FROM sqlprojects..creditcardcustomers
	  GROUP BY Customer_ID) t1
  WHERE interest_rate < 50
  GROUP BY interest_rate
  ORDER BY interest_rate DESC, delayed_payments_per_customer DESC, num_delayed_payments

  -- Inference : Interest rate 24,25,26 seems to have least delayed payments per customer
   
  -------------------------------------------------------------------------------------------------------------------------------
  
  -- INSIGHT 4: Relation between no.of inquires & no.delayed payment

  SELECT MAX(Num_Credit_Inquiries) AS num_credit_inquiries, MAX(Num_of_Delayed_Payment) AS num_delayed_payments
  FROM sqlprojects..creditcardcustomers
  WHERE Num_Credit_Inquiries <= 100
  GROUP BY Customer_ID

   -----------------------------------------------------------------------------------------------------------------------------

-- Pie Chart

   -- CHART 1 : customers wrt to profession
   
   WITH CTE AS (
	   SELECT Customer_ID, Occupation
	   FROM sqlprojects..creditcardcustomers
	   GROUP BY Customer_ID, Occupation)

   SELECT Occupation, COUNT(*) AS num_of_customers
   FROM CTE
   WHERE Occupation NOT LIKE '[_]%'
   GROUP BY Occupation

   ------------------------------------------------------------------------------------------------------------------------------

   -- CHART 2 : customers with Good Credit Rating

   SELECT Credit_Score, COUNT(DISTINCT Customer_ID) AS num_of_customers
   FROM sqlprojects..creditcardcustomers
   GROUP BY Credit_Score

   ----------------------------------------------------------END--------------------------------------------------------------------