create Procedure sp_ContactDataTransfer
as
begin

BEGIN TRY
BEGIN TRAN
--In here we will first check if the customer is not longer available both in donation system and SalesLT.Customers so we will delete it
--the reason I'm doing it first is it may have more data after new insertions

DELETE FROM dbo.Leads WHERE dbo.Leads.email not in (
SELECT dc.emailaddress1 from dbo.ContactData dc
union all
SELECT sc.EmailAddress FROM SalesLT.Customer sc
)

--the below query will insert data from Donation System(ContactData table) where not exist in lead table

INSERT INTO dbo.Leads (title, firstName, lastName, email, companyName, createdOn, isDynamics,
address1, city, state, zip, country, priPhoneNumber)
--the reason for my below query is to get rows with unique email address
SELECT salutation, firstname, lastname,emailaddress1, company, getdate(), 1, address1_composite,
address1_city, address1_stateorprovince,address1_postalcode, address1_country, telephone1
FROM 
(
SELECT salutation, firstname, lastname,emailaddress1, company, address1_composite,
address1_city, address1_stateorprovince,address1_postalcode, address1_country, telephone1,
Row_number() over (partition by emailaddress1 order by contactid desc) RowId
from 
dbo.ContactData
--in below condition for donotphone I used not equal to 'true' because it can be empty or other value as the data type is varchar
where donotphone != 'true'
) contactData
where RowId = 1 and emailaddress1 not in (SELECT dbo.Leads.email from dbo.Leads)

--now after all unique data is transfered from Donation system to leads we will compare the 
--SalesLT.Customer with Leads which means it is compared with both tables

INSERT INTO dbo.Leads (title, firstName, lastName, email, companyName, createdOn, isSalesLT,
address1, city, state, zip, country, priPhoneNumber)
select  Title, FirstName, LastName,EmailAddress, CompanyName, getdate(), 1,
AddressLine1, City, StateProvince, PostalCode, CountryRegion, Phone
from (
select  C.CustomerID, c.Title, c.FirstName, c.LastName,c.EmailAddress, c.CompanyName,
a.AddressLine1, a.City, a.StateProvince, a.PostalCode, a.CountryRegion, c.Phone,
Row_number() over (partition by c.EmailAddress order by C.CustomerId desc) as RowId 
from SalesLT.Customer c 
LEFT OUTER JOIN  SalesLT.CustomerAddress ca on C.CustomerID=CA.CustomerID
LEFT OUTER join SalesLT.Address a ON ca.AddressID = a.AddressID
) customer
where customer.RowId=2 and EmailAddress not in (SELECT dbo.Leads.email from dbo.Leads) 
and EmailAddress is not null and EmailAddress !=''

--below we will check after transfering data from Donation system and SalesLT if the data from Donation
--is also exist in Sales so we can set the flag to 1 for SaleLT

Update dbo.Leads SET isSalesLT = 1 
WHERE dbo.Leads.email in (select distinct c.EmailAddress from SalesLT.Customer c)

COMMIT
END TRY
BEGIN CATCH
	RAISERROR('Error: The data transfer was not successfull', 16,1)
	ROLLBACK
END CATCH
end
