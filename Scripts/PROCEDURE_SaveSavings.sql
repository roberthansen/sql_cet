/*
################################################################################
Name            :  SaveSavings
Date            :  2016-06-30
Author          :  Wayne Hauck
Company         :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose         :  This stored procedure saves savings by JobID into the 
                :  SavedSavings table.
Usage           :  n/a
Called by       :  n/a
Copyright �     :  Developed by Pinnacle Consulting Group (aka Intech Energy,
                :  Inc.) for California Public Utilities Commission (CPUC), All
                :  Rights Reserved
Change History  :  2016-06-30  Wayne Hauck added comment header
                :  2023-03-13  Robert Hansen added new fields for Water Energy
                :              Nexus calculated fields
                :  2023-03-16  Robert Hansen added separate direct and embedded
                :              (i.e., water-energy nexus) savings fields, and
                :              added "Annual" label to otherwise unlabelled
                :              Gross and Net savings fields
                :  2024-04-23  Robert Hansen renamed the "PA" field to
                :              "IOU_AC_Territory"
################################################################################
*/
USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[SaveSavings]    Script Date: 2019-12-16 2:09:19 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SaveSavings]
@JobID INT = -1,
@CETDataDbName VARCHAR(255)=''

AS

SET NOCOUNT ON

DECLARE @SQL1 nvarchar(max)
DECLARE @SQL2 NVARCHAR(MAX)

-- Clear SavedKeys table for Job
SET @SQL1 = 'DELETE FROM SavedSavings WHERE JobID=' + CONVERT(NVARCHAR,@JobID)
EXEC  sp_executesql @SQL1

IF @CETDataDbName =''
    BEGIN
        SET @CETDataDbName = 'dbo.'
    END 
ELSE
    BEGIN
        SET @CETDataDbName = @CETDataDbName + '.dbo.'
    END 

--************** Start Insert  ***************
SET @SQL2 = 
'INSERT INTO ' + @CETDataDbName + 'SavedSavings 
SELECT ' + CONVERT(NVARCHAR,@JobID) + ' AS JobID
      ,[IOU_AC_Territory]
      ,[PrgID]
      ,[CET_ID]
      ,[AnnualGrosskWh]
      ,[AnnualGrosskWhDirect]
      ,[AnnualGrosskWhWater]
      ,[AnnualGrosskW]
      ,[AnnualGrossThm]
      ,[AnnualNetkWh]
      ,[AnnualNetkWhDirect]
      ,[AnnualNetkWhWater]
      ,[AnnualNetkW]
      ,[AnnualNetThm]
      ,[LifecycleGrosskWh]
      ,[LifecycleGrosskWhDirect]
      ,[LifecycleGrosskWhWater]
      ,[LifecycleGrossThm]
      ,[LifecycleNetkWh]
      ,[LifecycleNetkWhDirect]
      ,[LifecycleNetkWhWater]
      ,[LifecycleNetThm]
      ,[GoalAttainmentkWh]
      ,[GoalAttainmentkWhDirect]
      ,[GoalAttainmentkWhWater]
      ,[GoalAttainmentkW]
      ,[GoalAttainmentThm]
      ,[FirstYearGrosskWh]
      ,[FirstYearGrosskWhDirect]
      ,[FirstYearGrosskWhWater]
      ,[FirstYearGrosskW]
      ,[FirstYearGrossThm]
      ,[FirstYearNetkWh]
      ,[FirstYearNetkWhDirect]
      ,[FirstYearNetkWhWater]
      ,[FirstYearNetkW]
      ,[FirstYearNetThm]
      ,[WeightedSavings]
  FROM [dbo].[OutputSavings]'

EXEC  sp_executesql @SQL2

GO