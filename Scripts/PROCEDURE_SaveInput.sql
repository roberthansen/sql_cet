/*
################################################################################
Name             :  SaveInput (procedure)
Date             :  2016-06-30
Author           :  Wayne Hauck
Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose          :  This stored procedure saves inputs by JobID into the
                 :  SavedInputs table.
Usage            :  n/a
Called by        :  n/a
Copyright        :  Developed by Pinnacle Consulting Group (aka Intech Energy,
                 :  Inc.) for California Public Utilities Commission (CPUC),
                 :  All Rights Reserved
Change History   :  2016-06-30  Wayne Hauck added comment header
                 :  2021-05-25  Robert Hansen removed MEBens and MECost fields
                 :  2021-06-16  Robert Hansen commented out new fields for fuel
                 :  substitution for implementation at a later date
                 :  2022-09-02  Robert Hansen added water energy fields:
                 :    + Gal1
                 :    + Gal2
                 :    + kWhWater1
                 :    + kWhWater2
                 :    + kWhTotalWater1
                 :    + kWhTotalWater2
                 :  2023-02-07  Robert Hansen added WaterUse field for tracking
                 :  water-energy nexus measures, and removed extra water energy
                 :  fields not used in CET calculations:
                 :    + Gal1
                 :    + Gal2
                 :    + kWhTotalWater1
                 :    + kWhTotalWater2
                 :  2023-04-04  Robert Hansen implemented sorting on CET_ID for
                 :  output table
                 :  2024-04-23  Robert Hansen renamed the "PA" field to
                 :  "IOU_AC_Territory"
                 :  2024-04-23  Robert Hansen reverted "IOU_AC_Territory" to
                 :  "PA"
                 :  2025-04-11  Robert Hansen added new UnitTaxCredits field
################################################################################
*/

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('dbo.SaveInput'))
   exec('CREATE PROCEDURE [dbo].[SaveInput] AS BEGIN SET NOCOUNT ON; END')
GO

ALTER PROCEDURE [dbo].[SaveInput]
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
(
JobID
,CET_ID
,PA
,PrgID
,ProgramName
,MeasureName
,MeasureID
,TS
,EU
--,EUAL
,CZ
,GS
,GP
--,GPAL
,CombType
,Qtr
,Qm
,Qty
,kW1
,kWh1
,Thm1
,kW2
,kWh2
,Thm2
--,kW1_AL
--,kWh1_AL
--,Thm1_AL
--,kW2_AL
--,kWh2_AL
--,Thm2_AL
,kWhWater1
,kWhWater2
,WaterUse
,EUL
,RUL
,eulq
,eulq1
,eulq2
,rulq
,NTGRkW
,NTGRkWh
,NTGRThm
,NTGRCost
,IR
,IRkW
,IRkWh
,IRThm
,RR
,RRkWh
,RRkW
,RRThm
,IncentiveToOthers
,EndUserRebate
,DILaborCost
,DIMaterialCost
,UnitMeasureGrossCost
,UnitMeasureGrossCost_ER
,MeasIncrCost
,MeasInflation
,UnitGasInfraBens
,UnitRefrigCosts
,UnitRefrigBens
,UnitMiscCosts
,MiscCostsDesc
,UnitMiscBens
,MiscBensDesc
,UnitTaxCredits
,Sector
,EndUse
,BuildingType
,MeasureGroup
,SolutionCode
,Technology
,Channel
,IsCustom
,Location
,ProgramType
,UnitType
,Comments
,DataField
)
SELECT ' + CONVERT(NVARCHAR,@JobID) + ' AS JobID
,CET_ID
,PA
,PrgID
,ProgramName
,MeasureName
,MeasureID
,TS
,EU
--,EUAL
,CZ
,GS
,GP
--,GPAL
,CombType
,Qtr
,Qm
,Qty
,kW1
,kWh1
,Thm1
,kW2
,kWh2
,Thm2
--,kW1_AL
--,kWh1_AL
--,Thm1_AL
--,kW2_AL
--,kWh2_AL
--,Thm2_AL
,kWhWater1
,kWhWater2
,WaterUse
,EUL
,RUL
,eulq
,eulq1
,eulq2
,rulq
,NTGRkW
,NTGRkWh
,NTGRThm
,NTGRCost
,IR
,IRkW
,IRkWh
,IRThm
,RR
,RRkWh
,RRkW
,RRThm
,IncentiveToOthers
,EndUserRebate
,DILaborCost
,DIMaterialCost
,UnitMeasureGrossCost
,UnitMeasureGrossCost_ER
,MeasIncrCost
,MeasInflation
,UnitGasInfraBens
,UnitRefrigCosts
,UnitRefrigBens
,UnitMiscCosts
,MiscCostsDesc
,UnitMiscBens
,MiscBensDesc
,UnitTaxCredits
,Sector
,EndUse
,BuildingType
,MeasureGroup
,SolutionCode
,Technology
,Channel
,IsCustom
,Location
,ProgramType
,UnitType
,Comments
,DataField
FROM [dbo].[InputMeasurevw]
ORDER BY JobID, CET_ID ASC'

EXEC  sp_executesql @SQL2

GO