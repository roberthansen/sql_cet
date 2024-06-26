/*
################################################################################
Name             :  SaveCE (procedure)
Date             :  2016-06-30
Author           :  Wayne Hauck
Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose          :  This stored procedure saves cost effectiveness results by
                 :  JobID into the SavedCE table.
Usage            :  n/a
Called by        :  n/a
Copyright �      :  Developed by Pinnacle Consulting Group (aka Intech Energy,
                 :  Inc.) for California Public Utilities Commission (CPUC),
                 :  All Rights Reserved
Change History   :  2016-06-30  Wayne Hauck added comment header
                 :  2021-05-28  Robert Hansen renamed "NegBens" to "SupplyCost"
                 :  and added Total System Benefits calculations
				 :  2021-07-08  Robert Hansen renamed "TotalSystemBenefits" to
				 :  "TotalSystemBenefit"
				 :  2021-07-09  Robert Hansen added OtherBenGross and
				 :  OtherCostGross fields to outputs
				 :  2024-04-23  Robert Hansen renamed "PA" field to
				 :	"IOU_AC_Territory"
				 :	2024-06-20  Robert Hansen reverted "IOU_AC_Territory" to
				 :	"PA"

################################################################################
*/

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('dbo.SaveCE'))
   exec('CREATE PROCEDURE [dbo].[SaveCE] AS BEGIN SET NOCOUNT ON; END')
GO

ALTER PROCEDURE [dbo].[SaveCE]
@JobID INT = -1,
@CETDataDbName VARCHAR(255)=''

AS

SET NOCOUNT ON

DECLARE @SQL nvarchar(max)

IF @CETDataDbName =''
	BEGIN
		SET @CETDataDbName = 'dbo.'
	END 
ELSE
	BEGIN
		SET @CETDataDbName = @CETDataDbName + '.dbo.'
	END 

-- Clear table for Job
SET @SQL = 'DELETE FROM ' + @CETDataDbName + 'SavedCE WHERE JobID=' + CONVERT(NVARCHAR,@JobID)
EXEC  sp_executesql @SQL

	
--************** Start Validate Input  ***************
SET @SQL = 
'INSERT INTO ' + @CETDataDbName + 'SavedCE  
SELECT ' + CONVERT(NVARCHAR,@JobID) + ' AS JobID
	,[PA]
	,[PrgID]
	,[CET_ID]
	,[ElecBen]
	,[GasBen]
	,[ElecBenGross]
	,[GasBenGross]
	,[OtherBen]
	,[OtherBenGross]
	,[ElecSupplyCost]
	,[GasSupplyCost]
	,[ElecSupplyCostGross]
	,[GasSupplyCostGross]
	,[OtherCost]
	,[OtherCostGross]
	,[TotalSystemBenefit]
	,[TotalSystemBenefitGross]
	,[TRCCost]
	,[PACCost]
	,[TRCCostGross]
	,[TRCCostNoAdmin]
	,[PACCostNoAdmin]
	,[TRCRatio]
	,[PACRatio]
	,[TRCRatioNoAdmin]
	,[PACRatioNoAdmin]
	,[BillReducElec]
	,[BillReducGas]
	,[RIMCost]
	,[WeightedBenefits]
	,[WeightedElecAlloc]
	,[WeightedProgramCost]
FROM [dbo].[OutputCE]'

EXEC  sp_executesql @SQL

GO