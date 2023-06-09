/*
################################################################################
Name             :  SaveInputCEDARS (procedure)
Date             :  06/30/2016
Author           :  Wayne Hauck
Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose          :  This stored procedure saves inputs by JobID into the
                 :  SavedInputs table.
Usage            :  n/a
Called by        :  n/a
Copyright �      :  Developed by Pinnacle Consulting Group (aka Intech Energy,
                 :  Inc.) for California Public Utilities Commission (CPUC),
                 :  All Rights Reserved
Change History   :  06/30/2016  Wayne Hauck added comment header
                 :  05/25/2021  Robert Hansen removed MarketEffectsBenefits and
                 :  MarketEffectsCosts fields
                 :  2021-06-16  Robert Hansen commented out new fields for fuel
                    substitution for implementation at a later date
                 :  2021-06-16  Robert Hansen commented out new fields for fuel
                    substitution for implementation at a later date

################################################################################
*/

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('dbo.SaveInputCEDARS'))
   exec('CREATE PROCEDURE [dbo].[SaveInputCEDARS] AS BEGIN SET NOCOUNT ON; END')
GO

ALTER PROCEDURE [dbo].[SaveInputCEDARS]
@JobID INT = -1,
@MEBens FLOAT,
@MECost FLOAT,
@CETDataDbName VARCHAR(255)=''
AS
SET NOCOUNT ON

DECLARE @SQL1 nvarchar(max)
DECLARE @SQL2 nvarchar(max)



-- Clear SavedKeys table for Job
SET @SQL1 = 'DELETE FROM SavedInputCEDARS WHERE JobID=' + Convert(nvarchar,@JobID)
EXEC  sp_executesql @SQL1

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
'INSERT INTO ' + @CETDataDbName + 'SavedInputCEDARS
(
[JobID]
,[CEInputID]
,[PA]
,[PrgID]
,[ClaimYearQuarter]
,[MeasDescription]
,[MeasImpactType]
,[MeasCode]
,[MeasureID]
,[E3TargetSector]
,[E3MeaElecEndUseShape]
--,[E3MeaElecAddEndUseShape]
,[E3ClimateZone]
,[E3GasSavProfile]
--,[E3GasAddProfile]
,[E3GasSector]
,RateScheduleElec
,RateScheduleGas
,CombustionType
,[NumUnits]
,[EUL_ID]
,[EUL_Yrs]
,[RUL_ID]
,[RUL_Yrs]
,[NTG_ID]
,[NTGRkW]
,[NTGRkWh]
,[NTGRTherm]
,[NTGRCost]
,MeasInflation
,[InstallationRatekW]
,[InstallationRatekWh]
,[InstallationRateTherm]
,[RealizationRatekW]
,[RealizationRatekWh]
,[RealizationRateTherm]
,[UnitkW1stBaseline]
,[UnitkW2ndBaseline]
,[UnitkWh1stBaseline]
,[UnitkWh2ndBaseline]
,[UnitTherm1stBaseline]
,[UnitTherm2ndBaseline]
--,[UnitAddkW1stBaseline]
--,[UnitAddkW2ndBaseline]
--,[UnitAddkWh1stBaseline]
--,[UnitAddkWh2ndBaseline]
--,[UnitAddTherm1stBaseline]
--,[UnitAddTherm2ndBaseline]
,[UnitMeaCost1stBaseline]
,[UnitMeaCost2ndBaseline]
,[UnitDirectInstallLab]
,[UnitDirectInstallMat]
,[UnitEndUserRebate]
,[UnitIncentiveToOthers]
,[UnitGasInfraBens]
,[UnitRefrigCosts]
,[UnitRefrigBens]
,[UnitMiscCosts]
,[MiscCostsDesc]
,[UnitMiscBens]
,[MiscBensDesc]
,[Sector]
,[UseCategory]
,[UseSubCategory]
,[Residential_Flag]
,[Upstream_Flag]
,[GSIA_ID]
,[BldgType]
,[DeliveryType]
,[MeasAppType]
,[NormUnit]
,[PreDesc]
,[SourceDesc]
,[StdDesc]
,[TechGroup]
,[TechType]
,[Version]
,[Comments]
)

SELECT ' + CONVERT(NVARCHAR,@JobID) + ' AS JobID
,[CEInputID]
,[PA]
,[PrgID]
,[ClaimYearQuarter]
,[MeasDescription]
,[MeasImpactType]
,[MeasCode]
,[MeasureID]
,[E3TargetSector]
,[E3MeaElecEndUseShape]
--,[E3MeaElecAddEndUseShape]
,[E3ClimateZone]
,[E3GasSavProfile]
--,[E3GasAddProfile]
,[E3GasSector]
,RateScheduleElec
,RateScheduleGas
,CombustionType
,[NumUnits]
,[EUL_ID]
,[EUL_Yrs]
,[RUL_ID]
,[RUL_Yrs]
,[NTG_ID]
,[NTGRkW]
,[NTGRkWh]
,[NTGRTherm]
,[NTGRCost]
,MeasInflation
,[InstallationRatekW]
,[InstallationRatekWh]
,[InstallationRateTherm]
,[RealizationRatekW]
,[RealizationRatekWh]
,[RealizationRateTherm]
,[UnitkW1stBaseline]
,[UnitkW2ndBaseline]
,[UnitkWh1stBaseline]
,[UnitkWh2ndBaseline]
,[UnitTherm1stBaseline]
,[UnitTherm2ndBaseline]
--,[UnitAddkW1stBaseline]
--,[UnitAddkW2ndBaseline]
--,[UnitAddkWh1stBaseline]
--,[UnitAddkWh2ndBaseline]
--,[UnitAddTherm1stBaseline]
--,[UnitAddTherm2ndBaseline]
,[UnitMeaCost1stBaseline]
,[UnitMeaCost2ndBaseline]
,[UnitDirectInstallLab]
,[UnitDirectInstallMat]
,[UnitEndUserRebate]
,[UnitIncentiveToOthers]
,[UnitGasInfraBens]
,[UnitRefrigCosts]
,[UnitRefrigBens]
,[UnitMiscCosts]
,[MiscCostsDesc]
,[UnitMiscBens]
,[MiscBensDesc]
,[Sector]
,[UseCategory]
,[UseSubCategory]
,[Residential_Flag]
,[Upstream_Flag]
,[GSIA_ID]
,[BldgType]
,[DeliveryType]
,[MeasAppType]
,[NormUnit]
,[PreDesc]
,[SourceDesc]
,[StdDesc]
,[TechGroup]
,[TechType]
,[Version]
,[Comments]
FROM [dbo].[SourceMeasurevw]'

EXEC  sp_executesql @SQL2

GO