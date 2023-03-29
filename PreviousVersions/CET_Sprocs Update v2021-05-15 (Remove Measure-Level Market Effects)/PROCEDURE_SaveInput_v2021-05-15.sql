USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[SaveInput]    Script Date: 12/16/2019 2:06:25 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




--#################################################################################################
-- Name             :  SaveInput
-- Date             :  06/30/2016
-- Author           :  Wayne Hauck
-- Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
-- Purpose          :  This stored procedure saves inputs by JobID into the SavedInputs table.
-- Usage            :  n/a
-- Called by        :  n/a
-- Copyright ©      :  Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
-- Change History   :  06/30/2016  Wayne Hauck added comment header
--                     
--#################################################################################################



CREATE PROCEDURE [dbo].[SaveInput]
@JobID INT = -1,
@MEBens FLOAT,
@MECost FLOAT,
@CETDataDbName VARCHAR(255)=''

AS

SET NOCOUNT ON

DECLARE @SQL1 nvarchar(max)
DECLARE @SQL2 nvarchar(max)

-- Clear SavedKeys table for Job
SET @SQL1 = 'DELETE FROM SavedInput WHERE JobID=' + Convert(nvarchar,@JobID)
EXEC  sp_executesql @SQL1

IF @MEBens Is Null
    BEGIN
        SET @MEBens = IsNull((SELECT MarketEffectBens from CETJobs WHERE ID = @JobID),0)
    END 
IF @MECost Is Null
    BEGIN
        SET @MECost = IsNull((SELECT MarketEffectCost from CETJobs WHERE ID = @JobID),0)
    END 
IF @CETDataDbName =''
    BEGIN
        SET @CETDataDbName = 'dbo.'
    END 
ELSE
    BEGIN
        SET @CETDataDbName = @CETDataDbName + '.dbo.'
    END 

--************** Start Input  ***************
SET @SQL2 = 
'INSERT INTO ' + @CETDataDbName + 'SavedInput  
SELECT
      ' + CONVERT(NVARCHAR,@JobID) + ' AS JobID
      ,[CET_ID]
      ,[PA]
      ,[PrgID]
      ,[ProgramName]
      ,[MeasureName]
      ,[MeasureID]
      ,[TS]
      ,[EU]
      ,[CZ]
      ,[GS]
      ,[GP]
      ,[CombType]
      ,[Qtr]
      ,[Qm]
      ,[Qty]
      ,[kW1]
      ,[kWh1]
      ,[Thm1]
      ,[kW2]
      ,[kWh2]
      ,[Thm2]
      ,[EUL]
      ,[RUL]
      ,[eulq]
      ,[eulq1]
      ,[eulq2]
      ,[rulq]
      ,[NTGRkW]
      ,[NTGRkWh]
      ,[NTGRThm]
      ,[NTGRCost]
      ,[IR]
      ,[IRkW]
      ,[IRkWh]
      ,[IRThm]
      ,[RR]
      ,[RRkWh]
      ,[RRkW]
      ,[RRThm]
      ,[IncentiveToOthers]
      ,[EndUserRebate]
      ,[DILaborCost]
      ,[DIMaterialCost]
      ,[UnitMeasureGrossCost]
      ,[UnitMeasureGrossCost_ER]
      ,[MeasIncrCost]
      ,[MeasInflation]
      ,Coalesce([MEBens],' + CONVERT(VARCHAR,@MEBens) + ') AS MEBens
      ,Coalesce([MECost],' + CONVERT(VARCHAR,@MECost) + ') AS MECost
      ,[Sector]
      ,[EndUse]
      ,[BuildingType]
      ,[MeasureGroup]
      ,[SolutionCode]
      ,[Technology]
      ,[Channel]
      ,[IsCustom]
      ,[Location]
      ,[ProgramType]
      ,[UnitType]
      ,[Comments]
      ,[DataField]
  FROM [dbo].[InputMeasurevw]'

EXEC  sp_executesql @SQL2

GO
