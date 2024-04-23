/*
################################################################################
Name             :  GetJobAllByJobID
Date             :  2016-06-30
Author           :  Wayne Hauck
Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose          :  This stored procedure returns job-level CET results.
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

/****** Object:  StoredProcedure [dbo].[GetJobAllByJobID]    Script Date: 2019-12-16 1:29:37 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetJobAllByJobID] @JobID INT
AS
BEGIN

SET FMTONLY OFF;

CREATE TABLE [dbo].[#tmpCE](
	[IOU_AC_Territory] [varchar](255) NOT NULL,
	[TRCRatio] [float] NULL,
	[PACRatio] [float] NULL,
	[ElecBen] [float] NULL,
	[GasBen] [float] NULL,
	[TRCCost] [float] NOT NULL,
	[PACCost] [float] NOT NULL,
	[TRCRatioNoAdmin] [float] NULL,
	[PACRatioNoAdmin] [float] NULL,
	[TRCCostNoAdmin] [float] NULL,
	[PACCostNoAdmin] [float] NULL,
	[BillReducElec] [float] NULL,
	[BillReducGas] [float] NULL,
	[RIMCost] [float] NULL,
	[RIMRatio] [float] NULL,
	[WeightedBenefits] [float] NULL,
	[WeightedElecAlloc] [float] NULL,
) ON [PRIMARY]

CREATE TABLE [dbo].[#tmpSav](
	[IOU_AC_Territory] [varchar](255) NOT NULL,
	[GrossKWh] [float] NULL,
	[GrossKW] [float] NULL,
	[GrossThm] [float] NULL,
	[NetKWh] [float] NULL,
	[NetKW] [float] NULL,
	[NetThm] [float] NULL,
	[GoalAttainmentKWh] [float] NULL,
	[GoalAttainmentKW] [float] NULL,
	[GoalAttainmentThm] [float] NULL,
	[FirstYearGrossKWh] [float] NULL,
	[FirstYearGrossKW] [float] NULL,
	[FirstYearGrossThm] [float] NULL,
	[FirstYearNetKWh] [float] NULL,
	[FirstYearNetKW] [float] NULL,
	[FirstYearNetThm] [float] NULL,
	[LifecycleGrossKWh] [float] NULL,
	[LifecycleGrossThm] [float] NULL,
	[LifecycleNetKWh] [float] NULL,
	[LifecycleNetThm] [float] NULL,
) ON [PRIMARY]

CREATE TABLE [dbo].[#tmpEm](
	[IOU_AC_Territory] [varchar](255) NOT NULL,
	[NetElecCO2] [float] NULL,
	[NetGasCO2] [float] NULL,
	[GrossElecCO2] [float] NULL,
	[GrossGasCO2] [float] NULL,
	[NetElecCO2Lifecycle] [float] NULL,
	[NetGasCO2Lifecycle] [float] NULL,
	[GrossElecCO2Lifecycle] [float] NULL,
	[GrossGasCO2Lifecycle] [float] NULL,
	[NetElecNOx] [float] NULL,
	[NetGasNOx] [float] NULL,
	[GrossElecNOx] [float] NULL,
	[GrossGasNOx] [float] NULL,
	[NetElecNOxLifecycle] [float] NULL,
	[NetGasNOxLifecycle] [float] NULL,
	[GrossElecNOxLifecycle] [float] NULL,
	[GrossGasNOxLifecycle] [float] NULL,
	[NetPM10] [float] NULL,
	[GrossPM10] [float] NULL,
	[NetPM10Lifecycle] [float] NULL,
	[GrossPM10Lifecycle] [float] NULL,
) ON [PRIMARY]

CREATE TABLE [dbo].[#tmpCost](
	[IOU_AC_Territory] [nvarchar](255) NULL,
	[GrossMeasureCost] [float] NULL,
	[DILaborCost] [float] NULL,
	[DIMaterialCost] [float] NULL,
	[EndUserRebate] [float] NULL,
	[IncentiveToOthers] [float] NULL,
	[ExcessIncentives] [float] NULL,
	[NetParticipantCost] [float] NULL,
	[ProgramCosts] [float] NULL,
	[TotalIncentives] [float] NULL,
	[TotalCosts] [float] NULL,
	[PrgAdminCostsOverheadAndGA] [float] NULL,
	[PrgAdminCostsOther] [float] NULL,
	[PrgMarketingOutreach] [float] NULL,
	[PrgDIActivity] [float] NULL,
	[PrgDIInstallation] [float] NULL,
	[PrgDIHardwareAndMaterials] [float] NULL,
	[PrgDIRebateAndInspection] [float] NULL,
	PrgEMV [float] NULL,
	PrgUserInputIncentive [float] NULL,
	[PrgCostsRecoveredFromOtherSources] [float] NULL,
	[DiscountedSavingsGrosskWh] [float] NULL,
	[DiscountedSavingsNetkWh] [float] NULL,
	[DiscountedSavingsGrossThm] [float] NULL,
	[DiscountedSavingsNetThm] [float] NULL,
	[TRCLifecycleNetBen] [float] NULL,
	[PACLifecycleNetBen] [float] NULL,
	[LevBenElec] [float] NULL,
	[LevBenGas] [float] NULL,
	[LevTRCCost] [float] NULL,
	[LevTRCCostNoAdmin] [float] NULL,
	[LevPACCost] [float] NULL,
	[LevPACCostNoAdmin] [float] NULL,
	[LevRIMCost] [float] NULL,
	[LevNetBenTRCElec] [float] NULL,
	[LevNetBenTRCElecNoAdmin] [float] NULL,
	[LevNetBenPACElec] [float] NULL,
	[LevNetBenPACElecNoAdmin] [float] NULL,
	[LevNetBenTRCGas] [float] NULL,
	[LevNetBenTRCGasNoAdmin] [float] NULL,
	[LevNetBenPACGas] [float] NULL,
	[LevNetBenPACGasNoAdmin] [float] NULL,
	[LevNetBenRIMElec] [float] NULL,
	[LevNetBenRIMGas] [float] NULL

) ON [PRIMARY]


INSERT INTO #tmpCE
SELECT 
	   --JobID
	  'Job ' + Convert(varchar(255),@JobID) AS  IOU_AC_Territory
	  ,CASE WHEN Sum(IsNull(c.TRCCost,0)) <> 0 THEN (Sum(c.ElecBen) + Sum(c.GasBen))/Sum(c.TRCCost) ELSE 0 END AS TRCRatio
	  ,CASE WHEN Sum(IsNull(c.PACCost,0)) <> 0 THEN (Sum(c.ElecBen) + Sum(c.GasBen))/Sum(c.PACCost) ELSE 0 END AS PACRatio
      ,Sum(c.[ElecBen]) ElecBen
      ,Sum(c.[GasBen]) GasBen
      ,IsNull(Sum(c.[TRCCost]), 0) TRCCost
      ,IsNull(Sum(c.[PACCost]), 0) PACCost
	  ,CASE WHEN Sum(IsNull(c.TRCCostNoAdmin,0)) <> 0 THEN (Sum(c.ElecBen) + Sum(c.GasBen))/Sum(c.TRCCostNoAdmin) ELSE 0 END AS TRCRatioNoAdmin
	  ,CASE WHEN Sum(IsNull(c.PACCostNoAdmin,0)) <> 0 THEN (Sum(c.ElecBen) + Sum(c.GasBen))/Sum(c.PACCostNoAdmin) ELSE 0 END AS PACRatioNoAdmin
      ,Sum(c.[TRCCostNoAdmin]) TRCCostNoAdmin
      ,Sum(c.[PACCostNoAdmin]) PACCostNoAdmin
	  ,Sum(c.[BillReducElec]) BillReducElec
	  ,Sum(c.[BillReducGas]) BillReducGas
	  ,Sum(c.[RIMCost]) RIMCost
	  ,CASE WHEN Sum(c.[RIMCost]) <> 0 THEN (Sum(c.ElecBen) + Sum(c.GasBen))/Sum(c.[RIMCost]) ELSE 0 END RIMRatio
	  ,Sum(c.[WeightedBenefits]) WeightedBenefits
	  ,Sum(c.[WeightedElecAlloc]) WeightedElecAlloc
  FROM [SavedCE] c
  WHERE c.JobID = @JobID
  GROUP BY c.JobID

INSERT INTO #tmpSav
SELECT 
	   --JobID
	  'Job ' + Convert(varchar(255),@JobID) AS  IOU_AC_Territory
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
  FROM [SavedSavings] s
  WHERE s.JobID = @JobID
  GROUP BY s.JobID

INSERT INTO #tmpEM
SELECT 
	   --JobID
	  'Job ' + Convert(varchar(255),@JobID) AS IOU_AC_Territory
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
      ,Sum(e.[NetPM10]) NetPM10
      ,Sum(e.[GrossPM10]) GrossPM10
      ,Sum(e.[NetPM10Lifecycle]) NetPM10Lifecycle
      ,Sum(e.[GrossPM10Lifecycle]) GrossPM10Lifecycle
  FROM SavedEmissions e 
  WHERE e.JobID = @JobID
  GROUP BY e.JobID

INSERT INTO #tmpCost
SELECT 
	   --JobID
	  'Job ' + Convert(varchar(255),@JobID) AS  IOU_AC_Territory
	  ,Sum(m.[GrossMeasureCost]) GrossMeasureCost
	  ,Sum(m.[DILaborCost]) DILaborCost
	  ,Sum(m.[DIMaterialCost]) DIMaterialCost
	  ,Sum(m.[EndUserRebate]) EndUserRebate
	  ,Sum(m.[IncentiveToOthers]) IncentiveToOthers
	  ,Sum(m.[ExcessIncentives]) ExcessIncentives
	  ,Sum(m.[NetParticipantCost]) NetParticipantCost
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
	  ,Sum(IsNull(m.[DiscountedSavingsGrosskWh],0)) DiscountedSavingsGrosskWh
	  ,Sum(IsNull(m.[DiscountedSavingsNetkWh],0)) DiscountedSavingsNetkWh
	  ,Sum(IsNull(m.[DiscountedSavingsGrossThm],0)) DiscountedSavingsGrossThm
	  ,Sum(IsNull(m.[DiscountedSavingsNetThm],0)) DiscountedSavingsNetThm
	  ,Sum(IsNull(m.[TRCLifecycleNetBen],0)) TRCLifecycleNetBen
	  ,Sum(IsNull(m.[PACLifecycleNetBen],0)) [PACLifecycleNetBen]

	  ,CASE WHEN Sum(m.DiscountedSavingsNetkWh) <> 0 THEN Sum(IsNull(c.ElecBen,0))/Sum(m.DiscountedSavingsNetkWh) ELSE 0 END LevBenElec
	  ,CASE WHEN Sum(m.DiscountedSavingsNetThm) <> 0 THEN Sum(IsNull(c.GasBen,0))/Sum(m.DiscountedSavingsNetThm) ELSE 0 END LevBenGas
	  ,CASE WHEN Sum(m.DiscountedSavingsNetkWh) <> 0 AND Sum(c.ElecBen+c.GasBen) <> 0  THEN (Sum(IsNull(c.TRCCost,0)) * Sum(c.ElecBen)/(Sum(c.ElecBen+c.GasBen)))/Sum(m.DiscountedSavingsNetkWh) ELSE 0 END LevTRCCost
	  ,CASE WHEN Sum(m.DiscountedSavingsNetkWh) <> 0 AND Sum(c.ElecBen+c.GasBen) <> 0  THEN (Sum(IsNull(c.TRCCostNoAdmin,0)) * Sum(c.ElecBen)/(Sum(c.ElecBen+c.GasBen)))/Sum(m.DiscountedSavingsNetkWh) ELSE 0 END  LevTRCCostNoAdmin
	  ,CASE WHEN Sum(m.DiscountedSavingsNetkWh) <> 0 AND Sum(c.ElecBen+c.GasBen) <> 0 THEN (Sum(IsNull(c.PACCost,0)) * Sum(c.ElecBen)/(Sum(c.ElecBen+c.GasBen)))/Sum(m.DiscountedSavingsNetkWh) ELSE 0 END  LevPACCost
	  ,CASE WHEN Sum(m.DiscountedSavingsNetkWh) <> 0 THEN (Sum(IsNull(c.PACCostNoAdmin,0)) * Sum(c.ElecBen)/(Sum(c.ElecBen+c.GasBen)))/Sum(m.DiscountedSavingsNetkWh) ELSE 0 END  LevPACCostNoAdmin
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

  FROM SavedCost m 
  LEFT JOIN SavedCE c on m.CET_ID = c.CET_ID 
  WHERE m.JobID = @JobID and c.JobID = @JobID
  GROUP BY m.JobID


DECLARE @cnt int
set @cnt = (select count(*) from ( select IOU_AC_Territory from savedCE where JobID = @JobID group by IOU_AC_Territory ) as tmp)
 
IF @cnt > 1
BEGIN

INSERT INTO #tmpCE
SELECT 
	   --JobID
	   IOU_AC_Territory
	  ,CASE WHEN Sum(IsNull(c.TRCCost,0)) <> 0 THEN (Sum(c.ElecBen) + Sum(c.GasBen))/Sum(c.TRCCost) ELSE 0 END AS TRCRatio
	  ,CASE WHEN Sum(IsNull(c.PACCost,0)) <> 0 THEN (Sum(c.ElecBen) + Sum(c.GasBen))/Sum(c.PACCost) ELSE 0 END AS PACRatio
      ,Sum(c.[ElecBen]) ElecBen
      ,Sum(c.[GasBen]) GasBen
      ,IsNull(Sum(c.[TRCCost]), 0) TRCCost
      ,IsNull(Sum(c.[PACCost]), 0) PACCost
	  ,CASE WHEN Sum(IsNull(c.TRCCostNoAdmin,0)) <> 0 THEN (Sum(c.ElecBen) + Sum(c.GasBen))/Sum(c.TRCCostNoAdmin) ELSE 0 END AS TRCRatioNoAdmin
	  ,CASE WHEN Sum(IsNull(c.PACCostNoAdmin,0)) <> 0 THEN (Sum(c.ElecBen) + Sum(c.GasBen))/Sum(c.PACCostNoAdmin) ELSE 0 END AS PACRatioNoAdmin
      ,Sum(c.[TRCCostNoAdmin]) TRCCostNoAdmin
      ,Sum(c.[PACCostNoAdmin]) PACCostNoAdmin
	  ,Sum(c.[BillReducElec]) BillReducElec
	  ,Sum(c.[BillReducGas]) BillReducGas
	  ,Sum(c.[RIMCost]) RIMCost
	  ,CASE WHEN Sum(c.[RIMCost]) <> 0 THEN (Sum(c.[BillReducElec]) + Sum(c.[BillReducGas]))/Sum(c.[RIMCost]) ELSE 0 END RIMRatio
	  ,Sum(c.[WeightedBenefits]) WeightedBenefits
	  ,CASE WHEN Sum(c.ElecBen+c.GasBen) <> 0 THEN Sum(c.ElecBen)/(Sum(c.ElecBen+c.GasBen)) ELSE 0 END  WeightedElecAlloc
  FROM [SavedCE] c
  WHERE c.JobID = @JobID
  GROUP BY c.IOU_AC_Territory

INSERT INTO #tmpSav
SELECT 
	   --JobID
	   IOU_AC_Territory
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
  FROM [SavedSavings] s
  WHERE s.JobID = @JobID
  GROUP BY s.IOU_AC_Territory

INSERT INTO #tmpEM
SELECT 
	   --JobID
	  IOU_AC_Territory
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
      ,Sum(e.[NetPM10]) NetPM10
      ,Sum(e.[GrossPM10]) GrossPM10
      ,Sum(e.[NetPM10Lifecycle]) NetPM10Lifecycle
      ,Sum(e.[GrossPM10Lifecycle]) GrossPM10Lifecycle
  FROM SavedEmissions e 
  WHERE e.JobID = @JobID
  GROUP BY e.IOU_AC_Territory


INSERT INTO #tmpCost
SELECT 
	   --JobID
	  m.IOU_AC_Territory
	  ,SUM(m.[GrossMeasureCost]) GrossMeasureCost
	  ,SUM(m.[DILaborCost]) DILaborCost
	  ,SUM(m.[DIMaterialCost]) DIMaterialCost
	  ,SUM(m.[EndUserRebate]) EndUserRebate
	  ,SUM(m.[IncentiveToOthers]) IncentiveToOthers
	  ,SUM(m.[ExcessIncentives]) ExcessIncentives
	  ,SUM(m.[NetParticipantCost]) NetParticipantCost
	  ,SUM(m.[ProgramCosts]) WeightedProgramCosts
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
	  ,SUM(ISNULL(m.[DiscountedSavingsGrosskWh],0)) DiscountedSavingsGrosskWh
	  ,SUM(ISNULL(m.[DiscountedSavingsNetkWh],0)) DiscountedSavingsNetkWh
	  ,SUM(ISNULL(m.[DiscountedSavingsGrossThm],0)) DiscountedSavingsGrossThm
	  ,SUM(ISNULL(m.[DiscountedSavingsNetThm],0)) DiscountedSavingsNetThm
	  ,SUM(ISNULL(m.[TRCLifecycleNetBen],0)) TRCLifecycleNetBen
	  ,SUM(ISNULL(m.[PACLifecycleNetBen],0)) [PACLifecycleNetBen]


	  ,CASE WHEN SUM(m.DiscountedSavingsNetkWh) <> 0 THEN SUM(ISNULL(c.ElecBen,0))/SUM(m.DiscountedSavingsNetkWh) ELSE 0 END LevBenElec
	  ,CASE WHEN SUM(m.DiscountedSavingsNetThm) <> 0 THEN SUM(ISNULL(c.GasBen,0))/SUM(m.DiscountedSavingsNetThm) ELSE 0 END LevBenGas
	  ,CASE WHEN SUM(m.DiscountedSavingsNetkWh) <> 0 AND SUM(c.ElecBen+c.GasBen) <> 0 THEN (SUM(ISNULL(c.TRCCost,0)) * SUM(c.ElecBen)/(SUM(c.ElecBen+c.GasBen)))/SUM(m.DiscountedSavingsNetkWh) ELSE 0 END LevTRCCost
	  ,CASE WHEN SUM(m.DiscountedSavingsNetkWh) <> 0 AND SUM(c.ElecBen+c.GasBen) <> 0 THEN (SUM(ISNULL(c.TRCCostNoAdmin,0)) * SUM(c.ElecBen)/(SUM(c.ElecBen+c.GasBen)))/SUM(m.DiscountedSavingsNetkWh) ELSE 0 END  LevTRCCostNoAdmin
	  ,CASE WHEN SUM(m.DiscountedSavingsNetkWh) <> 0 AND SUM(c.ElecBen+c.GasBen) <> 0 THEN (SUM(ISNULL(c.PACCost,0)) * SUM(c.ElecBen)/(SUM(c.ElecBen+c.GasBen)))/SUM(m.DiscountedSavingsNetkWh) ELSE 0 END  LevPACCost
	  ,CASE WHEN SUM(m.DiscountedSavingsNetkWh) <> 0 AND SUM(c.ElecBen+c.GasBen) <> 0 THEN (SUM(ISNULL(c.PACCostNoAdmin,0)) * SUM(c.ElecBen)/(SUM(c.ElecBen+c.GasBen)))/SUM(m.DiscountedSavingsNetkWh) ELSE 0 END  LevPACCostNoAdmin
	  ,CASE WHEN SUM(m.DiscountedSavingsNetkWh) <> 0 AND SUM(c.ElecBen+c.GasBen) <> 0 THEN (SUM(ISNULL(c.RIMCost,0)) * SUM(c.ElecBen)/(SUM(c.ElecBen+c.GasBen)))/SUM(m.DiscountedSavingsNetkWh) ELSE 0 END  LevRIMCost
	  ,CASE WHEN SUM(m.DiscountedSavingsNetkWh) <> 0 AND SUM(c.ElecBen+c.GasBen) <> 0 THEN (SUM(ISNULL(c.ElecBen,0)) - (SUM(ISNULL(c.TRCCost,0)) * SUM(c.ElecBen)/(SUM(c.ElecBen+c.GasBen))))/SUM(m.DiscountedSavingsNetkWh) ELSE 0 END  LevNetBenTRCElec
	  ,CASE WHEN SUM(m.DiscountedSavingsNetkWh) <> 0 AND SUM(c.ElecBen+c.GasBen) <> 0 THEN (SUM(ISNULL(c.ElecBen,0)) - (SUM(ISNULL(c.TRCCostNoAdmin,0)) * SUM(c.ElecBen)/(SUM(c.ElecBen+c.GasBen))))/SUM(m.DiscountedSavingsNetkWh) ELSE 0 END  LevNetBenTRCElecNoAdmin
	  ,CASE WHEN SUM(m.DiscountedSavingsNetkWh) <> 0 AND SUM(c.ElecBen+c.GasBen) <> 0 THEN (SUM(ISNULL(c.ElecBen,0)) - (SUM(ISNULL(c.PACCost,0)) * SUM(c.ElecBen)/(SUM(c.ElecBen+c.GasBen))))/SUM(m.DiscountedSavingsNetkWh) ELSE 0 END  LevNetBenPACElec
	  ,CASE WHEN SUM(m.DiscountedSavingsNetkWh) <> 0 AND SUM(c.ElecBen+c.GasBen) <> 0 THEN (SUM(ISNULL(c.ElecBen,0)) - (SUM(ISNULL(c.PACCostNoAdmin,0)) * SUM(c.ElecBen)/(SUM(c.ElecBen+c.GasBen))))/SUM(m.DiscountedSavingsNetkWh) ELSE 0 END  LevNetBenPACElecNoAdmin
	  ,CASE WHEN SUM(m.DiscountedSavingsNetThm) <> 0 AND SUM(c.ElecBen+c.GasBen) <> 0 THEN (SUM(ISNULL(c.GasBen,0)) - (SUM(ISNULL(c.TRCCost,0)) * (1-SUM(c.ElecBen)/(SUM(c.ElecBen+c.GasBen)))))/SUM(m.DiscountedSavingsNetThm) ELSE 0 END  LevNetBenTRCGas
	  ,CASE WHEN SUM(m.DiscountedSavingsNetThm) <> 0 AND SUM(c.ElecBen+c.GasBen) <> 0 THEN (SUM(ISNULL(c.GasBen,0)) - (SUM(ISNULL(c.TRCCostNoAdmin,0)) * (1-SUM(c.ElecBen)/(SUM(c.ElecBen+c.GasBen)))))/SUM(m.DiscountedSavingsNetThm) ELSE 0 END  LevNetBenTRCGasNoAdmin
	  ,CASE WHEN SUM(m.DiscountedSavingsNetThm) <> 0 AND SUM(c.ElecBen+c.GasBen) <> 0 THEN (SUM(ISNULL(c.GasBen,0)) - (SUM(ISNULL(c.PACCost,0)) * (1-SUM(c.ElecBen)/(SUM(c.ElecBen+c.GasBen)))))/SUM(m.DiscountedSavingsNetThm) ELSE 0 END  LevNetBenPACGas
	  ,CASE WHEN SUM(m.DiscountedSavingsNetThm) <> 0 AND SUM(c.ElecBen+c.GasBen) <> 0 THEN (SUM(ISNULL(c.GasBen,0)) - (SUM(ISNULL(c.PACCostNoAdmin,0)) * (1-SUM(c.ElecBen)/(SUM(c.ElecBen+c.GasBen)))))/SUM(m.DiscountedSavingsNetThm) ELSE 0 END  LevNetBenPACGasNoAdmin
	  ,CASE WHEN SUM(m.DiscountedSavingsNetkWh) <> 0 AND SUM(c.ElecBen+c.GasBen) <> 0 THEN (SUM(ISNULL(c.ElecBen,0)) - (SUM(ISNULL(c.RIMCost,0)) * SUM(c.ElecBen)/(SUM(c.ElecBen+c.GasBen))))/SUM(m.DiscountedSavingsNetkWh) ELSE 0 END  LevNetBenRIMElec
	  ,CASE WHEN SUM(m.DiscountedSavingsNetThm) <> 0 AND SUM(c.ElecBen+c.GasBen) <> 0 THEN (SUM(ISNULL(c.GasBen,0)) - (SUM(ISNULL(c.RIMCost,0)) * (1-SUM(c.ElecBen)/(SUM(c.ElecBen+c.GasBen)))))/SUM(m.DiscountedSavingsNetThm) ELSE 0 END  LevNetBenRIMGas

  FROM SavedCost m 
  LEFT JOIN SavedCE c ON m.CET_ID = c.CET_ID 
  WHERE m.JobID = @JobID AND c.JobID = @JobID
  GROUP BY m.IOU_AC_Territory

END

SELECT 
	ce.[IOU_AC_Territory],
	[TRCRatio],
	[PACRatio],
	[ElecBen],
	[GasBen],
	[TRCCost],
	[PACCost],
	[TRCRatioNoAdmin],
	[PACRatioNoAdmin],
	[TRCCostNoAdmin],
	[PACCostNoAdmin],
    [TRCLifecycleNetBen],
    [PACLifecycleNetBen],
    [BillReducElec],
    [BillReducGas],
    [RIMCost],
	[RIMRatio],
    GrossKWh,
    GrossKW,
    GrossThm,
    NetKWh,
    NetKW,
    NetThm,
	GoalAttainmentKWh,
	GoalAttainmentKW,
	GoalAttainmentThm,
	FirstYearGrossKWh,
	FirstYearGrossKW,
	FirstYearGrossThm,
	FirstYearNetKWh,
	FirstYearNetKW,
	FirstYearNetThm,
    LifecycleGrossKWh,
    LifecycleGrossThm,
    LifecycleNetKWh,
    LifecycleNetThm,
	[NetElecCO2],
	[NetGasCO2],
	[GrossElecCO2],
	[GrossGasCO2],
	[NetElecCO2Lifecycle],
	[NetGasCO2Lifecycle],
	[GrossElecCO2Lifecycle],
	[GrossGasCO2Lifecycle],
	[NetElecNOx],
	[NetGasNOx],
	[GrossElecNOx],
	[GrossGasNOx],
	[NetElecNOxLifecycle],
	[NetGasNOxLifecycle],
	[GrossElecNOxLifecycle],
	[GrossGasNOxLifecycle],
	NetPM10,
	GrossPM10,
	NetPM10Lifecycle,
	GrossPM10Lifecycle,
	ProgramCosts,
	TotalIncentives,
	TotalCosts,
	[PrgAdminCostsOverheadAndGA],
	[PrgAdminCostsOther],
	[PrgMarketingOutreach],
	[PrgDIActivity],
	[PrgDIInstallation],
	[PrgDIHardwareAndMaterials],
	[PrgDIRebateAndInspection],
	PrgEMV,
	PrgUserInputIncentive,
	[PrgCostsRecoveredFromOtherSources],
	DILaborCost,
	DIMaterialCost,
	EndUserRebate,
	IncentiveToOthers,
	GrossMeasureCost,
	ExcessIncentives,
	NetParticipantCost,
	DiscountedSavingsGrosskWh,
	DiscountedSavingsNetkWh,
	DiscountedSavingsGrossThm,
	DiscountedSavingsNetThm,
    [LevBenElec],
    [LevBenGas],
    [LevTRCCost],
    [LevTRCCostNoAdmin],
    [LevPACCost],
    [LevPACCostNoAdmin],
    [LevRIMCost],
    [LevNetBenTRCElec],
    [LevNetBenTRCElecNoAdmin],
    [LevNetBenPACElec],
    [LevNetBenPACElecNoAdmin],
    [LevNetBenTRCGas],
    [LevNetBenTRCGasNoAdmin],
    [LevNetBenPACGas],
    [LevNetBenPACGasNoAdmin],
    [LevNetBenRIMElec],
    [LevNetBenRIMGas]
	FROM #tmpCE ce
	LEFT JOIN #tmpSav s ON ce.IOU_AC_Territory = s.IOU_AC_Territory 
	LEFT JOIN #tmpEM e ON ce.IOU_AC_Territory = e.IOU_AC_Territory
	LEFT JOIN #tmpCost m ON ce.IOU_AC_Territory = m.IOU_AC_Territory

END




































GO


