/*
################################################################################
Name             :  GetProgramsAllByJobID
Date             :  2016-06-30
Author           :  Wayne Hauck
Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose          :  This stored procedure returns program-level CET results.
Usage            :  n/a
Called by        :  n/a
Copyright        :  Developed by Pinnacle Consulting Group (aka InTech Energy,
				 :  Inc.) for California Public Utilities Commission (CPUC). All
				 :  Rights Reserved.
Change History   :  2016-06-30  Wayne Hauck added comment header
				 :  2024-04-23  Robert Hansen renamed the "PA" field to
				 :  			"IOU_AC_Territory"
################################################################################
*/
USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[GetProgramsAllByJobID]    Script Date: 2019-12-16 1:47:21 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO








CREATE PROCEDURE [dbo].[GetProgramsAllByJobID]
         @JobID INT		 
AS
BEGIN

--SET FMTONLY OFF;

DECLARE @SourceType varchar(255)

SET @SourceType = (SELECT SourceType FROM dbo.CETJobs WHERE ID = @JobID ) 
PRINT 'Source Type = ' + @SourceType

IF @SourceType NOT IN ('CEDARS','CEDARSDatabase', 'CEDARSExcel')
BEGIN  

SELECT 
      c.[IOU_AC_Territory]
      ,c.[PrgID]
	  ,Coalesce(Case When k.ProgramName = '' Then Null else k.ProgramName end ,p.[Program Name],'') ProgramName
	  ,CASE WHEN Sum(IsNull(c.TRCCost,0)) > 0 THEN (Sum(c.ElecBen) + Sum(c.GasBen))/Sum(c.TRCCost) ELSE 0 END AS TRCRatio
	  ,CASE WHEN Sum(IsNull(c.PACCost,0)) > 0 THEN (Sum(c.ElecBen) + Sum(c.GasBen))/Sum(c.PACCost) ELSE 0 END AS PACRatio
      ,Sum(c.[ElecBen]) ElecBen
      ,Sum(c.[GasBen]) GasBen
      ,IsNull(Sum(c.[TRCCost]), 0) TRCCost
      ,IsNull(Sum(c.[PACCost]), 0) PACCost
	  ,CASE WHEN Sum(IsNull(c.TRCCostNoAdmin,0)) > 0 THEN (Sum(c.ElecBen) + Sum(c.GasBen))/Sum(c.TRCCostNoAdmin) ELSE 0 END AS TRCRatioNoAdmin
	  ,CASE WHEN Sum(IsNull(c.PACCostNoAdmin,0)) > 0 THEN (Sum(c.ElecBen) + Sum(c.GasBen))/Sum(c.PACCostNoAdmin) ELSE 0 END AS PACRatioNoAdmin
      ,Sum(c.[TRCCostNoAdmin]) TRCCostNoAdmin
      ,Sum(c.[PACCostNoAdmin]) PACCostNoAdmin
      ,Sum(m.[TRCLifecycleNetBen]) [TRCLifecycleNetBen]
      ,Sum(m.[PACLifecycleNetBen]) [PACLifecycleNetBen]
      ,Sum(c.[BillReducElec]) [BillReducElec]
      ,Sum(c.[BillReducGas]) [BillReducGas]
      ,Sum(c.[RIMCost]) [RIMCost]
	  ,CASE WHEN Sum(IsNull(c.[RIMCost],0)) <> 0 THEN (Sum(c.ElecBen) + Sum(c.GasBen))/Sum(c.[RIMCost]) ELSE 0 END RIMRatio
      ,Sum(c.[WeightedBenefits]) [WeightedBenefits]
	  ,CASE WHEN (Sum(c.ElecBen) + Sum(c.GasBen)) <> 0 THEN Sum(c.ElecBen)/(Sum(c.GasBen)+Sum(c.ElecBen)) ELSE 0 END AS [WeightedElecAlloc]
      ,Sum(s.[GrossKWh]) GrossKWh
      ,Sum(s.[GrossKW]) GrossKW
      ,Sum(s.[GrossThm]) GrossThm
      ,Sum(s.[NetKWh]) NetKWh
      ,Sum(s.[NetKW]) NetKW
      ,Sum(s.[NetThm]) NetThm
	  ,Sum(s.[GoalAttainmentKWh]) GoalAttainmentKWh
	  ,Sum(s.[GoalAttainmentKW]) GoalAttainmentKW
	  ,Sum(s.[GoalAttainmentThm]) GoalAttainmentThm
	  ,Sum(s.[FirstYearGrossKWh]) FirstYearGrossKWh
	  ,Sum(s.[FirstYearGrossKW]) FirstYearGrossKW
	  ,Sum(s.[FirstYearGrossThm]) FirstYearGrossThm
	  ,Sum(s.[FirstYearNetKWh]) FirstYearNetKWh
	  ,Sum(s.[FirstYearNetKW]) FirstYearNetKW
	  ,Sum(s.[FirstYearNetThm]) FirstYearNetThm
      ,Sum(s.[LifecycleGrossKWh]) LifecycleGrossKWh
      ,Sum(s.[LifecycleGrossThm]) LifecycleGrossThm
      ,Sum(s.[LifecycleNetKWh]) LifecycleNetKWh
      ,Sum(s.[LifecycleNetThm]) LifecycleNetThm
      ,Sum(e.[NetElecCO2]) NetElecCO2
      ,Sum(e.[NetGasCO2]) NetGasCO2
      ,Sum(e.[GrossElecCO2]) GrossElecCO2
      ,Sum(e.[GrossGasCO2]) GrossGasCO2
      ,Sum(e.[NetElecCO2Lifecycle]) NetElecCO2Lifecycle
      ,Sum(e.[NetGasCO2Lifecycle]) NetGasCO2Lifecycle
      ,Sum(e.[GrossElecCO2Lifecycle])  GrossElecCO2Lifecycle
      ,Sum(e.[GrossGasCO2Lifecycle]) GrossGasCO2Lifecycle
      ,Sum(e.[NetElecNOx]) NetElecNOx
      ,Sum(e.[NetGasNOx]) NetGasNOx
      ,Sum(e.[GrossElecNOx]) GrossElecNOx
      ,Sum(e.[GrossGasNOx]) GrossGasNOx
      ,Sum(e.[NetElecNOxLifecycle]) NetElecNOxLifecycle
      ,Sum(e.[NetGasNOxLifecycle]) NetGasNOxLifecycle
      ,Sum(e.[GrossElecNOxLifecycle]) GrossElecNOxLifecycle
      ,Sum(e.[GrossGasNOxLifecycle]) GrossGasNOxLifecycle
      ,Sum(e.[GrossPM10]) GrossPM10
      ,Sum(e.[NetPM10]) NetPM10
      ,Sum(e.[GrossPM10Lifecycle]) GrossPM10Lifecycle
      ,Sum(e.[NetPM10Lifecycle]) NetPM10Lifecycle
	  ,Sum(m.[ProgramCosts]) ProgramCosts
	  ,Sum(m.[DILaborCost]) 
	  +Sum(m.[DIMaterialCost])
	  +Sum(m.[EndUserRebate])
	  +Sum(m.[IncentiveToOthers]) TotalIncentives
	  ,Sum(m.[ProgramCosts])
	  +Sum(m.[DILaborCost]) 
	  +Sum(m.[DIMaterialCost])
	  +Sum(m.[EndUserRebate])
	  +Sum(m.[IncentiveToOthers]) TotalCosts
	  ,Sum(m.[WtdAdminCostsOverheadAndGA]) [PrgAdminCostsOverheadAndGA]
	  ,Sum(m.[WtdAdminCostsOther]) [PrgAdminCostsOther]
	  ,Sum(m.[WtdMarketingOutreach]) [PrgMarketingOutreach]
	  ,Sum(m.[WtdDIActivity]) [PrgDIActivity]
	  ,Sum(m.[WtdDIInstallation]) [PrgDIInstallation]
	  ,Sum(m.[WtdDIHardwareAndMaterials]) [PrgDIHardwareAndMaterials]
	  ,Sum(m.[WtdDIRebateAndInspection]) [PrgDIRebateAndInspection]
	  ,Sum(m.[WtdEMV]) PrgEMV
	  ,Sum(m.[WtdUserInputIncentive]) PrgUserInputIncentive
	  ,Sum(m.[WtdCostsRecoveredFromOtherSources]) [PrgCostsRecoveredFromOtherSources]
	  ,Sum(m.[DILaborCost]) DILaborCost
	  ,Sum(m.[DIMaterialCost]) DIMaterialCost
	  ,Sum(m.[EndUserRebate]) EndUserRebate
	  ,Sum(m.[IncentiveToOthers]) IncentiveToOthers
	  ,Sum(m.[GrossMeasureCost]) GrossMeasureCost
	  ,Sum(m.[ExcessIncentives]) ExcessIncentives
	  ,Sum(m.[NetParticipantCost]) NetParticipantCost
	  ,Sum(IsNull(m.[DiscountedSavingsGrosskWh],0)) DiscountedSavingsGrosskWh
	  ,Sum(IsNull(m.[DiscountedSavingsNetkWh],0)) DiscountedSavingsNetkWh
	  ,Sum(IsNull(m.[DiscountedSavingsGrossThm],0)) DiscountedSavingsGrossThm
	  ,Sum(IsNull(m.[DiscountedSavingsNetThm],0)) DiscountedSavingsNetThm

	  ,CASE WHEN Sum(m.DiscountedSavingsNetkWh) <> 0 THEN Sum(IsNull(c.ElecBen,0))/Sum(m.DiscountedSavingsNetkWh) ELSE 0 END LevBenElec
	  ,CASE WHEN Sum(m.DiscountedSavingsNetThm) <> 0 THEN Sum(IsNull(c.GasBen,0))/Sum(m.DiscountedSavingsNetThm) ELSE 0 END LevBenGas
	  ,CASE WHEN Sum(m.DiscountedSavingsNetkWh) <> 0 AND Sum(c.ElecBen+c.GasBen) <> 0 THEN (Sum(IsNull(c.TRCCost,0)) * Sum(c.ElecBen)/(Sum(c.ElecBen+c.GasBen)))/Sum(m.DiscountedSavingsNetkWh) ELSE 0 END LevTRCCost
	  ,CASE WHEN Sum(m.DiscountedSavingsNetkWh) <> 0 AND Sum(c.ElecBen+c.GasBen) <> 0  THEN (Sum(IsNull(c.TRCCostNoAdmin,0)) * Sum(c.ElecBen)/(Sum(c.ElecBen+c.GasBen)))/Sum(m.DiscountedSavingsNetkWh) ELSE 0 END  LevTRCCostNoAdmin
	  ,CASE WHEN Sum(m.DiscountedSavingsNetkWh) <> 0 AND Sum(c.ElecBen+c.GasBen) <> 0  THEN (Sum(IsNull(c.PACCost,0)) * Sum(c.ElecBen)/(Sum(c.ElecBen+c.GasBen)))/Sum(m.DiscountedSavingsNetkWh) ELSE 0 END  LevPACCost
	  ,CASE WHEN Sum(m.DiscountedSavingsNetkWh) <> 0 AND Sum(c.ElecBen+c.GasBen) <> 0  THEN (Sum(IsNull(c.PACCostNoAdmin,0)) * Sum(c.ElecBen)/(Sum(c.ElecBen+c.GasBen)))/Sum(m.DiscountedSavingsNetkWh) ELSE 0 END  LevPACCostNoAdmin
	  ,CASE WHEN Sum(m.DiscountedSavingsNetkWh) <> 0 AND Sum(c.ElecBen+c.GasBen) <> 0  THEN (Sum(IsNull(c.RIMCost,0)) * Sum(c.ElecBen)/(Sum(c.ElecBen+c.GasBen)))/Sum(m.DiscountedSavingsNetkWh) ELSE 0 END  LevRIMCost
	  ,CASE WHEN Sum(m.DiscountedSavingsNetkWh) <> 0 AND Sum(c.ElecBen+c.GasBen) <> 0  THEN (Sum(IsNull(c.ElecBen,0)) - (Sum(IsNull(c.TRCCost,0)) * Sum(c.ElecBen)/(Sum(c.ElecBen+c.GasBen))))/Sum(m.DiscountedSavingsNetkWh) ELSE 0 END  LevNetBenTRCElec
	  ,CASE WHEN Sum(m.DiscountedSavingsNetkWh) <> 0 AND Sum(c.ElecBen+c.GasBen) <> 0  THEN (Sum(IsNull(c.ElecBen,0)) - (Sum(IsNull(c.TRCCostNoAdmin,0)) * Sum(c.ElecBen)/(Sum(c.ElecBen+c.GasBen))))/Sum(m.DiscountedSavingsNetkWh) ELSE 0 END  LevNetBenTRCElecNoAdmin
	  ,CASE WHEN Sum(m.DiscountedSavingsNetkWh) <> 0 AND Sum(c.ElecBen+c.GasBen) <> 0  THEN (Sum(IsNull(c.ElecBen,0)) - (Sum(IsNull(c.PACCost,0)) * Sum(c.ElecBen)/(Sum(c.ElecBen+c.GasBen))))/Sum(m.DiscountedSavingsNetkWh) ELSE 0 END  LevNetBenPACElec
	  ,CASE WHEN Sum(m.DiscountedSavingsNetkWh) <> 0 AND Sum(c.ElecBen+c.GasBen) <> 0  THEN (Sum(IsNull(c.ElecBen,0)) - (Sum(IsNull(c.PACCostNoAdmin,0)) * Sum(c.ElecBen)/(Sum(c.ElecBen+c.GasBen))))/Sum(m.DiscountedSavingsNetkWh) ELSE 0 END  LevNetBenPACElecNoAdmin
	  ,CASE WHEN Sum(m.DiscountedSavingsNetThm) <> 0 AND Sum(c.ElecBen+c.GasBen) <> 0  THEN (Sum(IsNull(c.GasBen,0)) - (Sum(IsNull(c.TRCCost,0)) * (1-Sum(c.ElecBen)/(Sum(c.ElecBen+c.GasBen)))))/Sum(m.DiscountedSavingsNetThm) ELSE 0 END  LevNetBenTRCGas
	  ,CASE WHEN Sum(m.DiscountedSavingsNetThm) <> 0 AND Sum(c.ElecBen+c.GasBen) <> 0  THEN (Sum(IsNull(c.GasBen,0)) - (Sum(IsNull(c.TRCCostNoAdmin,0)) * (1-Sum(c.ElecBen)/(Sum(c.ElecBen+c.GasBen)))))/Sum(m.DiscountedSavingsNetThm) ELSE 0 END  LevNetBenTRCGasNoAdmin
	  ,CASE WHEN Sum(m.DiscountedSavingsNetThm) <> 0 AND Sum(c.ElecBen+c.GasBen) <> 0  THEN (Sum(IsNull(c.GasBen,0)) - (Sum(IsNull(c.PACCost,0)) * (1-Sum(c.ElecBen)/(Sum(c.ElecBen+c.GasBen)))))/Sum(m.DiscountedSavingsNetThm) ELSE 0 END  LevNetBenPACGas
	  ,CASE WHEN Sum(m.DiscountedSavingsNetThm) <> 0 AND Sum(c.ElecBen+c.GasBen) <> 0  THEN (Sum(IsNull(c.GasBen,0)) - (Sum(IsNull(c.PACCostNoAdmin,0)) * (1-Sum(c.ElecBen)/(Sum(c.ElecBen+c.GasBen)))))/Sum(m.DiscountedSavingsNetThm) ELSE 0 END  LevNetBenPACGasNoAdmin
	  ,CASE WHEN Sum(m.DiscountedSavingsNetkWh) <> 0 AND Sum(c.ElecBen+c.GasBen) <> 0  THEN (Sum(IsNull(c.ElecBen,0)) - (Sum(IsNull(c.RIMCost,0)) * Sum(c.ElecBen)/(Sum(c.ElecBen+c.GasBen))))/Sum(m.DiscountedSavingsNetkWh) ELSE 0 END  LevNetBenRIMElec
	  ,CASE WHEN Sum(m.DiscountedSavingsNetThm) <> 0 AND Sum(c.ElecBen+c.GasBen) <> 0  THEN (Sum(IsNull(c.GasBen,0)) - (Sum(IsNull(c.RIMCost,0)) * (1-Sum(c.ElecBen)/(Sum(c.ElecBen+c.GasBen)))))/Sum(m.DiscountedSavingsNetThm) ELSE 0 END  LevNetBenRIMGas

  FROM [SavedCE] c
  LEFT JOIN SavedSavings s on c.CET_ID = s.CET_ID
  LEFT JOIN SavedEmissions e on c.CET_ID = e.CET_ID
  LEFT JOIN SavedInput k on c.CET_ID = k.CET_ID
  LEFT JOIN SavedCost m on c.CET_ID = m.CET_ID
  LEFT JOIN Programs p on e.PrgID = p.[PrgID]
  WHERE c.JobID = @JobID and s.JobID = @JobID and  e.JobID = @JobID and k.JobID = @JobID and m.JobID = @JobID
  Group By c.IOU_AC_Territory, c.PrgID, k.ProgramName,p.[Program Name] 
  Order By c.IOU_AC_Territory, c.PrgID 

END

IF @SourceType = 'CEDARS' OR @SourceType = 'CEDARSDatabase' OR @SourceType = 'CEDARSExcel'
BEGIN
PRINT 'SELECTING FROM CEDARS'
SELECT 
      c.[IOU_AC_Territory]
      ,c.[PrgID]
	  ,p.[Program Name] ProgramName
	  ,CASE WHEN SUM(ISNULL(c.TRCCost,0)) > 0 THEN (SUM(c.ElecBen) + SUM(c.GasBen))/SUM(c.TRCCost) ELSE 0 END AS TRCRatio
	  ,CASE WHEN SUM(ISNULL(c.PACCost,0)) > 0 THEN (SUM(c.ElecBen) + SUM(c.GasBen))/SUM(c.PACCost) ELSE 0 END AS PACRatio
      ,SUM(c.[ElecBen]) ElecBen
      ,SUM(c.[GasBen]) GasBen
      ,ISNULL(SUM(c.[TRCCost]), 0) TRCCost
      ,ISNULL(SUM(c.[PACCost]), 0) PACCost
	  ,CASE WHEN SUM(ISNULL(c.TRCCostNoAdmin,0)) > 0 THEN (SUM(c.ElecBen) + SUM(c.GasBen))/SUM(c.TRCCostNoAdmin) ELSE 0 END AS TRCRatioNoAdmin
	  ,CASE WHEN SUM(ISNULL(c.PACCostNoAdmin,0)) > 0 THEN (SUM(c.ElecBen) + SUM(c.GasBen))/SUM(c.PACCostNoAdmin) ELSE 0 END AS PACRatioNoAdmin
      ,SUM(c.[TRCCostNoAdmin]) TRCCostNoAdmin
      ,SUM(c.[PACCostNoAdmin]) PACCostNoAdmin
      ,SUM(m.[TRCLifecycleNetBen]) [TRCLifecycleNetBen]
      ,SUM(m.[PACLifecycleNetBen]) [PACLifecycleNetBen]
      ,SUM(c.[BillReducElec]) [BillReducElec]
      ,SUM(c.[BillReducGas]) [BillReducGas]
      ,SUM(c.[RIMCost]) [RIMCost]
	  ,CASE WHEN SUM(ISNULL(c.[RIMCost],0)) <> 0 THEN (SUM(c.ElecBen) + SUM(c.GasBen))/SUM(c.[RIMCost]) ELSE 0 END RIMRatio
      ,SUM(c.[WeightedBenefits]) [WeightedBenefits]
	  ,CASE WHEN (SUM(c.ElecBen) + SUM(c.GasBen)) <> 0 THEN SUM(c.ElecBen)/(SUM(c.GasBen)+SUM(c.ElecBen)) ELSE 0 END AS [WeightedElecAlloc]
      ,SUM(s.[GrossKWh]) GrossKWh
      ,SUM(s.[GrossKW]) GrossKW
      ,SUM(s.[GrossThm]) GrossThm
      ,SUM(s.[NetKWh]) NetKWh
      ,SUM(s.[NetKW]) NetKW
      ,SUM(s.[NetThm]) NetThm
	  ,SUM(s.[GoalAttainmentKWh]) GoalAttainmentKWh
	  ,SUM(s.[GoalAttainmentKW]) GoalAttainmentKW
	  ,SUM(s.[GoalAttainmentThm]) GoalAttainmentThm
	  ,SUM(s.[FirstYearGrossKWh]) FirstYearGrossKWh
	  ,SUM(s.[FirstYearGrossKW]) FirstYearGrossKW
	  ,SUM(s.[FirstYearGrossThm]) FirstYearGrossThm
	  ,SUM(s.[FirstYearNetKWh]) FirstYearNetKWh
	  ,SUM(s.[FirstYearNetKW]) FirstYearNetKW
	  ,SUM(s.[FirstYearNetThm]) FirstYearNetThm
      ,SUM(s.[LifecycleGrossKWh]) LifecycleGrossKWh
      ,SUM(s.[LifecycleGrossThm]) LifecycleGrossThm
      ,SUM(s.[LifecycleNetKWh]) LifecycleNetKWh
      ,SUM(s.[LifecycleNetThm]) LifecycleNetThm
      ,SUM(e.[NetElecCO2]) NetElecCO2
      ,SUM(e.[NetGasCO2]) NetGasCO2
      ,SUM(e.[GrossElecCO2]) GrossElecCO2
      ,SUM(e.[GrossGasCO2]) GrossGasCO2
      ,SUM(e.[NetElecCO2Lifecycle]) NetElecCO2Lifecycle
      ,SUM(e.[NetGasCO2Lifecycle]) NetGasCO2Lifecycle
      ,SUM(e.[GrossElecCO2Lifecycle])  GrossElecCO2Lifecycle
      ,SUM(e.[GrossGasCO2Lifecycle]) GrossGasCO2Lifecycle
      ,SUM(e.[NetElecNOx]) NetElecNOx
      ,SUM(e.[NetGasNOx]) NetGasNOx
      ,SUM(e.[GrossElecNOx]) GrossElecNOx
      ,SUM(e.[GrossGasNOx]) GrossGasNOx
      ,SUM(e.[NetElecNOxLifecycle]) NetElecNOxLifecycle
      ,SUM(e.[NetGasNOxLifecycle]) NetGasNOxLifecycle
      ,SUM(e.[GrossElecNOxLifecycle]) GrossElecNOxLifecycle
      ,SUM(e.[GrossGasNOxLifecycle]) GrossGasNOxLifecycle
      ,SUM(e.[GrossPM10]) GrossPM10
      ,SUM(e.[NetPM10]) NetPM10
      ,SUM(e.[GrossPM10Lifecycle]) GrossPM10Lifecycle
      ,SUM(e.[NetPM10Lifecycle]) NetPM10Lifecycle
	  ,SUM(m.[ProgramCosts]) ProgramCosts
	  ,SUM(m.[DILaborCost]) 
	  +SUM(m.[DIMaterialCost])
	  +SUM(m.[EndUserRebate])
	  +SUM(m.[IncentiveToOthers]) TotalIncentives
	  ,SUM(m.[ProgramCosts])
	  +SUM(m.[DILaborCost]) 
	  +SUM(m.[DIMaterialCost])
	  +SUM(m.[EndUserRebate])
	  +SUM(m.[IncentiveToOthers]) TotalCosts
	  ,SUM(m.[WtdAdminCostsOverheadAndGA]) [PrgAdminCostsOverheadAndGA]
	  ,SUM(m.[WtdAdminCostsOther]) [PrgAdminCostsOther]
	  ,SUM(m.[WtdMarketingOutreach]) [PrgMarketingOutreach]
	  ,SUM(m.[WtdDIActivity]) [PrgDIActivity]
	  ,SUM(m.[WtdDIInstallation]) [PrgDIInstallation]
	  ,SUM(m.[WtdDIHardwareAndMaterials]) [PrgDIHardwareAndMaterials]
	  ,SUM(m.[WtdDIRebateAndInspection]) [PrgDIRebateAndInspection]
	  ,SUM(m.[WtdEMV]) PrgEMV
	  ,SUM(m.[WtdUserInputIncentive]) PrgUserInputIncentive
	  ,SUM(m.[WtdCostsRecoveredFromOtherSources]) [PrgCostsRecoveredFromOtherSources]
	  ,SUM(m.[DILaborCost]) DILaborCost
	  ,SUM(m.[DIMaterialCost]) DIMaterialCost
	  ,SUM(m.[EndUserRebate]) EndUserRebate
	  ,SUM(m.[IncentiveToOthers]) IncentiveToOthers
	  ,SUM(m.[GrossMeasureCost]) GrossMeasureCost
	  ,SUM(m.[ExcessIncentives]) ExcessIncentives
	  ,SUM(m.[NetParticipantCost]) NetParticipantCost
	  ,SUM(ISNULL(m.[DiscountedSavingsGrosskWh],0)) DiscountedSavingsGrosskWh
	  ,SUM(ISNULL(m.[DiscountedSavingsNetkWh],0)) DiscountedSavingsNetkWh
	  ,SUM(ISNULL(m.[DiscountedSavingsGrossThm],0)) DiscountedSavingsGrossThm
	  ,SUM(ISNULL(m.[DiscountedSavingsNetThm],0)) DiscountedSavingsNetThm

	  ,CASE WHEN SUM(m.DiscountedSavingsNetkWh) <> 0 THEN SUM(ISNULL(c.ElecBen,0))/SUM(m.DiscountedSavingsNetkWh) ELSE 0 END LevBenElec
	  ,CASE WHEN SUM(m.DiscountedSavingsNetThm) <> 0 THEN SUM(ISNULL(c.GasBen,0))/SUM(m.DiscountedSavingsNetThm) ELSE 0 END LevBenGas
	  ,CASE WHEN SUM(m.DiscountedSavingsNetkWh) <> 0 AND SUM(c.ElecBen+c.GasBen) <> 0 THEN (SUM(ISNULL(c.TRCCost,0)) * SUM(c.ElecBen)/(SUM(c.ElecBen+c.GasBen)))/SUM(m.DiscountedSavingsNetkWh) ELSE 0 END LevTRCCost
	  ,CASE WHEN SUM(m.DiscountedSavingsNetkWh) <> 0 AND SUM(c.ElecBen+c.GasBen) <> 0  THEN (SUM(ISNULL(c.TRCCostNoAdmin,0)) * SUM(c.ElecBen)/(SUM(c.ElecBen+c.GasBen)))/SUM(m.DiscountedSavingsNetkWh) ELSE 0 END  LevTRCCostNoAdmin
	  ,CASE WHEN SUM(m.DiscountedSavingsNetkWh) <> 0 AND SUM(c.ElecBen+c.GasBen) <> 0  THEN (SUM(ISNULL(c.PACCost,0)) * SUM(c.ElecBen)/(SUM(c.ElecBen+c.GasBen)))/SUM(m.DiscountedSavingsNetkWh) ELSE 0 END  LevPACCost
	  ,CASE WHEN SUM(m.DiscountedSavingsNetkWh) <> 0 AND SUM(c.ElecBen+c.GasBen) <> 0  THEN (SUM(ISNULL(c.PACCostNoAdmin,0)) * SUM(c.ElecBen)/(SUM(c.ElecBen+c.GasBen)))/SUM(m.DiscountedSavingsNetkWh) ELSE 0 END  LevPACCostNoAdmin
	  ,CASE WHEN SUM(m.DiscountedSavingsNetkWh) <> 0 AND SUM(c.ElecBen+c.GasBen) <> 0  THEN (SUM(ISNULL(c.RIMCost,0)) * SUM(c.ElecBen)/(SUM(c.ElecBen+c.GasBen)))/SUM(m.DiscountedSavingsNetkWh) ELSE 0 END  LevRIMCost
	  ,CASE WHEN SUM(m.DiscountedSavingsNetkWh) <> 0 AND SUM(c.ElecBen+c.GasBen) <> 0  THEN (SUM(ISNULL(c.ElecBen,0)) - (SUM(ISNULL(c.TRCCost,0)) * SUM(c.ElecBen)/(SUM(c.ElecBen+c.GasBen))))/SUM(m.DiscountedSavingsNetkWh) ELSE 0 END  LevNetBenTRCElec
	  ,CASE WHEN SUM(m.DiscountedSavingsNetkWh) <> 0 AND SUM(c.ElecBen+c.GasBen) <> 0  THEN (SUM(ISNULL(c.ElecBen,0)) - (SUM(ISNULL(c.TRCCostNoAdmin,0)) * SUM(c.ElecBen)/(SUM(c.ElecBen+c.GasBen))))/SUM(m.DiscountedSavingsNetkWh) ELSE 0 END  LevNetBenTRCElecNoAdmin
	  ,CASE WHEN SUM(m.DiscountedSavingsNetkWh) <> 0 AND SUM(c.ElecBen+c.GasBen) <> 0  THEN (SUM(ISNULL(c.ElecBen,0)) - (SUM(ISNULL(c.PACCost,0)) * SUM(c.ElecBen)/(SUM(c.ElecBen+c.GasBen))))/SUM(m.DiscountedSavingsNetkWh) ELSE 0 END  LevNetBenPACElec
	  ,CASE WHEN SUM(m.DiscountedSavingsNetkWh) <> 0 AND SUM(c.ElecBen+c.GasBen) <> 0  THEN (SUM(ISNULL(c.ElecBen,0)) - (SUM(ISNULL(c.PACCostNoAdmin,0)) * SUM(c.ElecBen)/(SUM(c.ElecBen+c.GasBen))))/SUM(m.DiscountedSavingsNetkWh) ELSE 0 END  LevNetBenPACElecNoAdmin
	  ,CASE WHEN SUM(m.DiscountedSavingsNetThm) <> 0 AND SUM(c.ElecBen+c.GasBen) <> 0  THEN (SUM(ISNULL(c.GasBen,0)) - (SUM(ISNULL(c.TRCCost,0)) * (1-SUM(c.ElecBen)/(SUM(c.ElecBen+c.GasBen)))))/SUM(m.DiscountedSavingsNetThm) ELSE 0 END  LevNetBenTRCGas
	  ,CASE WHEN SUM(m.DiscountedSavingsNetThm) <> 0 AND SUM(c.ElecBen+c.GasBen) <> 0  THEN (SUM(ISNULL(c.GasBen,0)) - (SUM(ISNULL(c.TRCCostNoAdmin,0)) * (1-SUM(c.ElecBen)/(SUM(c.ElecBen+c.GasBen)))))/SUM(m.DiscountedSavingsNetThm) ELSE 0 END  LevNetBenTRCGasNoAdmin
	  ,CASE WHEN SUM(m.DiscountedSavingsNetThm) <> 0 AND SUM(c.ElecBen+c.GasBen) <> 0  THEN (SUM(ISNULL(c.GasBen,0)) - (SUM(ISNULL(c.PACCost,0)) * (1-SUM(c.ElecBen)/(SUM(c.ElecBen+c.GasBen)))))/SUM(m.DiscountedSavingsNetThm) ELSE 0 END  LevNetBenPACGas
	  ,CASE WHEN SUM(m.DiscountedSavingsNetThm) <> 0 AND SUM(c.ElecBen+c.GasBen) <> 0  THEN (SUM(ISNULL(c.GasBen,0)) - (SUM(ISNULL(c.PACCostNoAdmin,0)) * (1-SUM(c.ElecBen)/(SUM(c.ElecBen+c.GasBen)))))/SUM(m.DiscountedSavingsNetThm) ELSE 0 END  LevNetBenPACGasNoAdmin
	  ,CASE WHEN SUM(m.DiscountedSavingsNetkWh) <> 0 AND SUM(c.ElecBen+c.GasBen) <> 0  THEN (SUM(ISNULL(c.ElecBen,0)) - (SUM(ISNULL(c.RIMCost,0)) * SUM(c.ElecBen)/(SUM(c.ElecBen+c.GasBen))))/SUM(m.DiscountedSavingsNetkWh) ELSE 0 END  LevNetBenRIMElec
	  ,CASE WHEN SUM(m.DiscountedSavingsNetThm) <> 0 AND SUM(c.ElecBen+c.GasBen) <> 0  THEN (SUM(ISNULL(c.GasBen,0)) - (SUM(ISNULL(c.RIMCost,0)) * (1-SUM(c.ElecBen)/(SUM(c.ElecBen+c.GasBen)))))/SUM(m.DiscountedSavingsNetThm) ELSE 0 END  LevNetBenRIMGas

  FROM [SavedCE] c
  LEFT JOIN SavedSavings s ON c.CET_ID = s.CET_ID
  LEFT JOIN SavedEmissions e ON c.CET_ID = e.CET_ID
  --LEFT JOIN SavedInputCEDARS k on c.CET_ID = k.CEInputID
  LEFT JOIN SavedCost m ON c.CET_ID = m.CET_ID
  LEFT JOIN Programs p ON e.PrgID = p.[PrgID]
  WHERE c.JobID = @JobID AND s.JobID = @JobID AND  e.JobID = @JobID AND m.JobID = @JobID
  GROUP BY c.IOU_AC_Territory, c.PrgID, p.[Program Name] 
  ORDER BY c.IOU_AC_Territory, c.PrgID 


END



END






























GO


