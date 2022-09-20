/*

SQL Data Cleaning Project Using Nashville Housing Data

Steps completed below:
1. Standardize the Date Format
2. Populate null Property Address Data
3. Break out PropertyAddress and OwnerAddress into Individual Columns (Street, City, State)
4. Change Y and N to Yes and No in "Sold as Vacant" field
5. Remove Duplicates
6. Delete Unused Columns

*/

Select *
from PortfolioProject.dbo.NashvilleHousing

-----------------------------------------------------------------------------------

-- Standardize Date Format

ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)

Select SaleDateConverted, convert(date,SaleDate)
from PortfolioProject.dbo.NashvilleHousing


-----------------------------------------------------------------------------------

-- Populate Property Address Data

Select *
from PortfolioProject.dbo.NashvilleHousing
where PropertyAddress is null

-- Lots of null values.  Order all data by Parcel ID and see if anything stands out.

Select *
from PortfolioProject.dbo.NashvilleHousing
order by ParcelID

/*

Looking through the data, you'll see duplicates of property addresses. The ParcelID is always the same. So if there is a null property address that has a parcel ID the same as another entry,
you can use the address of the other entry to populate the address field of the null entry.

*/

-- Join the table to itself where the parcel ID is the same, but it's not the same UniqueID.
-- The ISNULL command finds null values in the first listed field, and the corresponding values in the second field

-- Find the null values and show extra column with value that will replace the null values (not yet replacing them)
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
from PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

-- Update the null property values with the duplicate ParcelID address values
UPDATE a -- has to be the alias. If you call out NashvilleHousing, you'll get an error.
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
from PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

-----------------------------------------------------------------------------------

-- Breaking out PropertyAddress into Individual Columns (Street, City, State)

Select PropertyAddress
from PortfolioProject.dbo.NashvilleHousing

-- Use Substring and charindex to find the comma delimiter in the string, and separate the street from the city
SELECT
SUBSTRING(PropertyAddress, 1, charindex(',', PropertyAddress)-1) as Street
, SUBSTRING(PropertyAddress, charindex(',', PropertyAddress)+1, len(PropertyAddress)) as City
From PortfolioProject.dbo.NashvilleHousing

-- Once confirming the above works, add two new columns for the street and city
ALTER TABLE NashvilleHousing
Add PropertyStreet nvarchar(255);

UPDATE NashvilleHousing
SET PropertyStreet = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE NashvilleHousing
Add PropertyCity nvarchar(255);

UPDATE NashvilleHousing
SET PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

-- Check total dataset to see the columns added at the end as expected
Select *
From PortfolioProject.dbo.NashvilleHousing


-- Another method, and looking at the OwnerAddress, which also includes the state.  Instead of SUBSTRING, use PARSENAME.
-- Take a look at the OwnerAddress field to get familiar
SELECT OwnerAddress
From PortfolioProject.dbo.NashvilleHousing

-- Use PARSENAME to pull out the details. Parsename looks for periods, so use REPLACE to change the commas to periods
-- Also, PARSENAME goes backwards, so the first interval will be the state, the 2nd will be the city, the third will be the street.
SELECT
PARSENAME(REPLACE(OwnerAddress, ',','.') ,3) as OwnerStreet
, PARSENAME(REPLACE(OwnerAddress, ',','.') ,2) as OwnerCity
, PARSENAME(REPLACE(OwnerAddress, ',','.') ,1) as OwnerState
From PortfolioProject.dbo.NashvilleHousing

-- Looks good, so now add the columns and the values.

-- Add the columns
ALTER TABLE NashvilleHousing
Add OwnerStreet nvarchar(255);

ALTER TABLE NashvilleHousing
Add OwnerCity nvarchar(255);

ALTER TABLE NashvilleHousing
Add OwnerState nvarchar(255);


-- Add the values to the new columns
UPDATE NashvilleHousing
SET OwnerStreet = PARSENAME(REPLACE(OwnerAddress, ',','.') ,3)

UPDATE NashvilleHousing
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',','.') ,2)

UPDATE NashvilleHousing
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',','.') ,1)


-- Look at the whole dataset to see columns added to the end as expected. REMOVE THIS BEFORE POSTING.
Select *
From PortfolioProject.dbo.NashvilleHousing


-----------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field

-- count the number of each distinct "Sold as Vacant" value and sort by increasing order to see what you're dealing with
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
From PortfolioProject.dbo.NashvilleHousing
Group by SoldAsVacant
Order by 2

-- Case statement as proof before altering the SoldAsVacant column
SELECT SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
From PortfolioProject.dbo.NashvilleHousing

-- Case statement works as intended, so now update the table and set the SoldAsVacant column to all Yes's and No's
UPDATE NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END

-- Check to make sure it worked with intial distinct count command. REMOVE THIS BEFORE POSTING.
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
From PortfolioProject.dbo.NashvilleHousing
Group by SoldAsVacant
Order by 2

-----------------------------------------------------------------------------------

-- Remove Duplicates
/*
Note, normally create a temp table and remove duplicates there. Don't actually remove data from the original table. Though for simplicity on this project,
duplicates will be removed from the base data
*/

-- Write a CTE and use Windows functions to find duplicates

-- Need to partition data in order to rank duplicates. Other commands can be used, but using row numbers here.
-- Ignoring UniqueID to show other ways to identify duplicates.
-- Define a CTE to number duplicates as 2, 3, etc depending on the number of duplicates
WITH RowNumCTE AS(
Select *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From PortfolioProject.dbo.NashvilleHousing
)

-- Delete all the duplicates - called out by the CTE above that numbered duplicates as 2, 3, etc.
DELETE
From RowNumCTE
WHERE row_num > 1

-- Rerunning the CTE and then selecting all duplicates. Should come back empty since we just deleted all duplicates.  REMOVE BEFORE POSTING
WITH RowNumCTE AS(
Select *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From PortfolioProject.dbo.NashvilleHousing
)

Select *
From RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

-----------------------------------------------------------------------------------

-- Delete Unused Columns
/*
Note, don't actually delete unused columns from base data. Just create views that don't show the unused columns
*/

Select *
From PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate