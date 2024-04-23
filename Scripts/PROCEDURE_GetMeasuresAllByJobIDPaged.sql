/*
################################################################################
Name             :  GetMeasuresAllByJobIDPaged
Date             :  2016-06-30
Author           :  Wayne Hauck
Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose          :  This stored procedure returns measure-level CET results.
                 :  Called when there are large number of records.
Usage            :  n/a
Called by        :  n/a
Copyright        :  Developed by Pinnacle Consulting Group (aka InTech Energy,
                 :  Inc.) for California Public Utilities Commission (CPUC). All
                 :  Rights Reserved.
Change History   :  2016-06-30  Wayne Hauck added comment header
                 :  2024-04-23  Robert Hansen renamed the "PA" field to
                 :              "IOU_AC_Territory"
################################################################################
*/

USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[GetMeasuresAllByJobIDPaged]    Script Date: 2019-12-16 1:43:48 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetMeasuresAllByJobIDPaged]
         @JobID INT
		 ,@StartRow INT = 0
		 ,@NumRows INT = 250

AS
BEGIN


DECLARE @SourceType varchar(255)

SET @SourceType = (SELECT SourceType FROM dbo.CETJobs WHERE ID = @JobID ) 
PRINT 'Source Type = ' + @SourceType

IF @SourceType NOT IN ('CEDARS','CEDARSDatabase', 'CEDARSExcel')
BEGIN  

SELECT  *
FROM     
(
SELECT ROW_NUMBER() OVER (ORDER BY c.ID ASC) AS Row
	    :wq,c.[CET_ID]
      ,c.[IOU_AC_Territory]
      ,c.[PrgID]
	  ,Coalesce(Case When k.ProgramName = '' Then Null else k.ProgramName end ,p.[Program Name],'') ProgramName
      ,k.[MeasureName]
      ,c.[TRCRatio]
      ,c.[PACRatio]
      ,c.[ElecBen]
      ,c.[GasBen]
      ,c.[TRCCost]
      ,c.[PACCost]
      ,c.[TRCRatioNoAdmin]
      ,c.[PACRatioNoAdmin]
      ,c.[TRCCostNoAdmin]
      ,c.[PACCostNoAdmin]
      ,m.[TRCLifecycleNetBen]
      ,m.[PACLifecycleNetBen]
      ,c.[BillReducElec]
      ,c.[BillReducGas]
      ,c.[RIMCost]
	  ,CASE WHEN c.[RIMCost] <> 0 THEN (c.[ElecBen] + c.[GasBen])/c.[RIMCost] ELSE 0 END RIMRatio
      ,c.[WeightedBenefits]
      ,c.[WeightedElecAlloc]
      ,s.[GrossKWh]
      ,s.[GrossKW]
      ,s.[GrossThm]
      ,s.[NetKWh]
      ,s.[NetKW]
      ,s.[NetThm]
      ,s.[GoalAttainmentKWh]
      ,s.[GoalAttainmentKW]
      ,s.[GoalAttainmentThm]
      ,s.[FirstYearGrossKWh]
      ,s.[FirstYearGrossKW]
      ,s.[FirstYearGrossThm]
      ,s.[FirstYearNetKWh]
      ,s.[FirstYearNetKW]
      ,s.[FirstYearNetThm]
      ,s.[LifecycleGrossKWh]
      ,s.[LifecycleGrossThm]
      ,s.[LifecycleNetKWh]
      ,s.[LifecycleNetThm]
      ,e.[NetElecCO2]
      ,e.[NetGasCO2]
      ,e.[GrossElecCO2]
      ,e.[GrossGasCO2]
      ,e.[NetElecCO2Lifecycle]
      ,e.[NetGasCO2Lifecycle]
      ,e.[GrossElecCO2Lifecycle]
      ,e.[GrossGasCO2Lifecycle]
      ,e.[NetElecNOx]
      ,e.[NetGasNOx]
      ,e.[GrossElecNOx]
      ,e.[GrossGasNOx]
      ,e.[NetElecNOxLifecycle]
      ,e.[NetGasNOxLifecycle]
      ,e.[GrossElecNOxLifecycle]
      ,e.[GrossGasNOxLifecycle]
      ,e.[GrossPM10]
      ,e.[NetPM10]
      ,e.[GrossPM10Lifecycle]
      ,e.[NetPM10Lifecycle]
      --,c.[WeightedBenefits]
      --,s.[WeightedSavings]
      ,m.[ProgramCosts] ProgramCosts
      ,m.RebatesandIncents AS TotalIncentives
      ,m.TotalExpenditures AS TotalCosts
      ,m.[WtdAdminCostsOverheadAndGA] [PrgAdminCostsOverheadAndGA]
      ,m.[WtdAdminCostsOther] [PrgAdminCostsOther]
      ,m.[WtdMarketingOutreach] [PrgMarketingOutreach]
      ,m.[WtdDIActivity] [PrgDIActivity]
      ,m.[WtdDIInstallation] [PrgDIInstallation]
      ,m.[WtdDIHardwareAndMaterials] [PrgDIHardwareAndMaterials]
      ,m.[WtdDIRebateAndInspection] [PrgDIRebateAndInspection]
      ,m.[WtdEMV] [PrgEMV] 
      ,m.[WtdUserInputIncentive] [PrgUserInputIncentive]
      ,m.[WtdCostsRecoveredFromOtherSources] [PrgCostsRecoveredFromOtherSources]
      ,m.DILaborCost
      ,m.DIMaterialCost
      ,m.EndUserRebate
      ,m.IncentiveToOthers
      ,m.GrossMeasureCost
      ,m.[ExcessIncentives]
      ,m.[NetParticipantCost]
      ,IsNull(m.[DiscountedSavingsGrosskWh],0) DiscountedSavingsGrosskWh
      ,IsNull(m.[DiscountedSavingsNetkWh],0) DiscountedSavingsNetkWh
      ,IsNull(m.[DiscountedSavingsGrossThm],0) DiscountedSavingsGrossThm
      ,IsNull(m.[DiscountedSavingsNetThm],0) DiscountedSavingsNetThm
      ,m.[LevBenElec]
      ,m.[LevBenGas]
      ,m.[LevTRCCost]
      ,m.[LevTRCCostNoAdmin]
      ,m.[LevPACCost]
      ,m.[LevPACCostNoAdmin]
      ,m.[LevRIMCost]
      ,m.[LevNetBenTRCElec]
      ,m.[LevNetBenTRCElecNoAdmin]
      ,m.[LevNetBenPACElec]
      ,m.[LevNetBenPACElecNoAdmin]
      ,m.[LevNetBenTRCGas]
      ,m.[LevNetBenTRCGasNoAdmin]
      ,m.[LevNetBenPACGas]
      ,m.[LevNetBenPACGasNoAdmin]
      ,m.[LevNetBenRIMElec]
      ,m.[LevNetBenRIMGas]
      ,m.[ProgramCosts] WeightedProgramCost
      ,m.RebatesandIncents MeasureCosts
      ,c.[CET_ID] [CET__ID]
      ,k.[MeasureID]
      ,k.TS [ElecTargetSector]
      ,k.EU [ElecEndUseShape]
      ,k.CZ [ClimateZone]
      ,k.GS [GasSector]
      ,k.GP [GasSavingsProfile]
      ,k.Qtr [ClaimYearQuarter]
      ,k.[Qty]
      ,k.kW1 [UESkW]
      ,k.kWh1 [UESkWh]
      ,k.Thm1 [UESThm]
      ,k.kW2 [UESkW_ER]
      ,k.kWh2 [UESkWh_ER]
      ,k.Thm2 [UESThm_ER]
      ,k.[EUL]
      ,k.[RUL]
      ,k.[NTGRkW]
      ,k.[NTGRkWh]
      ,k.[NTGRThm]
      ,k.[NTGRCost]
      ,k.[IR]
      ,k.[IRkW]
      ,k.[IRkWh]
      ,k.[IRThm]
      ,k.[RRkW]
      ,k.[RRkWh]
      ,k.[RRThm]
      ,k.[UnitMeasureGrossCost]
      ,k.[UnitMeasureGrossCost_ER]
      --,k.[EndUserRebate]
      --,k.[IncentiveToOthers]
      --,k.DILaborCost
      --,k.[DIMaterialCost]
      ,k.[MEBens]
      ,k.[MECost]
      ,k.[Sector]
      ,k.[EndUse]
      ,k.[BuildingType]
      ,k.[MeasureGroup]
      ,k.[SolutionCode]
      ,k.[Technology]
      ,k.[Channel]
      ,k.[IsCustom]
      ,k.[Location]
      ,k.[ProgramType]
      ,k.[UnitType]
      ,k.[Comments]
      ,k.[DataField]
  FROM [SavedCE] c
  LEFT JOIN SavedInput k on c.CET_ID = k.CET_ID
  LEFT JOIN SavedSavings s on c.CET_ID = s.CET_ID
  LEFT JOIN SavedEmissions e on c.CET_ID = e.CET_ID
  LEFT JOIN SavedCost m on c.CET_ID = m.CET_ID
  LEFT JOIN Programs p on e.PrgID = p.[PrgID]
  WHERE  c.JobID = @JobID and s.JobID = @JobID and e.JobID = @JobID and m.JobID = @JobID and k.JobID = @JobID 
  ) tmp
WHERE (Row >= @StartRow AND Row <= @StartRow + @NumRows)

END


IF @SourceType = 'CEDARS' OR @SourceType = 'CEDARSDatabase' OR @SourceType = 'CEDARSExcel'
BEGIN
PRINT 'SELECTING FROM CEDARS'

SELECT  *
FROM     
(
SELECT ROW_NUMBER() OVER (ORDER BY c.ID ASC) AS Row
	    ,c.[CET_ID]
      ,c.[IOU_AC_Territory]
      ,c.[PrgID]
	    ,p.[Program Name] ProgramName
      ,k.[MeasDescription] [MeasureName]
      ,c.[TRCRatio]
      ,c.[PACRatio]
      ,c.[ElecBen]
      ,c.[GasBen]
      ,c.[TRCCost]
      ,c.[PACCost]
      ,c.[TRCRatioNoAdmin]
      ,c.[PACRatioNoAdmin]
      ,c.[TRCCostNoAdmin]
      ,c.[PACCostNoAdmin]
      ,m.[TRCLifecycleNetBen]
      ,m.[PACLifecycleNetBen]
      ,c.[BillReducElec]
      ,c.[BillReducGas]
      ,c.[RIMCost]
	    ,CASE WHEN c.[RIMCost] <> 0 THEN (c.[ElecBen] + c.[GasBen])/c.[RIMCost] ELSE 0 END RIMRatio
      ,c.[WeightedBenefits]
      ,c.[WeightedElecAlloc]
      ,s.[GrossKWh]
      ,s.[GrossKW]
      ,s.[GrossThm]
      ,s.[NetKWh]
      ,s.[NetKW]
      ,s.[NetThm]
      ,s.[GoalAttainmentKWh]
      ,s.[GoalAttainmentKW]
      ,s.[GoalAttainmentThm]
      ,s.[FirstYearGrossKWh]
      ,s.[FirstYearGrossKW]
      ,s.[FirstYearGrossThm]
      ,s.[FirstYearNetKWh]
      ,s.[FirstYearNetKW]
      ,s.[FirstYearNetThm]
      ,s.[LifecycleGrossKWh]
      ,s.[LifecycleGrossThm]
      ,s.[LifecycleNetKWh]
      ,s.[LifecycleNetThm]
      ,e.[NetElecCO2]
      ,e.[NetGasCO2]
      ,e.[GrossElecCO2]
      ,e.[GrossGasCO2]
      ,e.[NetElecCO2Lifecycle]
      ,e.[NetGasCO2Lifecycle]
      ,e.[GrossElecCO2Lifecycle]
      ,e.[GrossGasCO2Lifecycle]
      ,e.[NetElecNOx]
      ,e.[NetGasNOx]
      ,e.[GrossElecNOx]
      ,e.[GrossGasNOx]
      ,e.[NetElecNOxLifecycle]
      ,e.[NetGasNOxLifecycle]
      ,e.[GrossElecNOxLifecycle]
      ,e.[GrossGasNOxLifecycle]
      ,e.[GrossPM10]
      ,e.[NetPM10]
      ,e.[GrossPM10Lifecycle]
      ,e.[NetPM10Lifecycle]
      --,c.[WeightedBenefits]
      --,s.[WeightedSavings]
      ,m.[ProgramCosts] ProgramCosts
      ,m.RebatesandIncents AS TotalIncentives
      ,m.TotalExpenditures AS TotalCosts
      ,m.[WtdAdminCostsOverheadAndGA] [PrgAdminCostsOverheadAndGA]
      ,m.[WtdAdminCostsOther] [PrgAdminCostsOther]
      ,m.[WtdMarketingOutreach] [PrgMarketingOutreach]
      ,m.[WtdDIActivity] [PrgDIActivity]
      ,m.[WtdDIInstallation] [PrgDIInstallation]
      ,m.[WtdDIHardwareAndMaterials] [PrgDIHardwareAndMaterials]
      ,m.[WtdDIRebateAndInspection] [PrgDIRebateAndInspection]
      ,m.[WtdEMV] [PrgEMV] 
      ,m.[WtdUserInputIncentive] [PrgUserInputIncentive]
      ,m.[WtdCostsRecoveredFromOtherSources] [PrgCostsRecoveredFromOtherSources]
      ,m.DILaborCost
      ,m.DIMaterialCost
      ,m.EndUserRebate
      ,m.IncentiveToOthers
      ,m.GrossMeasureCost
      ,m.[ExcessIncentives]
      ,m.[NetParticipantCost]
      ,ISNULL(m.[DiscountedSavingsGrosskWh],0) DiscountedSavingsGrosskWh
      ,ISNULL(m.[DiscountedSavingsNetkWh],0) DiscountedSavingsNetkWh
      ,ISNULL(m.[DiscountedSavingsGrossThm],0) DiscountedSavingsGrossThm
      ,ISNULL(m.[DiscountedSavingsNetThm],0) DiscountedSavingsNetThm
      ,m.[LevBenElec]
      ,m.[LevBenGas]
      ,m.[LevTRCCost]
      ,m.[LevTRCCostNoAdmin]
      ,m.[LevPACCost]
      ,m.[LevPACCostNoAdmin]
      ,m.[LevRIMCost]
      ,m.[LevNetBenTRCElec]
      ,m.[LevNetBenTRCElecNoAdmin]
      ,m.[LevNetBenPACElec]
      ,m.[LevNetBenPACElecNoAdmin]
      ,m.[LevNetBenTRCGas]
      ,m.[LevNetBenTRCGasNoAdmin]
      ,m.[LevNetBenPACGas]
      ,m.[LevNetBenPACGasNoAdmin]
      ,m.[LevNetBenRIMElec]
      ,m.[LevNetBenRIMGas]
      ,m.[ProgramCosts] WeightedProgramCost
      ,m.RebatesandIncents MeasureCosts
      ,c.[CET_ID] [CET__ID]
      ,k.[MeasureID]
      ,k.[E3TargetSector] [ElecTargetSector]
      ,k.[E3MeaElecEndUseShape] [ElecEndUseShape]
      ,k.[E3ClimateZone] [ClimateZone]
      ,k.[E3GasSector] [GasSector]
      ,k.[E3GasSavProfile] [GasSavingsProfile]
      ,k.[ClaimYearQuarter]
      ,k.[NumUnits] [Qty]
      ,k.[UnitkW1stBaseline] [UESkW]
      ,k.[UnitkWh1stBaseline] [UESkWh]
      ,k.[UnitTherm1stBaseline] [UESThm]
      ,k.[UnitkW2ndBaseline] [UESkW_ER]
      ,k.[UnitkWh2ndBaseline] [UESkWh_ER]
      ,k.[UnitTherm2ndBaseline] [UESThm_ER]
      ,k.[EUL_Yrs] [EUL]
      ,k.[RUL_Yrs] [RUL]
      ,k.[NTGRkW]
      ,k.[NTGRkWh]
      ,k.[NTGRTherm] [NTGRThm]
      ,k.[NTGRCost]
      ,k.[InstallationRatekWh] [IR]
      ,k.[InstallationRatekW] [IRkW]
      ,k.[InstallationRatekWh] [IRkWh]
      ,k.[InstallationRateTherm] [IRThm]
      ,k.[RealizationRatekW] [RRkW]
      ,k.[RealizationRatekWh] [RRkWh]
      ,k.[RealizationRateTherm] [RRThm]
      ,k.[UnitMeaCost1stBaseline] [UnitMeasureGrossCost]
      ,k.[UnitMeaCost1stBaseline] [UnitMeasureGrossCost_ER]
      --,k.[EndUserRebate]
      --,k.[IncentiveToOthers]
      --,k.DILaborCost
      --,k.[DIMaterialCost]
      ,NULL [MEBens]
      ,NULL [MECost]
      ,k.[Sector]
      ,COALESCE(k.[UseCategory], k.[UseSubCategory]) [EndUse]
      ,k.[BldgType] [BuildingType]
      ,'' [MeasureGroup]
      ,k.MeasCode [SolutionCode]
      ,k.TechGroup [Technology]
      ,k.DeliveryType [Channel]
      ,k.MeasImpactType [IsCustom]
      ,'' [Location]
      ,k.MeasAppType [ProgramType]
      ,k.Normunit [UnitType]
      ,k.[Comments]
      ,'' [DataField]
  FROM [SavedCE] c
  LEFT JOIN SavedInputCEDARS k ON c.CET_ID = k.CEInputID
  LEFT JOIN SavedSavings s ON c.CET_ID = s.CET_ID
  LEFT JOIN SavedEmissions e ON c.CET_ID = e.CET_ID
  LEFT JOIN SavedCost m ON c.CET_ID = m.CET_ID
  LEFT JOIN Programs p ON e.PrgID = p.[PrgID]
  WHERE  c.JobID = @JobID AND s.JobID = @JobID AND e.JobID = @JobID AND m.JobID = @JobID AND k.JobID = @JobID 
  ) tmp
WHERE (Row >= @StartRow AND Row <= @StartRow + @NumRows)
 
 END



 END


















GO


