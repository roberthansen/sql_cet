USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[SaveProgramCost]    Script Date: 12/16/2019 2:07:54 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


--#################################################################################################
-- Name             :  SaveProgramCost
-- Date             :  06/30/2016
-- Author           :  Wayne Hauck
-- Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
-- Purpose          :  This stored procedure saves program cost inputs by JobID into the SavedProgramCost table.
-- Usage            :  n/a
-- Called by        :  n/a
-- Copyright ©      :  Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
-- Change History   :  06/30/2016  Wayne Hauck added comment header
--                     
--#################################################################################################


CREATE PROCEDURE [dbo].[SaveProgramCost]
@JobID INT = -1,
@CETDataDbName VARCHAR(255)=''

AS

SET NOCOUNT ON

DECLARE @SQL1 NVARCHAR(MAX)
DECLARE @SQL2 NVARCHAR(MAX)

-- Clear SavedKeys table for Job
SET @SQL1 = 'DELETE FROM SavedProgramCost WHERE JobID=' + CONVERT(NVARCHAR,@JobID)
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
'INSERT INTO ' + @CETDataDbName + 'SavedProgramCost 
 SELECT ' + CONVERT(NVARCHAR,@JobID) + ' AS JobID
      ,[PA]
      ,[PrgID]
      ,[ProgramName]
      ,[Year]
      ,[AdminCostsOverheadAndGA]
      ,[AdminCostsOther]
      ,[MarketingOutreach]
      ,[DIActivity]
      ,[DIInstallation]
      ,[DIHardwareAndMaterials]
      ,[DIRebateAndInspection]
      ,[EMV]
      ,[UserInputIncentive]
      ,[CostsRecoveredFromOtherSources]
      ,[OnBillFinancing]
  FROM [dbo].[InputProgramvw]'
  
EXEC  sp_executesql @SQL2




GO


