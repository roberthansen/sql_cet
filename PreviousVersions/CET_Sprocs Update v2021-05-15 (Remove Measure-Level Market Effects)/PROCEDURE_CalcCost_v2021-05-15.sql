USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[CalcCost]    Script Date: 12/16/2019 1:12:42 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





--#################################################################################################
-- Name             :  CalcCost
-- Date             :  06/30/2016
-- Author           :  Wayne Hauck
-- Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
-- Purpose          :  This stored procedure calculates cost outputs.
-- Usage            :  n/a
-- Called by        :  n/a
-- Copyright ©      :  Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
-- Change History   :  06/30/2016  Wayne Hauck added comment header
-- Change History   :  12/30/2016  Wayne Hauck added measure inflation
--                     
--#################################################################################################

CREATE PROCEDURE [dbo].[CalcCost]
@JobID INT = -1,
@MEBens FLOAT=NULL,
@MECost FLOAT=NULL,
@FirstYear INT,
@AVCVersion VARCHAR(255)

AS

SET NOCOUNT ON

IF @MEBens Is Null
    BEGIN
        SET @MEBens = IsNull((SELECT MarketEffectBens from CETJobs WHERE ID = @JobID),0)
    END 
IF @MECost Is Null
    BEGIN
        SET @MECost = IsNull((SELECT MarketEffectCost from CETJobs WHERE ID = @JobID),0)
    END 

CREATE TABLE [#OutputCost](
    [JobID] [int] NOT NULL,
    [PA] [nvarchar](8) NULL,
    [PrgID] [nvarchar](255) NULL,
    [CET_ID] [nvarchar](255) NOT NULL,
    IncentiveToOthers [float] NULL,
    DILaborCost [float] NULL,
    DIMaterialCost [float] NULL,
    EndUserRebate [float] NULL,
    RebatesandIncents [float] NULL,
    GrossMeasureCost [float] NULL,
    ExcessIncentives [float] NULL,
    MarkEffectPlusExcessInc [float] NULL,
    GrossParticipantCost [float] NULL,
    GrossParticipantCostAdjusted [float] NULL,
    NetParticipantCost [float] NULL,
    NetParticipantCostAdjusted [float] NULL,
    RebatesandIncentsPV [float] NULL,
    GrossMeasCostPV [float] NULL,
    ExcessIncentivesPV [float] NULL,
    MarkEffectPlusExcessIncPV [float] NULL,
    GrossParticipantCostPV [float] NULL,
    GrossParticipantCostAdjustedPV [float] NULL,
    NetParticipantCostPV [float] NULL,
    NetParticipantCostAdjustedPV [float] NULL,
    WtdAdminCostsOverheadAndGA [float] NULL, 
    WtdAdminCostsOther [float] NULL, 
    WtdMarketingOutreach [float] NULL, 
    WtdDIActivity [float] NULL, 
    WtdDIInstallation [float] NULL, 
    WtdDIHardwareAndMaterials [float] NULL,
    WtdDIRebateAndInspection [float] NULL, 
    WtdEMV [float] NULL, 
    WtdUserInputIncentive [float] NULL, 
    WtdCostsRecoveredFromOtherSources [float] NULL, 
    ProgramCosts [float] NULL, 
    TotalExpenditures [float] NULL, 
    DiscountedSavingsGrosskWh [float] NULL,
    DiscountedSavingsNetkWh [float] NULL,
    DiscountedSavingsGrossThm [float] NULL,
    DiscountedSavingsNetThm [float] NULL,
    TRCLifecycleNetBen [float] NULL,
    PACLifecycleNetBen [float] NULL,
    LevBenElec [float] NULL,
    LevBenGas [float] NULL,
    LevTRCCost [float] NULL,
    LevTRCCostNoAdmin [float] NULL,
    LevPACCost [float] NULL,
    LevPACCostNoAdmin [float] NULL,
    LevRIMCost [float] NULL,
    LevNetBenTRCElec [float] NULL,
    LevNetBenTRCElecNoAdmin [float] NULL,
    LevNetBenPACElec [float] NULL,
    LevNetBenPACElecNoAdmin [float] NULL,
    LevNetBenTRCGas [float] NULL,
    LevNetBenTRCGasNoAdmin [float] NULL,
    LevNetBenPACGas [float] NULL,
    LevNetBenPACGasNoAdmin [float] NULL,
    LevNetBenRIMElec [float] NULL,
    LevNetBenRIMGas [float] NULL
) ON [PRIMARY]


BEGIN
WITH Settings (
    PA
    , [Version]
    , Rqf
    , Raf
    , BaseYear
    )
AS (
    SELECT PA
    , [Version]
    , Rqf
    , Raf
    , BaseYear
    FROM Settingsvw
    WHERE [Version] = @AVCVersion
    )
, ProgramCostDetail (
    PrgID
    ,AdminCostsOverheadAndGA 
    ,AdminCostsOther 
    ,MarketingOutreach 
    ,DIActivity
    ,DIInstallation 
    ,DIHardwareAndMaterials
    ,DIRebateAndInspection
    ,EMV
    ,UserInputIncentive
    ,CostsRecoveredFromOtherSources
    , SumProgramCosts
    )
AS  (
    SELECT c.PrgID
        ,SUM(IsNull([AdminCostsOverheadAndGA],0)) AdminCostsOverheadAndGA 
        ,SUM(IsNull([AdminCostsOther],0)) AdminCostsOther 
        ,SUM(IsNull([MarketingOutreach],0)) MarketingOutreach 
        ,SUM(IsNull([DIActivity],0)) DIActivity
        ,SUM(IsNull([DIInstallation],0)) DIInstallation 
        ,SUM(IsNull([DIHardwareAndMaterials],0)) DIHardwareAndMaterials
        ,SUM(IsNull([DIRebateAndInspection],0)) DIRebateAndInspection
        ,SUM(IsNull([EMV],0)) EMV
        ,SUM(IsNull([UserInputIncentive],0)) UserInputIncentive
        ,SUM(IsNull([CostsRecoveredFromOtherSources],0)) CostsRecoveredFromOtherSources
        ,SUM(IsNull([AdminCostsOverheadAndGA],0) 
        + IsNull([AdminCostsOther],0) 
        + IsNull([MarketingOutreach],0) 
        + IsNull([DIActivity],0) 
        + IsNull([DIInstallation],0) 
        + IsNull([DIHardwareAndMaterials],0) 
        + IsNull([DIRebateAndInspection],0) 
        + IsNull([EMV],0) 
        + IsNull([UserInputIncentive],0) 
        + IsNull([CostsRecoveredFromOtherSources],0)) 
        AS SumProgramCosts
    FROM dbo.[InputProgramvw] c
    GROUP BY c.PrgID
    )
, ProgramCosts (
    PrgID
    , SumCosts
    , SumCostsNPV
    , UserInputIncentive
    , UserInputIncentiveNPV
    )
AS  (
    SELECT c.PrgID
        ,SUM(IsNull([AdminCostsOverheadAndGA],0) 
        + IsNull([AdminCostsOther],0) 
        + IsNull([MarketingOutreach],0) 
        + IsNull([DIActivity],0) 
        + IsNull([DIInstallation],0) 
        + IsNull([DIHardwareAndMaterials],0) 
        + IsNull([DIRebateAndInspection],0) 
        + IsNull([EMV],0) 
        + IsNull([UserInputIncentive],0) 
        + IsNull([CostsRecoveredFromOtherSources],0)) 
        AS SumCosts
        ,SUM(IsNull([AdminCostsOverheadAndGA],0) 
        + IsNull([AdminCostsOther],0) 
        + IsNull([MarketingOutreach],0) 
        + IsNull([DIActivity],0) 
        + IsNull([DIInstallation],0) 
        + IsNull([DIHardwareAndMaterials],0) 
        + IsNull([DIRebateAndInspection],0) 
        + IsNull([EMV],0) 
        + IsNull([UserInputIncentive],0) 
        + IsNull([CostsRecoveredFromOtherSources],0))/POWER(s.Raf,Convert(int,[Year]-@FirstYear))
        AS SumCostsNPV
        ,SUM(IsNull([UserInputIncentive],0)) AS UserInputIncentive
        ,SUM(IsNull([UserInputIncentive],0))/POWER(s.Raf,Convert(int,[Year]-@FirstYear)) AS UserInputIncentiveNPV
    FROM dbo.[InputProgramvw] c
    LEFT JOIN Settingsvw s ON c.PA = s.PA
    WHERE [Version] = @AVCVersion
    GROUP BY c.PrgID, [Year], s.Raf, BaseYear
    )
, ProgramCostsSum (
    PrgID
    , SumCostsNPV
    )
AS (
    SELECT PrgID, SUM(IsNull(SumCostsNPV,0)) AS SumCostsNPV
    FROM ProgramCosts
    GROUP BY PrgID
)
, ProgramLevelIncentives (
    PrgID
    , PAC_Cost
    , TotalIncentivesAndRebates
    )
AS  (
    SELECT e.PrgID
    ,Sum(ce.PACCost) PAC_Cost
    , Sum((Qty * (e.IncentiveToOthers + e.DILaborCost + e.DIMaterialCost + e.EndUserRebate)) / Power(Rqf, Qm)) As TotalIncentivesandRebatesPV
    FROM InputMeasurevw e
    LEFT JOIN OutputCE ce on e.PrgID = ce.PrgID 
    LEFT JOIN Settingsvw s ON e.PA = s.PA
    WHERE s.[Version] = @AVCVersion
    GROUP BY e.PrgID
    )
, RebatesAndIncentives (
    PrgID
    , CET_ID
    , NTGRCost
    , IncentiveToOthers
    , DILaborCost
    , DIMaterialCost
    , EndUserRebate
    , ExcessInc
    , Rebates
    , IncentsAndDI
    , ExcessIncPV
    , RebatesPV
    , IncentsAndDIPV
    , GrossMeasCost
    , GrossMeasCostPV
    , MeasureIncCost
    , RebatesandIncents
    , RebatesandIncentsPV
    )
AS (
    SELECT PrgID, e.CET_ID, NTGRCost
    ,Sum(Qty * e.IncentiveToOthers) IncentiveToOthers
    ,Sum(Qty * e.DILaborCost) DILaborCost
    ,Sum(Qty * e.DIMaterialCost) DIMaterialCost
    ,Sum(Qty * e.EndUserRebate) EndUserRebate
    , Sum((Qty * CASE WHEN (e.IncentiveToOthers + e.DILaborCost + e.DIMaterialCost -e.UnitMeasureGrossCost) <=0 THEN 
        0 
    ELSE
        e.IncentiveToOthers + e.DILaborCost + e.DIMaterialCost - e.UnitMeasureGrossCost
    END)) AS ExcessInc
    , Sum(Qty * e.EndUserRebate) As Rebates
    , Sum(Qty * (e.IncentiveToOthers + e.DILaborCost + e.DIMaterialCost) ) 
    As IncentsAndDI
    , Sum((Qty * CASE WHEN (e.IncentiveToOthers + e.DILaborCost + e.DIMaterialCost -e.UnitMeasureGrossCost) <=0 THEN 
        0 
    ELSE
        e.IncentiveToOthers + e.DILaborCost + e.DIMaterialCost - e.UnitMeasureGrossCost
    END)/ Power(Rqf, Qm)) AS ExcessIncPV
    , Sum(Qty * e.EndUserRebate / Power(Rqf, Qm)) As RebatesPV
    , Sum(Qty * (e.IncentiveToOthers + e.DILaborCost + e.DIMaterialCost) / Power(Rqf, Qm)) 
    As IncentsAndDIPV
    , Sum(Qty * (e.UnitMeasureGrossCost- CASE WHEN e.rul > 0 THEN (e.UnitMeasureGrossCost - e.MeasIncrCost) ELSE 0  END) ) As GrossMeasCost
    , Sum(Qty * (e.UnitMeasureGrossCost- CASE WHEN e.rul > 0 THEN (e.UnitMeasureGrossCost - e.MeasIncrCost)*Power((1+e.MeasInflation/4)/Rqf, e.rulq) ELSE 0  END) / Power(Rqf, Qm)) As GrossMeasCostPV
    , Sum(Qty * e.MeasIncrCost)  AS MeasureIncCost
    , Sum(Qty * (e.IncentiveToOthers + e.DILaborCost + e.DIMaterialCost + e.EndUserRebate) ) As RebatesAndIncents
    , Sum(Qty * (e.IncentiveToOthers + e.DILaborCost + e.DIMaterialCost + e.EndUserRebate) / Power(Rqf, Qm)) As RebatesAndIncentsPV
FROM InputMeasurevw e
    LEFT JOIN Settingsvw s ON e.PA = s.PA
    WHERE [Version] = @AVCVersion
    GROUP BY PrgID, e.CET_ID, NTGRCost
    )
, ClaimCount (
      PrgID
    , ClaimCount
)
AS (
    SELECT PrgID
        ,Count(CET_ID) As ClaimCount
    FROM OutputCE
    GROUP BY PrgID
)
, ExcessIncentives (
    CET_ID
    , ExcessIncentives
    , ExcessIncentivesPV
)
AS
(
    SELECT CE.CET_ID
        , CASE WHEN ri.IncentsAndDI <=ri.GrossMeasCost THEN 0 ELSE ri.IncentsAndDI - ri.GrossMeasCost END AS ExcessIncentives
        , CASE WHEN ri.IncentsAndDIPV <=ri.GrossMeasCostPV THEN 0 ELSE ri.IncentsAndDIPV - ri.GrossMeasCostPV END AS ExcessIncentivesPV
    FROM OutputCE  ce
    LEFT JOIN RebatesAndIncentives ri on CE.CET_ID = ri.CET_ID
    LEFT JOIN InputMeasurevw e ON CE.CET_ID = e.CET_ID
)
, GrossMeasureCostAdjusted (
    CET_ID
    ,  GrossMeasureCostAdjusted
    ,  GrossMeasureCostAdjustedPV
    , MarkEffectPlusExcessInc
    , MarkEffectPlusExcessIncPV
)
AS
(
    SELECT CE.CET_ID
        , ri.GrossMeasCost -  (ri.IncentsAndDI + ri.Rebates) + (ex.ExcessIncentives) AS GrossMeasureCostAdjusted
        , ri.GrossMeasCostPV -  (ri.IncentsAndDIPV + ri.RebatesPV) + (ex.ExcessIncentivesPV) AS GrossMeasureCostAdjustedPV
        , Coalesce(e.MECost,@MECost) * ((ri.GrossMeasCost) + (ex.ExcessIncentivesPV)) AS MarkEffectPlusExcessInc
        , Coalesce(e.MECost,@MECost) * ((ri.GrossMeasCostPV) + (ex.ExcessIncentivesPV)) AS MarkEffectPlusExcessIncPV
    FROM OutputCE  ce
    LEFT JOIN RebatesAndIncentives ri on CE.CET_ID = ri.CET_ID
    LEFT JOIN InputMeasurevw e ON CE.CET_ID = e.CET_ID
    LEFT JOIN ExcessIncentives ex on ce.CET_ID = ex.CET_ID
)
, ParticipantCost (
    CET_ID
    , ExcessIncentives
    , ExcessIncentivesPV
    , MarkEffectPlusExcessInc
    , MarkEffectPlusExcessIncPV
    , GrossParticipantCost
    , GrossParticipantCostPV
    , GrossParticipantCostAdjusted
    , GrossParticipantCostAdjustedPV
    , NetParticipantCost
    , NetParticipantCostPV
    , NetParticipantCostAdjusted
    , NetParticipantCostAdjustedPV
)
AS
(
    SELECT CE.CET_ID
        , ex.ExcessIncentives AS ExcessIncentives
        , ex.ExcessIncentivesPV AS ExcessIncentivesPV
        ,gma.MarkEffectPlusExcessInc
        ,gma.MarkEffectPlusExcessIncPV
        ,ri.GrossMeasCost - (ri.IncentsAndDI + ri.Rebates) AS  GrossParticipantCost
        ,ri.GrossMeasCostPV - (ri.IncentsAndDIPV + ri.RebatesPV) AS  GrossParticipantCostPV
        ,ri.GrossMeasCost - (ri.IncentsAndDI + ri.Rebates) + ex.ExcessIncentives + gma.MarkEffectPlusExcessInc AS  GrossParticipantCostAdjusted
        ,ri.GrossMeasCostPV - (ri.IncentsAndDIPV + ri.RebatesPV) + ex.ExcessIncentivesPV + gma.MarkEffectPlusExcessIncPV AS  GrossParticipantCostAdjustedPV
        ,ri.NTGRCost * (ri.GrossMeasCost - (ri.IncentsAndDI + ri.Rebates)+ ex.ExcessIncentives) AS  NetParticipantCost
        ,ri.NTGRCost * (ri.GrossMeasCostPV - (ri.IncentsAndDIPV + ri.RebatesPV)+ ex.ExcessIncentivesPV)   NetParticipantCostPV
        ,ri.NTGRCost * (ri.GrossMeasCost - (ri.IncentsAndDI + ri.Rebates)+ ex.ExcessIncentives) + gma.MarkEffectPlusExcessInc AS  NetParticipantCostAdjusted
        ,ri.NTGRCost * (ri.GrossMeasCostPV - (ri.IncentsAndDIPV + ri.RebatesPV)+ ex.ExcessIncentivesPV) + gma.MarkEffectPlusExcessIncPV  NetParticipantCostAdjustedPV

    FROM OutputCE  ce
    LEFT JOIN RebatesAndIncentives ri on CE.CET_ID = ri.CET_ID
    LEFT JOIN ExcessIncentives ex on ri.CET_ID = ex.CET_ID
    LEFT JOIN InputMeasurevw e ON CE.CET_ID = e.CET_ID
    LEFT JOIN GrossMeasureCostAdjusted gma on ce.CET_ID = gma.CET_ID
    --LEFT JOIN Settingsvw s ON e.PA = s.PA
)
, DiscountedSavings (
    CET_ID
    , DiscountedSavingsGrosskWh
    , DiscountedSavingsNetkWh
    , DiscountedSavingsGrossThm
    , DiscountedSavingsNetThm
)
AS
(
    SELECT e.CET_ID
        ,CASE WHEN IsNull(RUL,0) >0 THEN
            CASE WHEN Kwh1 <> 0 THEN CASE WHEN Power(Rqf, Qm) <> 0 THEN CASE WHEN Ra <> 0 THEN CASE WHEN Power(Raf, eul-1) <> 0 THEN CASE WHEN IsNull(eul,0) <> 0 THEN Sum(Qty * ((IRkWh * RRkWh * Kwh1 * (1 + (1-1/(Power(Raf, rul-1)))/Ra)) + (IRkWh * RRkWh * Kwh2 * (1+(1-1/(Power(Raf, (eul-rul))))/Ra))/Power(Raf, rul))/ Power(Rqf, Qm)) ELSE 0 END END END END END
        ELSE
            CASE WHEN Kwh1 <> 0 THEN CASE WHEN Power(Rqf, Qm) <> 0 THEN CASE WHEN Ra <> 0 THEN CASE WHEN Power(Raf, eul-1) <> 0 THEN CASE WHEN IsNull(eul,0) <> 0 THEN Sum(Qty * ((IRkWh * RRkWh * Kwh1 * (1 + (1-1/(Power(Raf, eul-1)))/Ra)))/ Power(Rqf, Qm)) ELSE 0 END END END END END END as DiscountedSavingsGrossKwh
        ,CASE WHEN IsNull(RUL,0) >0 THEN
            CASE WHEN kWh1 <> 0 THEN CASE WHEN Power(Rqf, Qm) <> 0 THEN CASE WHEN Ra <> 0 THEN CASE WHEN Power(Raf, eul-1) <> 0 THEN CASE WHEN IsNull(eul,0) <> 0 THEN Sum((NTGRkWh+Coalesce(e.MEBens,@MEBens)) * Qty * ((IRkWh * RRkWh * kwh1 * (1 + (1-1/(Power(Raf, rul-1)))/Ra)) + (IRkWh * RRkWh * kwh2 * (1 + (1-1/(Power(Raf, (eul-rul)-1)))/Ra))/Power(Raf, rul))/ Power(Rqf, Qm)) ELSE 0 END END END END END
        ELSE
            CASE WHEN kWh1 <> 0 THEN CASE WHEN Power(Rqf, Qm) <> 0 THEN CASE WHEN Ra <> 0 THEN CASE WHEN Power(Raf, eul-1) <> 0 THEN CASE WHEN IsNull(eul,0) <> 0 THEN Sum((NTGRkWh+Coalesce(e.MEBens,@MEBens)) * Qty * ((IRkWh * RRkWh * kwh1 * (1 + (1-1/(Power(Raf, eul-1)))/Ra)))/ Power(Rqf, Qm)) ELSE 0 END END END END END END as DiscountedSavingsGrosskWh

        ,CASE WHEN IsNull(RUL,0) >0 THEN
            CASE WHEN Thm1 <> 0 THEN CASE WHEN Power(Rqf, Qm) <> 0 THEN CASE WHEN Ra <> 0 THEN CASE WHEN Power(Raf, eul-1) <> 0 THEN CASE WHEN IsNull(eul,0) <> 0 THEN Sum(Qty * ((IRThm * RRThm * Thm1 * (1 + (1-1/(Power(Raf, rul-1)))/Ra)) + (IRThm * RRThm * Thm2 * (1 + (1-1/(Power(Raf, (eul-rul)-1))/ Power(Raf, rul))/Ra)))/ Power(Rqf, Qm)) ELSE 0 END END END END END
        ELSE
            CASE WHEN Thm1 <> 0 THEN CASE WHEN Power(Rqf, Qm) <> 0 THEN CASE WHEN Ra <> 0 THEN CASE WHEN Power(Raf, eul-1) <> 0 THEN CASE WHEN IsNull(eul,0) <> 0 THEN Sum(Qty * ((IRThm * RRThm * Thm1 * (1 + (1-1/(Power(Raf, eul-1)))/Ra)))/ Power(Rqf, Qm)) ELSE 0 END END END END END END as DiscountedSavingsGrossThm
        ,CASE WHEN IsNull(RUL,0) >0 THEN
            CASE WHEN Thm1 <> 0 THEN CASE WHEN Power(Rqf, Qm) <> 0 THEN CASE WHEN Ra <> 0 THEN CASE WHEN Power(Raf, eul-1) <> 0 THEN CASE WHEN IsNull(eul,0) <> 0 THEN Sum((NTGRThm+Coalesce(e.MEBens,@MEBens)) * Qty * ((IRThm * RRThm * Thm1 * (1 + (1-1/(Power(Raf, rul-1)))/Ra)) + (IRThm * RRThm * Thm2 * (1 + (1-1/(Power(Raf, (eul-rul)-1)))/Ra))/Power(Raf, rul))/ Power(Rqf, Qm)) ELSE 0 END END END END END
        ELSE
            CASE WHEN Thm1 <> 0 THEN CASE WHEN Power(Rqf, Qm) <> 0 THEN CASE WHEN Ra <> 0 THEN CASE WHEN Power(Raf, eul-1) <> 0 THEN CASE WHEN IsNull(eul,0) <> 0 THEN Sum((NTGRThm+Coalesce(e.MEBens,@MEBens)) * Qty * ((IRThm * RRThm * Thm1 * (1 + (1-1/(Power(Raf, eul-1)))/Ra)))/ Power(Rqf, Qm)) ELSE 0 END END END END END END as DiscountedSavingsGrossThm

    FROM InputMeasurevw e
    LEFT JOIN Settingsvw s ON e.PA = s.PA
    WHERE s.[Version] = @AVCVersion
    Group By CET_ID, kWh1, Thm1, eul,rul, Rqf, Qm, Ra, Raf 
)
, LevelizedCost (
    CET_ID
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
)
AS
(
    SELECT e.CET_ID
      ,IsNull((ce.ElecBen + ce.GasBen),0) - IsNull(ce.TRCCost,0)  TRCLifecycleNetBen
      ,IsNull((ce.ElecBen + ce.GasBen),0) - IsNull(ce.PACCost,0)  PACLifecycleNetBen
      ,CASE WHEN ds.DiscountedSavingsNetkWh <> 0 THEN IsNull(ce.ElecBen,0)/ds.DiscountedSavingsNetkWh ELSE 0 END LevBenElec
      ,CASE WHEN ds.DiscountedSavingsNetThm <> 0 THEN IsNull(ce.GasBen,0)/ds.DiscountedSavingsNetThm ELSE 0 END LevBenGas
      ,CASE WHEN ds.DiscountedSavingsNetkWh <> 0 THEN (IsNull(ce.TRCCost,0) * ce.WeightedElecAlloc)/ds.DiscountedSavingsNetkWh ELSE 0 END LevTRCCost
      ,CASE WHEN ds.DiscountedSavingsNetkWh <> 0 THEN (IsNull(ce.TRCCostNoAdmin,0) * ce.WeightedElecAlloc)/ds.DiscountedSavingsNetkWh ELSE 0 END  LevTRCCostNoAdmin
      ,CASE WHEN ds.DiscountedSavingsNetkWh <> 0 THEN (IsNull(ce.PACCost,0) * ce.WeightedElecAlloc)/ds.DiscountedSavingsNetkWh ELSE 0 END  LevPACCost
      ,CASE WHEN ds.DiscountedSavingsNetkWh <> 0 THEN (IsNull(ce.PACCostNoAdmin,0) * ce.WeightedElecAlloc)/ds.DiscountedSavingsNetkWh ELSE 0 END  LevPACCostNoAdmin
      ,CASE WHEN ds.DiscountedSavingsNetkWh <> 0 THEN (IsNull(ce.RIMCost,0) * ce.WeightedElecAlloc)/ds.DiscountedSavingsNetkWh ELSE 0 END  LevRIMCost
      ,CASE WHEN ds.DiscountedSavingsNetkWh <> 0 THEN (IsNull(ce.ElecBen,0) - (IsNull(ce.TRCCost,0) * ce.WeightedElecAlloc))/ds.DiscountedSavingsNetkWh ELSE 0 END  LevNetBenTRCElec
      ,CASE WHEN ds.DiscountedSavingsNetkWh <> 0 THEN (IsNull(ce.ElecBen,0) - (IsNull(ce.TRCCostNoAdmin,0) * ce.WeightedElecAlloc))/ds.DiscountedSavingsNetkWh ELSE 0 END  LevNetBenTRCElecNoAdmin
      ,CASE WHEN ds.DiscountedSavingsNetkWh <> 0 THEN (IsNull(ce.ElecBen,0) - (IsNull(ce.PACCost,0) * ce.WeightedElecAlloc))/ds.DiscountedSavingsNetkWh ELSE 0 END  LevNetBenPACElec
      ,CASE WHEN ds.DiscountedSavingsNetkWh <> 0 THEN (IsNull(ce.ElecBen,0) - (IsNull(ce.PACCostNoAdmin,0) * ce.WeightedElecAlloc))/ds.DiscountedSavingsNetkWh ELSE 0 END  LevNetBenPACElecNoAdmin
      ,CASE WHEN ds.DiscountedSavingsNetThm <> 0 THEN (IsNull(ce.GasBen,0) - (IsNull(ce.TRCCost,0) * (1-ce.WeightedElecAlloc)))/ds.DiscountedSavingsNetThm ELSE 0 END  LevNetBenTRCGas
      ,CASE WHEN ds.DiscountedSavingsNetThm <> 0 THEN (IsNull(ce.GasBen,0) - (IsNull(ce.TRCCostNoAdmin,0) * (1-ce.WeightedElecAlloc)))/ds.DiscountedSavingsNetThm ELSE 0 END  LevNetBenTRCGasNoAdmin
      ,CASE WHEN ds.DiscountedSavingsNetThm <> 0 THEN (IsNull(ce.GasBen,0) - (IsNull(ce.PACCost,0) * (1-ce.WeightedElecAlloc)))/ds.DiscountedSavingsNetThm ELSE 0 END  LevNetBenPACGas
      ,CASE WHEN ds.DiscountedSavingsNetThm <> 0 THEN (IsNull(ce.GasBen,0) - (IsNull(ce.PACCostNoAdmin,0) * (1-ce.WeightedElecAlloc)))/ds.DiscountedSavingsNetThm ELSE 0 END  LevNetBenPACGasNoAdmin
      ,CASE WHEN ds.DiscountedSavingsNetkWh <> 0 THEN (IsNull(ce.ElecBen,0) - (IsNull(ce.RIMCost,0) * ce.WeightedElecAlloc))/ds.DiscountedSavingsNetkWh ELSE 0 END  LevNetBenRIMElec
      ,CASE WHEN ds.DiscountedSavingsNetThm <> 0 THEN (IsNull(ce.GasBen,0) - (IsNull(ce.RIMCost,0) * (1-ce.WeightedElecAlloc)))/ds.DiscountedSavingsNetThm ELSE 0 END  LevNetBenRIMGas

    FROM OutputCE  ce
    LEFT JOIN RebatesAndIncentives ri on CE.CET_ID = ri.CET_ID
    LEFT JOIN ParticipantCost p on ce.CET_ID = p.CET_ID
    LEFT JOIN DiscountedSavings ds on ce.CET_ID = ds.CET_ID
    LEFT JOIN InputMeasurevw e ON CE.CET_ID = e.CET_ID
    LEFT JOIN ProgramLevelIncentives pli on ce.PrgID = pli.PrgID
)

    INSERT INTO #OutputCost
    SELECT 
        @JobID AS JobID
        ,e.PA
        ,e.PrgID
        ,e.CET_ID

        -- **************** Measure Level Costs  ********************

      ,ri.[IncentiveToOthers] IncentiveToOthers
      ,ri.DILaborCost  DILaborCost
      ,ri.DIMaterialCost DIMaterialCost
      ,ri.[EndUserRebate] EndUserRebate

        -- **************** Measure Level Calculated Cost Fields  ********************
      ,ri.[RebatesandIncents]
      ,ri.[GrossMeasCost]
      ,pc.[ExcessIncentives]
      ,pc.MarkEffectPlusExcessInc
      ,pc.GrossParticipantCost
      ,pc.GrossParticipantCostAdjusted
      ,pc.NetParticipantCost
      ,pc.NetParticipantCostAdjusted

        -- **************** Measure Level Net Present Value Fields  ********************
      ,ri.[RebatesandIncentsPV]
      ,ri.[GrossMeasCostPV]
      ,pc.ExcessIncentivesPV
      ,pc.MarkEffectPlusExcessIncPV
      ,pc.GrossParticipantCostPV
      ,pc.GrossParticipantCostAdjustedPV
      ,pc.NetParticipantCostPV
      ,pc.NetParticipantCostAdjustedPV    

        -- **************** Program Level Weighted Costs  ********************
      ,pd.[AdminCostsOverheadAndGA] * ce.WeightedBenefits WtdAdminCostsOverheadAndGA
      ,pd.AdminCostsOther * ce.WeightedBenefits [WtdAdminCostsOther]
      ,pd.MarketingOutreach * ce.WeightedBenefits [WtdMarketingOutreach]
      ,pd.DIActivity * ce.WeightedBenefits [WtdDIActivity]
      ,pd.DIInstallation * ce.WeightedBenefits [WtdDIInstallation]
      ,pd.DIHardwareAndMaterials * ce.WeightedBenefits [WtdDIHardwareAndMaterials]
      ,pd.DIRebateAndInspection * ce.WeightedBenefits [WtdDIRebateAndInspection]
      ,pd.EMV * ce.WeightedBenefits [WtdEMV]
      ,pd.UserInputIncentive * ce.WeightedBenefits [WtdUserInputIncentive]
      ,pd.CostsRecoveredFromOtherSources * ce.WeightedBenefits [WtdCostsRecoveredFromOtherSources]
      ,  (pd.SumProgramCosts * ce.WeightedBenefits) 
        AS [ProgramCosts]
      , ri.[IncentiveToOthers] + ri.DILaborCost + ri.DIMaterialCost + ri.[EndUserRebate] + (pd.SumProgramCosts * ce.WeightedBenefits) 
        AS [TotalExpenditures]

        -- **************** Discounted Savings (Used for Levelized Costs)  ********************
      ,IsNull(ds.[DiscountedSavingsGrosskWh],0) [DiscountedSavingsGrosskWh]
      ,IsNull(ds.[DiscountedSavingsNetkWh],0) [DiscountedSavingsNetkWh]
      ,IsNull(ds.[DiscountedSavingsGrossThm],0) [DiscountedSavingsGrossThm]
      ,IsNull(ds.[DiscountedSavingsNetThm],0) [DiscountedSavingsNetThm]

        -- **************** LEVELIZED COST  ********************
        ,lv.TRCLifecycleNetBen 
        ,lv.PACLifecycleNetBen
        ,lv.LevBenElec
        ,lv.LevBenGas
        ,lv.LevTRCCost
        ,lv.LevTRCCostNoAdmin
        ,lv.LevPACCost
        ,lv.LevPACCostNoAdmin
        ,lv.LevRIMCost
        ,lv.LevNetBenTRCElec
        ,lv.LevNetBenTRCElecNoAdmin
        ,lv.LevNetBenPACElec
        ,lv.LevNetBenPACElecNoAdmin
        ,lv.LevNetBenTRCGas
        ,lv.LevNetBenTRCGasNoAdmin
        ,lv.LevNetBenPACGas
        ,lv.LevNetBenPACGasNoAdmin
        ,lv.LevNetBenRIMElec
        ,lv.LevNetBenRIMGas

    FROM InputMeasurevw e
    LEFT JOIN Settingsvw s ON e.PA = s.PA
    LEFT JOIN OutputCE ce on e.CET_ID  = ce.CET_ID
    LEFT JOIN ParticipantCost pc on e.CET_ID = pc.CET_ID
    LEFT JOIN RebatesAndIncentives ri on e.CET_ID = ri.CET_ID
    LEFT JOIN ProgramCostsSum ps on e.PrgID = ps.PrgID
    LEFT JOIN DiscountedSavings ds on e.CET_ID = ds.CET_ID
    LEFT JOIN ProgramCostDetail pd on e.PrgID = pd.PrgID
    LEFT JOIN LevelizedCost lv on e.CET_ID = lv.CET_ID
    GROUP BY e.PA
        ,e.PrgID
        ,e.CET_ID
        ,ce.ElecBen
        ,ce.GasBen
        ,ce.TRCCost
        ,ce.PACCost
        ,ce.WeightedBenefits
        ,ce.WeightedElecAlloc
        ,ds.DiscountedSavingsNetkWh
        ,ds.DiscountedSavingsGrosskWh
        ,ds.DiscountedSavingsNetThm
        ,ds.DiscountedSavingsGrossThm
        ,pc.NetParticipantCostPV
        ,pc.NetParticipantCostAdjustedPV
        ,ri.RebatesAndIncents
        ,ps.SumCostsNPV
      ,ri.[IncentiveToOthers]
      ,ri.DILaborCost
      ,ri.DIMaterialCost
      ,ri.[EndUserRebate]
      ,ri.[GrossMeasCost]
      ,ri.[RebatesandIncentsPV]
      ,pc.[ExcessIncentives]
      ,pc.MarkEffectPlusExcessInc
      ,pc.GrossParticipantCost
      ,pc.GrossParticipantCostAdjusted
      ,pc.NetParticipantCost
      ,pc.NetParticipantCostAdjusted
      ,ri.[GrossMeasCostPV]
      ,pc.[ExcessIncentivesPV]
      ,pc.MarkEffectPlusExcessIncPV
      ,pc.GrossParticipantCostPV
      ,pc.GrossParticipantCostAdjustedPV
      ,pc.NetParticipantCostPV
      ,pc.NetParticipantCostAdjustedPV    
      ,pd.[AdminCostsOverheadAndGA]
      ,pd.AdminCostsOther
      ,pd.MarketingOutreach
      ,pd.DIActivity
      ,pd.DIInstallation
      ,pd.DIHardwareAndMaterials
      ,pd.DIRebateAndInspection
      ,pd.EMV
      ,pd.UserInputIncentive
      ,pd.CostsRecoveredFromOtherSources
      ,pd.SumProgramCosts
      ,lv.TRCLifecycleNetBen
      ,lv.PACLifecycleNetBen
      ,lv.LevBenElec
      ,lv.LevBenGas
      ,lv.LevTRCCost
      ,lv.LevTRCCostNoAdmin
      ,lv.LevPACCost
      ,lv.LevPACCostNoAdmin
      ,lv.LevRIMCost
      ,lv.LevNetBenTRCElec
      ,lv.LevNetBenTRCElecNoAdmin
      ,lv.LevNetBenPACElec
      ,lv.LevNetBenPACElecNoAdmin
      ,lv.LevNetBenTRCGas
      ,lv.LevNetBenTRCGasNoAdmin
      ,lv.LevNetBenPACGas
      ,lv.LevNetBenPACGasNoAdmin      
      ,lv.LevNetBenRIMElec
      ,lv.LevNetBenRIMGas
      ORDER BY e.PA
      ,e.PrgID
      ,e.CET_ID
END

--Clear OutputCE
DELETE FROM OutputCost WHERE JobID = @JobID
DELETE FROM SavedCost WHERE JobID = @JobID

--Copy data in temporary table to OutputCE
INSERT INTO OutputCost
SELECT 
    [JobID]
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
      ,MarkEffectPlusExcessIncPV
      ,GrossParticipantCostPV
      ,GrossParticipantCostAdjustedPV
      ,NetParticipantCostPV
      ,NetParticipantCostAdjustedPV

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
      ,ISNULL(TRCLifecycleNetBen,0)
      ,ISNULL(PACLifecycleNetBen,0)
      ,ISNULL(LevBenElec,0)
      ,ISNULL(LevBenGas,0)
      ,ISNULL(LevTRCCost,0)
      ,ISNULL(LevTRCCostNoAdmin,0)
      ,ISNULL(LevPACCost,0)
      ,ISNULL(LevPACCostNoAdmin,0)
      ,ISNULL(LevRIMCost,0)
      ,ISNULL(LevNetBenTRCElec,0)
      ,ISNULL(LevNetBenTRCElecNoAdmin,0)
      ,ISNULL(LevNetBenPACElec,0)
      ,ISNULL(LevNetBenPACElecNoAdmin,0)
      ,ISNULL(LevNetBenTRCGas,0)
      ,ISNULL(LevNetBenTRCGasNoAdmin,0)
      ,ISNULL(LevNetBenPACGas,0)
      ,ISNULL(LevNetBenPACGasNoAdmin,0)
      ,ISNULL(LevNetBenRIMElec,0)
      ,ISNULL(LevNetBenRIMGas,0)

  FROM [#OutputCost]

DROP TABLE [#OutputCost]










GO


