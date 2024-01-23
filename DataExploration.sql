-- Skills used: Joins, Subqueries, CTE, Windows Functions, Aggregate Functions, Creating Views, Conditional Filters

USE classicmodels;
Show tables;

-- This database has 8 tables: customers, employees, offices, orderdetails, orders, payments, productlines, products 
-- Let's get to know the data

-- Show a list of employees with the name & employee number of their manager.
Select E.employeeNumber, E.firstName, E.lastName, M.employeeNumber as ManagerEmployeeNumber, CONCAT(M.firstName, " ", M.lastName) as ManagerName
From employees E 
LEFT JOIN employees M 
ON E.reportsTo=M.employeeNumber;

-- List all customers whose average payment amount is greater than twice the total average payment
With table1 AS 
(Select a.customerNumber, customerName, Avg(amount) OVER() as Avg, avg(amount) OVER(partition by a.customerNumber Order by a.customernumber) as avg_amount 
From payments as a 
JOIN customers as b
ON a.customerNumber=b.customerNumber
Order by a.customerNumber)
Select DISTINCT customerNumber, customername, Format(avg_amount, 2) as Average_Payment, Format(Avg, 2) as Total_avg_payment
From table1
Where avg_amount > 2*(Select avg(amount) From payments);

-- What is the average percentage markup of the MSRP on buy price for product lines with atleast 5 products?
Select Productline, CONCAT(Format(Avg((MSRP-buyPrice)*100/buyprice), 2), '%') as Markup, count(*) as Product_Count 
From products
Group by productLine
HAVING count(*) >= 5;

-- How many products are there in each product line?
Select  productline, Count(*) From products
Group by productline
Order by productline;

-- Report the contact person name and city of customers who don't have sales representatives?
Select customerName as Customer, CONCAT(contactfirstName,' ', contactLastName) as Contact_Person, city 
From customers
Where salesRepEmployeeNumber is Null
Order by Customer;

-- Report the rolling total orders (Cumulative) by month for each productline
Select Productline, quantityOrdered,
Sum(quantityOrdered) over(Partition by Month(orderdate), Productline ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) Rolling_Total, 
Date_Format(orderdate, '%b') as Month
From orderdetails as a 
JOIN products as b
ON a.productCode=b.productcode 
JOIN orders as c 
ON a.ordernumber=c.ordernumber;

-- Report the products that have not been sold
Select Productcode, Productname From products 
Where productcode not in (Select DISTINCT productcode From orderdetails);

-- What are the names of executives with VP or Manager in their title ? 
Select CONCAT(firstName, ' ',lastName) as Name,  Jobtitle as 'Job Title'
From employees
Where jobtitle LIKE '%VP%' OR jobTitle LIKE '%Manager%';

-- List the products ordered on a Monday.
SELECT productname, Date_Format(orderDate, '%a') as Day From orders as a
JOIN orderdetails as b
ON a.ordernumber = b.ordernumber
JOIN
products as c
ON c.productcode = b.productcode
Where Date_Format(orderDate, '%a') = 'Mon';

-- Report those products that have been sold with a markup of 100% or more (i.e., the priceEach is at least twice the buyPrice)
Drop VIEW if exists df;
CREATE VIEW df AS Select productName, ROUND((priceEach-buyprice)*100/buyPrice,2) as Markup From orderdetails as a
JOIN products as b 
ON a.productcode= b.productCode;

Select DISTINCT productName, Concat(Markup, '%') as Markup From df
Where Markup > 100
Order by Markup;