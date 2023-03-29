USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[SaveCost]    Script Date: 12/16/2019 2:04:45 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




--#################################################################################################
-- Name             :  SaveCost
-- Date             :  06/30/2016
-- Author           :  Wayne Hauck
-- Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
-- Purpose          :  This stored procedure saves cost results by JobID into the SavedCost table.
-- Usage            :  n/a
-- Called by        :  n/a
-- Copyright ©      :  Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
-- Change History   :  06/30/2016  Wayne Hauck added comment header
--                     
--#################################################################################################


CREATE PROCEDURE [dbo].[SaveCost]
@JobID INT = -1,
@CETDataDbName VARCHAR(255)=''

AS

SET NOCOUNT ON

DECLARE @SQL1 nvarchar(max)
DECLARE @SQL2 nvarchar(max)

-- Clear SavedKeys table for Job
SET @SQL1 = 'DELETE FROM SavedCost WHERE JobID=' + Convert(nvarchar,@JobID)
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
'INSERT INTO ' + @CETDataDbName + 'SavedCost 
SELECT ' + CONVERT(NVARCHAR,@JobID) + ' AS JobID
      ,[PA]
      ,[PrgID]
      ,[CET_ID]
      ,[IncentiveToOthers]
      ,[DILaborCost]
      ,[DIMaterialCost]
      ,[EndUserRebate]
      ,[RebatesandIncents]
      ,[GrossMeasureCost]
      ,[ExcessIncentives]
	  ,[MarkEffectPlusExcessInc]
      ,[GrossParticipantCost]
      ,[GrossParticipantCostAdjusted]
      ,[NetParticipantCost]
      ,[NetParticipantCostAdjusted]
      ,[RebatesandIncentsPV]
      ,[GrossMeasCostPV]
      ,[ExcessIncentivesPV]
	  ,[MarkEffectPlusExcessIncPV]
      ,[GrossParticipantCostPV]
      ,[GrossParticipantCostAdjustedPV]
      ,[NetParticipantCostPV]
      ,[NetParticipantCostAdjustedPV]
      ,[WtdAdminCostsOverheadAndGA]
      ,[WtdAdminCostsOther]
      ,[WtdMarketingOutreach]
      ,[WtdDIActivity]
      ,[WtdDIInstallation]
      ,[WtdDIHardwareAndMaterials]
      ,[WtdDIRebateAndInspection]
      ,[WtdEMV]
      ,[WtdUserInputIncentive]
      ,[WtdCostsRecoveredFromOtherSources]
      ,[ProgramCosts]
      ,[TotalExpenditures]
      ,[DiscountedSavingsGrosskWh]
      ,[DiscountedSavingsNetkWh]
      ,[DiscountedSavingsGrossThm]
      ,[DiscountedSavingsNetThm]
	  ,TRCLifecycleNetBen
	  ,PACLifecycleNetBen
	  ,LevBenElec
	  ,LevBenGas
	  ,LevTRCCost
	  ,LevTRCCostNoAdmin
	  ,LevPACCost
	  ,LevPACCostNoAdmin
	  ,LevRIMCost
	  ,LevNetBenTRCElec
	  ,LevNetBenTRCElecNoAdmin
	  ,LevNetBenPACElec
	  ,LevNetBenPACElecNoAdmin
	  ,LevNetBenTRCGas
	  ,LevNetBenTRCGasNoAdmin
	  ,LevNetBenPACGas
	  ,LevNetBenPACGasNoAdmin
	  ,LevNetBenRIMElec
	  ,LevNetBenRIMGas
  FROM [dbo].[OutputCost]'

EXEC  sp_executesql @SQL2








GO


