/****** Object:  StoredProcedure [dbo].[CalcCE]    Script Date: 12/16/2019 12:51:29 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO






--#################################################################################################
-- Name             :  CalcCE
-- Date             :  06/30/2016
-- Author           :  Wayne Hauck
-- Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
-- Purpose          :  This stored procedure calculates cost effectiveness.
-- Usage            :  n/a
-- Called by        :  n/a
-- Copyright ©      :  Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
-- Change History   :  06/30/2016  Wayne Hauck added comment header
--                  :  12/30/2016   Wayne Hauck added measure inflation
--                  :   12/30/2016  Added modified Elec and Gas benefits to use savings-specific installation rate (IR) and realization rate (RR)
--                     
--#################################################################################################

CREATE PROCEDURE [dbo].[CalcCE]
@JobID INT = -1,
@MEBens FLOAT=NULL,
@MECost FLOAT=NULL,
@FirstYear INT = 2013,
@AVCVersion VARCHAR(255)

AS

SET NOCOUNT ON

PRINT 'Inserting electrical and gas benefits... Message 1'

IF @MEBens Is Null
    BEGIN
        SET @MEBens = IsNull((SELECT MarketEffectBens from CETJobs WHERE ID = @JobID),0)
    END 
IF @MECost Is Null
    BEGIN
        SET @MECost = IsNull((SELECT MarketEffectCost from CETJobs WHERE ID = @JobID),0)
    END 

PRINT 'Inserting electrical and gas benefits... Message 2'
CREATE TABLE [#OutputCE](
    [JobID]                 [int] NULL,
    [PA]                    [nvarchar](24) NULL,
    [PrgID]                 [nvarchar](255) NULL,
    [CET_ID]                [nvarchar](255) NULL,
    [ElecBen]               [float] NULL,
    [GasBen]                [float] NULL,
    [ElecBenGross]          [float] NULL,
    [GasBenGross]           [float] NULL,
    [TRCCost]               [float] NULL,
    [PACCost]               [float] NULL,
    [TRCCostGross]          [float] NULL,
    [TRCCostNoAdmin]        [float] NULL,
    [PACCostNoAdmin]        [float] NULL,
    [TRCRatio]              [float] NULL,
    [PACRatio]              [float] NULL,
    [TRCRatioNoAdmin]       [float] NULL,
    [PACRatioNoAdmin]       [float] NULL,
    [BillReducElec]         [float] NULL,
    [BillReducGas]          [float] NULL,
    [RIMCost]               [float] NULL,
    [WeightedBenefits]      [float] NULL,
    [WeightedElecAlloc]     [float] NULL,
    [WeightedProgramCost]   [float] NULL
) ON [PRIMARY]

BEGIN
PRINT 'Inserting electrical and gas benefits... Message 3'
    -- Insert into CE with correction for Null gas and elec
    INSERT INTO #OutputCE (
        JobID
        ,PA
        ,PrgID
        ,CET_ID
        ,ElecBen
        ,GasBen
        ,ElecBenGross
        ,GasBenGross
    )
    SELECT
        @JobID 
        ,e.PA
        ,e.PrgID
        ,e.CET_ID
--- ElecBen --------------------------------------------------------------------
        ,ISNULL(
            SUM(
                --- The following POWER() term is later divided by a similar
                --- term and could be simplified to POWER( Rqf, -1 ) or
                --- simply divide by Rqf:
                POWER(Rqf, Qm - 1) *
                (
                    Qty *
                    (
                        (
                            ( NTGRkWh + COALESCE( e.MEBens, @MEBens ) ) *
                            IRkWh *
                            RRkWh *
                            kWh1 *
                            ( Gen1 + Genfrac1 ) +
                            --- Transmission and Distribution terms elsewhere
                            --- apply IR and RR values for kWh rather than kW:
                            IRkW *
                            RRkW *
                            ( e.NTGRkw + COALESCE( e.MEBens, @MEBens ) ) *
                            DS1 *
                            ( TD1 + TDfrac1 )
                        ) +
                        IRkWh *
                        RRkWh *
                        (
                            ( NTGRkWh + COALESCE( e.MEBens, @MEBens) ) *
                            kWh2 *
                            (
                                ISNULL( Gen2, 0 ) +
                                ISNULL( Genfrac2_1, 0 ) +
                                ISNULL( Genfrac2_2, 0 )
                            ) +
                            --- Unlike the Transmission and Distribution term
                            --- for the first baseline, the following second
                            --- baseline applies the consumption (kWh) IR and RR
                            --- values rather than peak demand (kW):
                            ( e.NTGRkw + COALESCE( e.MEBens, @MEBens ) ) *
                            ISNULL( DS2, 0 ) *
                            (
                                ISNULL( TD2, 0 ) +
                                ISNULL( TDfrac2_1, 0 ) +
                                ISNULL( TDfrac2_2, 0 )
                            )
                        )
                    ) /
                    --- The following term cancels all but -1 power of the POWER
                    -- term above:
                    POWER( Rqf, Qm )
                )
            ),
            0
        ) AS ElecBen -- First and second baselines
--------------------------------------------------------------------------------
--- GasBen ---------------------------------------------------------------------
        ,ISNULL(
            SUM(
                --- The following POWER() term is later divided by a similar
                --- term and could be simplified to POWER( Rqf, -1 ) or
                --- simply divide by Rqf:
                POWER( Rqf, Qm - 1 ) *
                (
                    Qty *
                    (
                        (
                            ( e.NTGRThm + COALESCE( e.MEBens, @MEBens ) ) *
                            IRThm *
                            RRThm *
                            Thm1 *
                            ( Gas1 + ISNULL( Gasfrac1, 0 ) )
                        ) +
                        IRThm *
                        RRThm *
                        (
                            ( e.NTGRThm + COALESCE( e.MEBens, @MEBens ) ) *
                            Thm2 *
                            (
                                ISNULL( Gas2, 0 ) +
                                ISNULL( Gasfrac2_1, 0 ) +
                                ISNULL( Gasfrac2_2, 0 )
                            )
                        )
                    ) /
                    --- The following term cancels all but -1 power of the POWER
                    -- term above:
                    POWER( Rqf, Qm )
                )
            ),
            0
        ) AS GasBen -- First and second baselines
--------------------------------------------------------------------------------
--- ElecBenGross ---------------------------------------------------------------
        ,ISNULL(
            SUM(
                --- The following POWER() term is later divided by a similar
                --- term and could be simplified to POWER( Rqf, -1 ) or
                --- simply divide by Rqf:
                POWER( Rqf, Qm - 1 ) *
                (
                    Qty *
                    (
                        (
                            ( 1+ COALESCE( e.MEBens, @MEBens ) ) *
                            IRkWh *
                            RRkWh *
                            kWh1 *
                            ( Gen1 + Genfrac1 ) +
                            --- Unlike in ElecBen, the following Transmission
                            --- and Distribution term doesn't account for IR or
                            --- RR for kW or kWh:
                            DS1 *
                            ( TD1 + TDfrac1 )
                        ) +
                        (
                            IRkWh *
                            RRkWh *
                            kWh2 *
                            (
                                ISNULL( Gen2, 0 ) +
                                ISNULL( Genfrac2_1, 0 ) +
                                ISNULL( Genfrac2_2, 0 )
                            ) +
                            --- Unlike in ElecBen, the following Transmission
                            --- and Distribution term doesn't account for IR or
                            --- RR for kW or kWh:
                            ISNULL( DS2, 0 ) *
                            (
                                ISNULL( TD2, 0 ) +
                                ISNULL( TDfrac2_1, 0 ) +
                                ISNULL( TDfrac2_2, 0 )
                            )
                        )
                    ) /
                    --- The following term cancels all but -1 power of the POWER
                    -- term above:
                    POWER( Rqf, Qm )
                )
            ),
            0
        ) AS ElecBenGross -- First and second baselines
--------------------------------------------------------------------------------
--- GasBenGross ----------------------------------------------------------------
        ,ISNULL(
            SUM(
                POWER( Rqf, Qm - 1 ) *
                (
                    Qty *
                    (
                        (
                            --- The following term applies Market Effects to
                            --- only the first baseline of the Gross savings:
                            ( 1+ COALESCE( e.MEBens, @MEBens ) ) *
                            IRThm *
                            RRThm *
                            Thm1 *
                            ( Gas1 + ISNULL( Gasfrac1, 0 ) )
                        ) +
                        (
                            IRThm *
                            RRThm *
                            Thm2 *
                            (
                                ISNULL( Gas2, 0 ) +
                                ISNULL( Gasfrac2_1, 0 ) +
                                ISNULL( Gasfrac2_2, 0 )
                            )
                        )
                    ) /
                    POWER( Rqf, Qm )
                )
            ),
            0
        ) AS GasBenGross -- First and second baselines
--------------------------------------------------------------------------------
        --Note: below are E3-compatible equations
        --,IsNull(Sum(Power(Rqf, Qm - 1) * (Qty * IR * RR * (((NTGRkWh+Coalesce(e.MEBens,@MEBens)) * kWh1 * (Gen1 + Genfrac1) + (e.NTGRkw+Coalesce(e.MEBens,@MEBens)) * DS1 * (TD1 + TDfrac1)) + ((NTGRkWh+Coalesce(e.MEBens,@MEBens)) * kWh2 * (IsNull(Gen2,0) + IsNull(Genfrac2_1,0) + IsNull(Genfrac2_2,0)) + (e.NTGRkw+Coalesce(e.MEBens,@MEBens)) * IsNull(DS2,0) * (IsNull(TD2,0) + IsNull(TDfrac2_1,0) + IsNull(TDfrac2_2,0))))/ Power(Rqf, Qm))),0) -- First and second baselines
        --AS ElecBen
        --,IsNull(Sum(Power(Rqf, Qm - 1) * (Qty * IR * RR * (((e.NTGRThm+Coalesce(e.MEBens,@MEBens)) * Thm1 * (Gas1 + IsNull(Gasfrac1, 0))) + ((e.NTGRThm+Coalesce(e.MEBens,@MEBens)) * Thm2 * (IsNull(Gas2,0) + IsNull(Gasfrac2_1, 0) + IsNull(Gasfrac2_2, 0))))/ Power(Rqf, Qm))),0) -- First and second baselines
        --AS GasBen
        --,IsNull(Sum(Power(Rqf, Qm - 1) * (Qty * IR * RR * (((1+Coalesce(e.MEBens,@MEBens)) * kWh1 * (Gen1 + Genfrac1) + DS1 * (TD1 + TDfrac1)) + (kWh2 * (IsNull(Gen2,0) + IsNull(Genfrac2_1,0) + IsNull(Genfrac2_2,0)) + IsNull(DS2,0) * (IsNull(TD2,0) + IsNull(TDfrac2_1,0) + IsNull(TDfrac2_2,0))))/ Power(Rqf, Qm))),0) -- First and second baselines
        --AS ElecBenGross
        --,IsNull(Sum(Power(Rqf, Qm - 1) * (Qty * IR * RR * (((1+Coalesce(e.MEBens,@MEBens)) * Thm1 * (Gas1 + IsNull(Gasfrac1, 0))) + (Thm2 * (IsNull(Gas2,0) + IsNull(Gasfrac2_1, 0) + IsNull(Gasfrac2_2, 0))))/ Power(Rqf, Qm))),0) -- First and second baselines
        --AS GasBenGross

    FROM InputMeasurevw AS e
    LEFT JOIN Settingsvw s ON e.PA = s.PA AND s.[Version] = @AVCVersion

    --***************************** ELECTRIC  *************************************
    -- Get generation (Gen) and transmission & Distribution (TD) avoided costs, demand scalar (DS) and NTGRkw
    LEFT JOIN (
        SELECT CET_ID
            ,ISNULL(SUM(Gen / POWER(Rqf, Qac)),0) AS Gen1
            ,ISNULL(SUM(TD / POWER(Rqf, Qac)),0) AS TD1
            ,ISNULL(DS1,0) AS DS1
            ,NTGRkw
        FROM AvoidedCostElecvw
        WHERE Qac BETWEEN Qm
                AND Qm + CONVERT(INT, eulq1) - 1
        GROUP BY CET_ID
            ,DS1
            ,NTGRkw
        ) AC ON e.CET_ID = AC.CET_ID

    -- Get fractional generation (Genfrac) and transmission & Distribution (TDfrac) avoided costs. Fractions are effective useful lives (eul) for fractions of a quarter. Fist Baseline fraction
    LEFT JOIN (
        SELECT CET_ID
            ,(eulq1 - CONVERT(INT, eulq1)) * (Gen / POWER(Rqf, Qac)) AS Genfrac1
            ,(eulq1 - CONVERT(INT, eulq1)) * (TD / POWER(Rqf, Qac)) AS TDfrac1
        FROM AvoidedCostElecvw
        WHERE Qac = CONVERT(INT, Qm + (eulq1))
        ) frac ON e.CET_ID = frac.CET_ID

    -- Get fractional generation (Genfrac) and transmission & Distribution (TDfrac) avoided costs. Second baseline fraction.
    LEFT JOIN (
        SELECT CET_ID
            ,CASE WHEN eulq2 > 0 AND  (eulq1 - CONVERT(INT, eulq1)) > 0 THEN (1-(eulq1 - CONVERT(INT, eulq1))) * (Gen / POWER(Rqf, Qac)) ELSE 0 END AS Genfrac2_1
            ,CASE WHEN eulq2 > 0 AND (eulq1 - CONVERT(INT, eulq1)) > 0 THEN (1-(eulq1 - CONVERT(INT, eulq1))) * (TD / POWER(Rqf, Qac)) ELSE 0 END AS TDfrac2_1
        FROM AvoidedCostElecvw
        WHERE Qac = CONVERT(INT, Qm + (eulq1))
        ) frac2_1 ON e.CET_ID = frac2_1.CET_ID


    ---- Get fractional Elec avoided costs (Elecfrac) - Second baseline
    LEFT JOIN (
        SELECT CET_ID
            ,ISNULL(SUM(Gen / POWER(Rqf, Qac)),0) AS Gen2
            ,ISNULL(SUM(TD / POWER(Rqf, Qac)),0) AS TD2
            ,ISNULL(DS2,0) AS DS2
            ,NTGRkw
        FROM AvoidedCostElecvw
        WHERE Qac BETWEEN Qm + eulq1 
                AND Qm + eulq2 - 1  
        GROUP BY CET_ID
            ,DS2
            ,NTGRkw
        ) AC2 ON e.CET_ID = AC2.CET_ID

    -- Get fractional generation (Genfrac) and transmission & Distribution (TDfrac) avoided costs. Fractions are effective useful lives (eul) for fractions of a quarter
    LEFT JOIN (
        SELECT CET_ID
            ,(eulq2 - CONVERT(INT, eulq2)) * (Gen / POWER(Rqf, Qac)) AS Genfrac2_2
            ,(eulq2 - CONVERT(INT, eulq2)) * (TD / POWER(Rqf, Qac)) AS TDfrac2_2
        FROM AvoidedCostElecvw
        WHERE Qac = CONVERT(INT, Qm + (eulq2))
        ) frac2_2 ON e.CET_ID = frac2_2.CET_ID

    --***************************** GAS  *************************************
    -- Get Gas avoided costs, and NTGRTherms
    LEFT JOIN (
        SELECT CET_ID
            ,ISNULL(SUM(Cost / POWER(Rqf, Qac)),0) AS Gas1
            ,NTGRThm
        FROM AvoidedCostGasvw
        WHERE Qac BETWEEN Qm
                AND Qm + CONVERT(INT, eulq1) - 1
        GROUP BY CET_ID
            ,NTGRThm
        ) gAC ON e.CET_ID = gAC.CET_ID


    -- Get fractional Gas avoided costs (Gasfrac). Fractions are effective useful lives (eul) for fractions of a quarter. Fist Baseline fraction
    LEFT JOIN (
        SELECT CET_ID
            ,(eulq1 - CONVERT(INT, eulq1)) * (Cost / POWER(Rqf, Qac)) AS Gasfrac1
        FROM AvoidedCostGasvw
        WHERE Qac = CONVERT(INT, Qm + eulq1)
        ) gfrac ON e.CET_ID = gfrac.CET_ID


    -- Get fractional Gas avoided costs (Gasfrac) - Second baseline
    LEFT JOIN (
        SELECT CET_ID
            ,CASE WHEN (eulq1 - CONVERT(INT, eulq1)) > 0 THEN (1-(eulq1 - CONVERT(INT, eulq1))) * (Cost / POWER(Rqf, Qac)) ELSE 0 END AS Gasfrac2_1
    FROM AvoidedCostGasvw
        WHERE Qac = CONVERT(INT, Qm + eulq1)
        ) gfrac2_1 ON e.CET_ID = gfrac2_1.CET_ID


    -- Get Gas avoided costs, and NTGRTherms - Second baseline
    LEFT JOIN (
        SELECT CET_ID
            ,ISNULL(SUM(Cost / POWER(Rqf, Qac)),0) AS Gas2
            ,NTGRThm
        FROM AvoidedCostGasvw
        WHERE Qac BETWEEN Qm + eulq1 
                AND Qm + eulq2 - 1  
        GROUP BY CET_ID
            ,NTGRThm
        ) gAC2 ON e.CET_ID = gAC2.CET_ID

    -- Get fractional Gas avoided costs (Gasfrac)
    LEFT JOIN (
        SELECT CET_ID
            ,(eulq2 - CONVERT(INT, eulq2)) * (Cost / POWER(Rqf, Qac)) AS Gasfrac2_2
        FROM AvoidedCostGasvw
        WHERE Qac = CONVERT(INT, Qm + (eulq2))
        ) gfrac2_2 ON e.CET_ID = gfrac2_2.CET_ID

    WHERE s.Version = @AVCVersion
    GROUP BY e.PA
        ,e.PrgID
        ,e.CET_ID
    ORDER BY e.PA
        ,e.PrgID
        ,e.CET_ID

END
PRINT 'Inserting electrical and gas benefits... Message 4'

BEGIN
    -- correct for null elec and gas benefits and EDFilledUnitGrMeaCost
    UPDATE #OutputCE SET ElecBen = IsNull(ElecBen,0), GasBen = IsNull(GasBen,0) 
END

PRINT 'Updating TRC and PAC costs...'
PRINT 'Inserting electrical and gas benefits... Message 5'

BEGIN
-- Update OutputCE table with Costs
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
, ProgramCosts (
    PrgID
    , SumCosts
    , SumCostsNPV
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
    FROM dbo.[InputProgramvw] c
    LEFT JOIN Settingsvw s ON c.PA = s.PA 
    WHERE s.[Version] = @AVCVersion
    GROUP BY c.PrgID, [Year], s.Raf
    )
, ProgramCostsSum (
    PrgID
    ,SumCosts
    , SumCostsNPV
    )
AS (
    SELECT PrgID
    , SUM(IsNull(SumCosts,0)) AS SumCosts
    , SUM(IsNull(SumCostsNPV,0)) AS SumCostsNPV
    FROM ProgramCosts
    GROUP BY PrgID
)
, RebatesAndIncentives (
    PrgID
    , CET_ID
    , NTGRCost
    , ExcessIncPV
    , RebatesPV
    , IncentsAndDIPV
    , GrossMeasCostPV
    , MeasureIncCost
    )
AS (
    SELECT PrgID, e.CET_ID, NTGRCost
    , Sum((Qty * CASE WHEN (e.IncentiveToOthers + e.DILaborCost + e.DIMaterialCost -e.UnitMeasureGrossCost) <=0 THEN 
        0 
    ELSE
        e.IncentiveToOthers + e.DILaborCost + e.DIMaterialCost - e.UnitMeasureGrossCost
    END)/ Power(Rqf, Qm)) AS ExcessIncPV
    , Sum(Qty * e.EndUserRebate / Power(Rqf, Qm)) As RebatesPV
    , Sum(Qty * (e.IncentiveToOthers + e.DILaborCost + e.DIMaterialCost) / Power(Rqf, Qm)) 
    As IncentsAndDIPV
    , Sum(Qty * (e.UnitMeasureGrossCost- CASE WHEN e.rul > 0 THEN (e.UnitMeasureGrossCost - e.MeasIncrCost)*Power((1+e.MeasInflation/4)/Rqf, e.rulq) ELSE 0  END) / Power(Rqf, Qm)) As GrossMeasCostPV
--  , Sum(Qty * (e.UnitMeasureGrossCost- CASE WHEN e.rul > 0 THEN (e.UnitMeasureGrossCost - e.MeasIncrCost)/Power(((1+e.MeasInflation)/4)*Rqf, e.rulq) ELSE 0  END) / Power(Rqf, Qm)) As GrossMeasCostPV
    , Sum(Qty * e.MeasIncrCost)  AS MeasureIncCost
FROM InputMeasurevw e
    LEFT JOIN Settingsvw s ON e.PA = s.PA
    WHERE s.[Version] = @AVCVersion
    GROUP BY PrgID, e.CET_ID, NTGRCost
    )
, BenefitsSum (
      PrgID
    , SumElecBen
    , SumGasBen
)
AS (
    SELECT PrgID
        ,Sum(CASE 
                WHEN ElecBen > 0
                    THEN ElecBen
                ELSE 0
                END) AS SumElecBen
        ,Sum(CASE 
                WHEN GasBen > 0
                    THEN GasBen
                ELSE 0
                END) AS SumGasBen
    FROM #OutputCE
    GROUP BY PrgID
)
, BenPos (
    CET_ID
    ,ElecBenPos
    ,GasBenPos
    ,SumBenPos
)
AS
(
    SELECT CET_ID
        , CASE WHEN ElecBen > 0 THEN ElecBen ELSE 0 END AS ElecBenPos
        , CASE WHEN GasBen > 0 THEN GasBen ELSE 0 END AS GasBenPos
        , CASE WHEN ElecBen > 0 THEN ElecBen ELSE 0 END + CASE WHEN GasBen > 0 THEN GasBen ELSE 0 END  AS SumBenPos
    FROM #OutputCE ce 
)
, ClaimCount (
      PrgID
    , ClaimCount
)
AS (
    SELECT PrgID
        ,Count(CET_ID) As ClaimCount
    FROM #OutputCE
    GROUP BY PrgID
)
, ExcessIncentives (
    CET_ID
    , ExcessIncentivesPV
)
AS
(
    SELECT CE.CET_ID
        , CASE WHEN ri.IncentsAndDIPV <=ri.GrossMeasCostPV THEN 0 ELSE ri.IncentsAndDIPV - ri.GrossMeasCostPV END AS ExcessIncentivesPV
    FROM #OutputCE  ce
    LEFT JOIN RebatesAndIncentives ri on CE.CET_ID = ri.CET_ID
    LEFT JOIN InputMeasurevw e ON CE.CET_ID = e.CET_ID
)
, GrossMeasureCostAdjusted (
    CET_ID
    ,  GrossMeasureCostAdjustedPV
    , MarkEffectPlusExcessIncPV
)
AS
(
    SELECT CE.CET_ID
        , ri.GrossMeasCostPV -  (ri.IncentsAndDIPV + ri.RebatesPV) + (ex.ExcessIncentivesPV) AS GrossMeasureCostAdjustedPV
        , Coalesce(e.MECost,@MECost) * ((ri.GrossMeasCostPV) + (ex.ExcessIncentivesPV)) AS MarkEffectPlusExcessIncPV
    FROM #OutputCE  ce
    LEFT JOIN RebatesAndIncentives ri on CE.CET_ID = ri.CET_ID
    LEFT JOIN InputMeasurevw e ON CE.CET_ID = e.CET_ID
    LEFT JOIN ExcessIncentives ex on ce.CET_ID = ex.CET_ID
)
, ParticipantCost (
    CET_ID
    , ExcessIncentives
    , GrossMeasureCostAdjusted
    , ParticipantCost
    , ParticipantCostPV
    , GrossParticipantCostPV
    , NetParticipantCostPV
)
AS
(
    SELECT CE.CET_ID
        , ex.ExcessIncentivesPV AS ExcessIncentives
        , ri.GrossMeasCostPV -  (ri.IncentsAndDIPV + ri.RebatesPV) + (ex.ExcessIncentivesPV) AS GrossMeasureCostAdjusted
        , ri.NTGRCost * (gma.GrossMeasureCostAdjustedPV) + (Coalesce(e.MECost,@MECost) * (ri.GrossMeasCostPV + ex.ExcessIncentivesPV)) AS ParticipantCost
        , (ri.NTGRCost * (gma.GrossMeasureCostAdjustedPV) + (Coalesce(e.MECost,@MECost) * (ri.GrossMeasCostPV + ex.ExcessIncentivesPV))) / Power(Rqf, Qm) AS ParticipantCostPV
        ,ri.GrossMeasCostPV - (ri.IncentsAndDIPV + ri.RebatesPV) + ex.ExcessIncentivesPV AS  GrossParticipantCostAdjustedPV
        ,ri.NTGRCost * (ri.GrossMeasCostPV - (ri.IncentsAndDIPV + ri.RebatesPV)+ ex.ExcessIncentivesPV) + MarkEffectPlusExcessIncPV AS  NetParticipantCostAdjustedPV
    FROM #OutputCE  ce
    LEFT JOIN RebatesAndIncentives ri on CE.CET_ID = ri.CET_ID
    LEFT JOIN ExcessIncentives ex on ri.CET_ID = ex.CET_ID
    LEFT JOIN InputMeasurevw e ON CE.CET_ID = e.CET_ID
    LEFT JOIN GrossMeasureCostAdjusted gma on ce.CET_ID = gma.CET_ID
    LEFT JOIN Settingsvw s ON e.PA = s.PA
    WHERE s.[Version] = @AVCVersion
)
, Calculations (
    CET_ID
    , Pac_Cost
    , TRC_Cost
    , TRC_CostGross
    , Pac_Cost_NoAdmin
    , TRC_Cost_NoAdmin
    , WeightedBenefits
    , WeightedElecAlloc
    , WeightedProgramCost
    , NTGRCost
    , ExcessIncentives
    , GrossMeasureCostAdjusted
    , ParticipantCost
    , ParticipantCostPV
    , GrossParticipantCostPV
    , NetParticipantCostPV
)
AS
(
    SELECT CE.CET_ID
        , CASE 
            WHEN (SumElecBen + SumGasBen <> 0)
                THEN (
                        CASE 
                            WHEN ElecBen > 0
                                THEN ElecBen
                            ELSE 0
                            END + CASE 
                            WHEN GasBen > 0
                                THEN GasBen
                            ELSE 0
                            END
                        ) / (SumElecBen + SumGasBen)
            ELSE 
                1.000 / cc.ClaimCount -- If no benefits then divide program costs evenly among claims
            END * 
            IsNull(pcSum.SumCostsNPV,0) + (Qty * (e.IncentiveToOthers + e.DILaborCost + e.DIMaterialCost + e.EndUserRebate) / Power(Rqf, Qm)) AS Pac_Cost
        ,CASE 
            WHEN (SumElecBen + SumGasBen) <> 0
                THEN (
                        CASE 
                            WHEN ElecBen > 0
                                THEN ElecBen
                            ELSE 0
                            END + CASE 
                            WHEN GasBen > 0
                                THEN GasBen
                            ELSE 0
                            END
                        ) / (SumElecBen + SumGasBen)
            ELSE 
                1.000 / cc.ClaimCount -- If no benefits then divide program costs evenly among claims
            END * 
            IsNull(pcSum.SumCostsNPV,0) + (Qty * (e.IncentiveToOthers + e.DILaborCost + e.DIMaterialCost + e.EndUserRebate) / Power(Rqf, Qm)) + 
                pc.NetParticipantCostPV AS TRC_Cost

        ,CASE 
            WHEN (SumElecBen + SumGasBen) <> 0
                THEN (
                        CASE 
                            WHEN ElecBen > 0
                                THEN ElecBen
                            ELSE 0
                            END + CASE 
                            WHEN GasBen > 0
                                THEN GasBen
                            ELSE 0
                            END
                        ) / (SumElecBen + SumGasBen)
            ELSE 
                1.000 / cc.ClaimCount -- If no benefits then divide program costs evenly among claims
            END * 
            IsNull(pcSum.SumCostsNPV,0) + (Qty * (e.IncentiveToOthers + e.DILaborCost + e.DIMaterialCost + e.EndUserRebate) / Power(Rqf, Qm)) + 
                pc.NetParticipantCostPV AS TRC_Cost_NoAdmin

        ,Qty * (e.IncentiveToOthers + e.DILaborCost + e.DIMaterialCost + e.EndUserRebate) / Power(Rqf, Qm) AS Pac_Cost_NoAdmin
        ,Qty * (e.IncentiveToOthers + e.DILaborCost + e.DIMaterialCost + e.EndUserRebate) / Power(Rqf, Qm) + pc.NetParticipantCostPV AS TRC_Cost_NoAdmin
        ,CASE 
            WHEN (SumElecBen + SumGasBen) <> 0
                THEN (
                        CASE 
                            WHEN ElecBen > 0
                                THEN ElecBen
                            ELSE 0
                            END + CASE 
                            WHEN GasBen > 0
                                THEN GasBen
                            ELSE 0
                            END
                        ) / (SumElecBen + SumGasBen)
            ELSE 
                1.000 / cc.ClaimCount -- If no benefits then divide program costs evenly among claims
            END  AS WeightedBenefits
        ,CASE WHEN SumBenPos <> 0 THEN ElecBenPos/SumBenPos ELSE 0 END  AS WeightedElectricAlloc
        , CASE 
            WHEN (SumElecBen <> 0 OR SumGasBen <> 0)
                THEN (
                        CASE 
                            WHEN ElecBen > 0
                                THEN ElecBen
                            ELSE 0
                            END + CASE 
                            WHEN GasBen > 0
                                THEN GasBen
                            ELSE 0
                            END
                        ) / (SumElecBen + SumGasBen)
            ELSE 
                1.000 / cc.ClaimCount -- If no benefits then divide program costs evenly among claims
            END * 
            IsNull(pcSum.SumCosts,0) AS WeightedProgramCost
        , e.NTGRCost
        , pc.ExcessIncentives
        , pc.GrossMeasureCostAdjusted
        , pc.ParticipantCost
        , pc.ParticipantCostPV
        , pc.GrossParticipantCostPV
        , pc.NetParticipantCostPV
    FROM #OutputCE CE
    LEFT JOIN ProgramCostsSum pcSum ON CE.PrgID = pcSum.PrgID
    LEFT JOIN RebatesAndIncentives ri on CE.CET_ID = ri.CET_ID
    LEFT JOIN ParticipantCost pc on ce.CET_ID = pc.CET_ID
    LEFT JOIN BenefitsSum bensSum ON CE.PrgID = bensSum.PrgID
    LEFT JOIN BenPos bp on ce.CET_ID = bp.CET_ID
    LEFT JOIN InputMeasurevw e ON CE.CET_ID = e.CET_ID
    LEFT JOIN ClaimCount cc on CE.PrgID = cc.PrgID
    LEFT JOIN Settingsvw s ON e.PA = s.PA
    WHERE s.[Version] = @AVCVersion
)
    UPDATE #OutputCE 
    SET 
         TRCCost = c.TRC_Cost
        ,TRCCostGross = c.TRC_CostGross
        ,PACCost = c.Pac_Cost
        ,TRCCostNoAdmin = c.TRc_Cost_NoAdmin
        ,PACCostNoAdmin = c.Pac_Cost_NoAdmin
        ,WeightedBenefits = c.WeightedBenefits
        ,WeightedElecAlloc = c.WeightedElecAlloc
        ,WeightedProgramCost = c.WeightedProgramCost
    FROM #OutputCE CE
    LEFT JOIN Calculations c ON CE.CET_ID = c.CET_ID
END


PRINT 'Calculating RIM Cost...'

BEGIN
-- Update RIM Test Costs
WITH RIMTest (
    CET_ID
    , RIMCostElec
    , RIMCostGas
    )
AS (
    SELECT 
        e.CET_ID
        ,IsNull(Sum(Qty * IR * RR * ((NTGRkWh+Coalesce(e.MEBens,@MEBens)) * (kWh1 * (IsNull(RateE1,0)+IsNull(RateEFrac1,0)) + (kWh2 * (IsNull(RateEFrac2_1,0)+IsNull(RateE2,0)+IsNull(RateEFrac2_2,0)))))),0) AS RimCostElec 
        ,IsNull(Sum(Qty * IR * RR * ((NTGRThm+Coalesce(e.MEBens,@MEBens)) * (Thm1 * (IsNull(RateG1,0)+IsNull(RateGFrac1,0)) + (Thm2 * (IsNull(RateGFrac2_1,0)+IsNull(RateG2,0)+IsNull(RateGFrac2_2,0)))))),0) AS RimCostGas
    FROM InputMeasurevw e
    LEFT JOIN Settingsvw s ON e.PA = s.PA and s.[Version] = @AVCVersion
    
--First baseline
    LEFT JOIN (
        SELECT CET_ID 
            ,IsNull(Sum([RateE] / Power(Raf, Qy-Yr1)),0) AS [RateE1]

        FROM [E3RateScheduleElecvw] 
        WHERE Qy Between Yr1 and Yr1 + (Convert(int,EUL1)-1)
        GROUP BY CET_ID, EUL1
        ) RE on e.CET_ID = RE.CET_ID

--First baseline, fraction
    LEFT JOIN (
        SELECT CET_ID 
            ,(eul1 - Convert(int,eul1)) *[RateE] / Power(Raf, Qy) AS [RateEFrac1]
        FROM [E3RateScheduleElecvw] 
        WHERE Qy = Convert(INT, Yr1 + (eul1))
        GROUP BY CET_ID, EUL1, RateE, Raf, Qy
        ) REfrac1 on e.CET_ID = REfrac1.CET_ID

--Second Baseline, first fraction
    LEFT JOIN (
        SELECT CET_ID 
            ,CASE WHEN eul2 > 0 AND  (eul1 - Convert(INT, eul1)) > 0 THEN (1-(eul1 - Convert(INT, eul1))) * (RateE / Power(Raf, Qy)) ELSE 0 END AS RateEfrac2_1
        FROM [E3RateScheduleElecvw] 
        WHERE Qy = Convert(INT, Yr1 + (eul1))
        GROUP BY CET_ID, EUL1, EUL2, RateE, Raf, Qy
        ) REfrac2_1 on e.CET_ID = REfrac2_1.CET_ID

--Second Baseline
    LEFT JOIN (
        SELECT CET_ID
            ,IsNull(Sum(RateE / Power(Raf, Qy)),0) AS RateE2
        FROM [E3RateScheduleElecvw] 
        WHERE Qy BETWEEN Yr1 + eul1 
                AND Yr1 + eul2 - 1  
        GROUP BY CET_ID
        ) RE2 ON e.CET_ID = RE2.CET_ID

--Second Baseline, Fraction 2
    LEFT JOIN (
        SELECT CET_ID
            ,(eul2 - Convert(INT, eul2)) * (RateE / Power(Raf, Qy)) AS RateEFrac2_2
        FROM [E3RateScheduleElecvw] 
        WHERE Qy = Convert(INT, Yr1 + (eul2))
        ) REfrac2_2 ON e.CET_ID = REfrac2_2.CET_ID

--*********************
----First baseline GAS
    LEFT JOIN (
        SELECT CET_ID 
            ,IsNull(Sum([RateG] / Power(Raf, Qy-Yr1)),0) AS [RateG1]

        FROM [E3RateScheduleGasvw] 
        WHERE Qy Between Yr1 and Yr1 + (Convert(int,EUL1)-1)
        GROUP BY CET_ID, EUL1
        ) RG on e.CET_ID = RG.CET_ID

--First baseline, fraction
    LEFT JOIN (
        SELECT CET_ID 
            ,(eul1 - Convert(int,eul1)) *[RateG] / Power(Raf, Qy) AS [RateGFrac1]
        FROM [E3RateScheduleGasvw] 
        WHERE Qy = Convert(INT, Yr1 + (eul1))
        GROUP BY CET_ID, EUL1, RateG, Raf, Qy
        ) RGfrac1 on e.CET_ID = RGfrac1.CET_ID

--Second Baseline, first fraction
    LEFT JOIN (
        SELECT CET_ID 
            ,CASE WHEN eul2 > 0 AND  (eul1 - Convert(INT, eul1)) > 0 THEN (1-(eul1 - Convert(INT, eul1))) * (RateG / Power(Raf, Qy)) ELSE 0 END AS RateGfrac2_1
        FROM [E3RateScheduleGasvw] 
        WHERE Qy = Convert(INT, Yr1 + (eul1))
        GROUP BY CET_ID, EUL1, EUL2, RateG, Raf, Qy
        ) RGfrac2_1 on e.CET_ID = RGfrac2_1.CET_ID

--Second Baseline
    LEFT JOIN (
        SELECT CET_ID
            ,IsNull(Sum(RateG / Power(Raf, Qy)),0) AS RateG2
        FROM [E3RateScheduleGasvw] 
        WHERE Qy BETWEEN Yr1 + eul1 
                AND Yr1 + eul2 - 1  
        GROUP BY CET_ID
        ) RG2 ON e.CET_ID = RG2.CET_ID

--Second Baseline, Fraction 2
    LEFT JOIN (
        SELECT CET_ID
            ,(eul2 - Convert(INT, eul2)) * (RateG / Power(Raf, Qy)) AS RateGFrac2_2
        FROM [E3RateScheduleGasvw] 
        WHERE Qy = Convert(INT, Yr1 + (eul2))
        ) RGfrac2_2 ON e.CET_ID = RGfrac2_2.CET_ID
    WHERE s.Version = @AVCVersion
    GROUP BY e.PA, e.PrgID, e.CET_ID, e.EUL1, re.RateE1, rg.RateG1, Qy
)
    UPDATE #OutputCE
    SET BillReducElec=t.RimCostElec, BillReducGas=t.RimCostGas, RimCost = t.RimCostElec + t.RimCostGas + ce.PacCost
    FROM #OutputCE ce
    LEFT JOIN RIMTest t ON CE.CET_ID = t.CET_ID

END 


PRINT 'Updating TRC and PAC ratios...'

BEGIN
    -- Update TRC and PAC Ratios at measure level
    UPDATE #OutputCE
    SET TRCRatio = CASE 
            WHEN TRCCost <> 0
                THEN (ElecBen + GasBen) / (TRCCost)
            ELSE 0
            END
        ,PACRatio = CASE 
            WHEN PACCost <> 0
                THEN (ElecBen + GasBen) / (PACCost)
            ELSE 0
            END
        ,TRCRatioNoAdmin = CASE 
            WHEN TRCCostNoAdmin <> 0
                THEN (ElecBen + GasBen) / (TRCCostNoAdmin)
            ELSE 0
            END
        ,PACRatioNoAdmin = CASE 
            WHEN PACCostNoAdmin <> 0
                THEN (ElecBen + GasBen) / (PACCostNoAdmin)
            ELSE 0
            END
END

--Clear OutputCE
DELETE FROM OutputCE WHERE JobID = @JobID
DELETE FROM SavedCE WHERE JobID = @JobID

--Copy data in temporary table to OutputCE
INSERT INTO OutputCE
SELECT 
      [JobID]
      ,[PA]
      ,[PrgID]
      ,[CET_ID]
      ,[ElecBen]
      ,[GasBen]
      ,[ElecBenGross]
      ,[GasBenGross]
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
  FROM [#OutputCE]

DROP TABLE [#OutputCE]

--PRINT 'Done!'





GO


