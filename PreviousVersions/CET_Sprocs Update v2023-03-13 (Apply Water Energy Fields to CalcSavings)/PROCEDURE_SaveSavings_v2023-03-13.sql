USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[SaveSavings]    Script Date: 12/16/2019 2:09:19 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/*
################################################################################
Name             :  SaveSavings
Date             :  06/30/2016
Author           :  Wayne Hauck
Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose          :  This stored procedure saves savings by JobID into the 
                 :  SavedSavings table.
Usage            :  n/a
Called by        :  n/a
Copyright �      :  Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
Change History   :  2016-06-30  Wayne Hauck added comment header
                 :  2023-03-13  Robert Hansen added new fields for Water Energy
                 :              Nexus calculated fields
################################################################################
*/

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
      ,[PA]
      ,[PrgID]
      ,[CET_ID]
      ,[GrosskWh]
      ,[GrosskW]
      ,[GrossThm]
      ,[GrosskWhWater]
      ,[NetkWh]
      ,[NetkW]
      ,[NetThm]
      ,[NetkWhWater]
      ,[LifecycleGrosskWh]
      ,[LifecycleGrossThm]
      ,[LifecycleGrosskWhWater]
      ,[LifecycleNetkWh]
      ,[LifecycleNetThm]
      ,[LifecycleNetkWhWater]
      ,[GoalAttainmentkWh]
      ,[GoalAttainmentkW]
      ,[GoalAttainmentThm]
      ,[GoalAttainmentkWhWater]
      ,[FirstYearGrosskWh]
      ,[FirstYearGrosskW]
      ,[FirstYearGrossThm]
      ,[FirstYearGrosskWhWater]
      ,[FirstYearNetkWh]
      ,[FirstYearNetkW]
      ,[FirstYearNetThm]
      ,[FirstYearNetkWhWater]
      ,[WeightedSavings]
  FROM [dbo].[OutputSavings]'

EXEC  sp_executesql @SQL2




GO


