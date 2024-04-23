USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[SaveEmissions]    Script Date: 12/16/2019 2:05:35 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



--#################################################################################################
-- Name             :  SaveEmissions
-- Date             :  06/30/2016
-- Author           :  Wayne Hauck
-- Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
-- Purpose          :  This stored procedure saves emissions results by JobID into the SavedEmissions table.
-- Usage            :  n/a
-- Called by        :  n/a
-- Copyright �      :  Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
-- Change History   :  06/30/2016  Wayne Hauck added comment header
--                     
--#################################################################################################



CREATE PROCEDURE [dbo].[SaveEmissions]
@JobID INT = -1,
@CETDataDbName VARCHAR(255)=''

AS

SET NOCOUNT ON

DECLARE @SQL1 nvarchar(max)
DECLARE @SQL2 NVARCHAR(MAX)

-- Clear SavedKeys table for Job
SET @SQL1 = 'DELETE FROM SavedEmissions WHERE JobID=' + CONVERT(NVARCHAR,@JobID)
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
'INSERT INTO ' + @CETDataDbName + 'SavedEmissions 
SELECT ' + CONVERT(NVARCHAR,@JobID) + ' AS JobID
      ,[IOU_AC_Territory]
      ,[PrgID]
      ,[CET_ID]
      ,[NetElecCO2]
      ,[NetGasCO2]
      ,[GrossElecCO2]
      ,[GrossGasCO2]
      ,[NetElecCO2Lifecycle]
      ,[NetGasCO2Lifecycle]
      ,[GrossElecCO2Lifecycle]
      ,[GrossGasCO2Lifecycle]
      ,[NetElecNOx]
      ,[NetGasNOx]
      ,[GrossElecNOx]
      ,[GrossGasNOx]
      ,[NetElecNOxLifecycle]
      ,[NetGasNOxLifecycle]
      ,[GrossElecNOxLifecycle]
      ,[GrossGasNOxLifecycle]
      ,[NetPM10]
      ,[GrossPM10]
      ,[NetPM10Lifecycle]
      ,[GrossPM10Lifecycle]
  FROM [dbo].[OutputEmissions]'

EXEC  sp_executesql @SQL2



GO


