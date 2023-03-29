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
--                  :  12/30/2016  Wayne Hauck added measure inflation
--                  :  12/30/2016  Added modified Elec and Gas benefits to use savings-specific installation rate (IR) and realization rate (RR)
--                  :  02/11/2020  Robert Hansen reformatted for readability and added comments to identify possible errors
--                  :  07/23/2020  Robert Hansen applied logic to remove negative benefits to measure costs
--                  :              Added four fields to #OutputCE table variable:
--                  :                + ElecNegBen
--                  :                + GasNegBen
--                  :                + ElecNegBenGross
--                  :                + GasNegBenGross
--                  :              Added ElecNegBen and GasNegBen (and _Gross) to measure-level cost columns:
--                  :                + PAC_Cost
--                  :                + PAC_Cost_NoAdmin
--                  :                + TRC_Cost
--                  :                + TRC_CostGross
--                  :                + TRC_Cost_NoAdmin
--                  :  08/03/2020  Robert Hansen added switch to negative benefits logic to apply
--                  :              only to measures marked with 'FuelSub' in the MeasImpactType
--                  :              field of the InputMeasure table
--                  :  11/03/2020  Robert Hansen removed JobID from join between InputMeasurevw
--                  :              and InputMeasureCEDARS, used for retrieving MeasImpactType
--                  :  11/19/2020  Robert Hansen fixed error in program-level summations in the
--                  :              in-memory table "BenefitsSum" introduced when the threshold
--                  :              logic applied to each measure which was removed in 07/23/2020
--                  :              due to similar logic in ElecBen and GasBen calculations, but
--                  :              again became necessary when "FuelSub" tag check was added in
--                  :              08/03/2020.
--                  :  12/18/2020  Robert Hansen added ISNULL() wrappers to benefits fields in
--                  :              WeightedBenefits calculation; replaced erroneous "OR" with
--                  :              "AND" in ElecBenGross calculation.
--                     
--#################################################################################################

IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('dbo.CalcCE'))
   exec('CREATE PROCEDURE [dbo].[CalcCE] AS BEGIN SET NOCOUNT ON; END')
GO

ALTER PROCEDURE [dbo].[CalcCE]
    @JobID INT = -1,
    @MEBens FLOAT = NULL,
    @MECost FLOAT = NULL,
    @FirstYear INT = 2013,
    @AVCVersion VARCHAR(255)
AS

SET NOCOUNT ON

PRINT 'Inserting electrical and gas benefits... Message 1'

IF @MEBens Is Null
    BEGIN
        SET @MEBens = ISNULL((SELECT MarketEffectBens from CETJobs WHERE ID = @JobID),0)
    END 
IF @MECost Is Null
    BEGIN
        SET @MECost = ISNULL((SELECT MarketEffectCost from CETJobs WHERE ID = @JobID),0)
    END 

PRINT 'Inserting electrical and gas benefits... Message 2'
CREATE TABLE [#OutputCE](
    [JobID] [int] NULL,
    [PA] [nvarchar](24) NULL,
    [PrgID] [nvarchar](255) NULL,
    [CET_ID] [nvarchar](255) NULL,
    [ElecBen] [float] NULL,
    [GasBen] [float] NULL,
    [ElecBenGross] [float] NULL,
    [GasBenGross] [float] NULL,
    [ElecNegBen] [float] NULL,
    [GasNegBen] [float] NULL,
    [ElecNegBenGross] [float] NULL,
    [GasNegBenGross] [float] NULL,
    [TRCCost] [float] NULL,
    [PACCost] [float] NULL,
    [TRCCostGross] [float] NULL,
    [TRCCostNoAdmin] [float] NULL,
    [PACCostNoAdmin] [float] NULL,
    [TRCRatio] [float] NULL,
    [PACRatio] [float] NULL,
    [TRCRatioNoAdmin] [float] NULL,
    [PACRatioNoAdmin] [float] NULL,
    [BillReducElec] [float] NULL,
    [BillReducGas] [float] NULL,
    [RIMCost] [float] NULL,
    [WeightedBenefits] [float] NULL,
    [WeightedElecAlloc] [float] NULL,
    [WeightedProgramCost] [float] NULL

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
        ,ElecNegBen
        ,GasNegBen
        ,ElecNegBenGross
        ,GasNegBenGross
    )
    SELECT
        @JobID AS JobID
        ,e.PA AS PA
        ,e.PrgID AS PrgID
        ,e.CET_ID AS CET_ID
--- ElecBen (Net Lifecycle) ----------------------------------------------------
--- PVBenNet[E]: Present value net electricity benefits
        --- ISNULL should be applied inside SUM:
        ,ISNULL(
            SUM(
                --- The following POWER term is cancelled by denominator--both should be replaced by dividing by Rqf:
                POWER( s.Rqf, e.Qm - 1 ) *
                --- IN_M,Q:
                e.Qty *
                (
                    --- First Baseline:
                    -- Remove negative savings from benefits from fuel substitution measures:
                    CASE
                        WHEN e.kWh1 < 0 AND ec.MeasImpactType LIKE '%FuelSub'
                        THEN 0
                        ELSE
                            ( e.NTGRkWh + COALESCE( e.MEBens, @MEBens ) ) *
                            e.IRkWh *
                            e.RRkWh *
                            e.kWh1 *
                            --- PV[Gen] -- Present value Generation benefits:
                            ( AC.Gen1 + frac.Genfrac1 )
                    END +
                    -- Remove negative savings from benefits from fuel substitution measures:
                    CASE
                        WHEN AC.DS1 < 0 AND ec.MeasImpactType LIKE '%FuelSub'
                        THEN 0
                        ELSE
                            ( e.NTGRkw + COALESCE( e.MEBens, @MEBens ) ) *
                            e.IRkW *
                            e.RRkW *
                            AC.DS1 *
                            --- PV[TD] -- Present value transmission/distribution benefits:
                            ( AC.TD1 + frac.TDfrac1 )
                    END +
                    --- Second Baseline:
                    -- Remove negative savings from benefits from fuel substitution measures:
                    CASE
                        WHEN e.kWh2 < 0 AND ec.MeasImpactType LIKE '%FuelSub'
                        THEN 0
                        ELSE
                            ( e.NTGRkWh + COALESCE( e.MEBens, @MEBens ) ) *
                            e.IRkWh *
                            e.RRkWh *
                            e.kWh2 *
                            --- PV[Gen] -- Present value generation benefits:
                            (
                                ISNULL( AC2.Gen2, 0 ) +
                                ISNULL( frac2_1.Genfrac2_1, 0 ) +
                                ISNULL( frac2_2.Genfrac2_2, 0 )
                            )
                    END +
                    -- Remove negative savings from benefits from fuel substitution measures:
                    CASE
                        WHEN ISNULL( AC2.DS2, 0 ) < 0 AND ec.MeasImpactType LIKE '%FuelSub'
                        THEN 0
                        ELSE
                            -- TEMPORARILY REPLACED IRkW AND RRkW WITH kWh VERSIONS
                            e.IRkWh *
                            e.RRkWh *
                            ( e.NTGRkW + COALESCE( e.MEBens, @MEBens ) ) *
                            --e.IRkW *
                            --e.RRkW *
                            --- PV[TD] -- Present value transmission/distribution benefits:
                            ISNULL( AC2.DS2, 0 ) *
                            (
                                ISNULL( AC2.TD2, 0 ) +
                                ISNULL( frac2_1.TDfrac2_1, 0 ) +
                                ISNULL( frac2_2.TDfrac2_2, 0 )
                            )
                    END
                ) /
                --- The following POWER term cancels that in the numerator--both can be replaced by dividing by Rqf
                POWER( s.Rqf, e.Qm )
            ),
            0
        ) AS ElecBen
--------------------------------------------------------------------------------
--- GasBen (Net Lifecycle) -----------------------------------------------------
--- NetPVBenTOT[G]: Present value of net gas benefits
        --- ISNULL should be applied inside SUM:
        ,ISNULL(
            SUM(
                --- The following POWER term is cancelled by denominator--both should be replaced by dividing by Rqf:
                POWER( s.Rqf, e.Qm - 1 ) *
                e.Qty *
                (
                    --- First Baseline:
                    -- Remove negative savings from benefits from fuel substitution measures:
                    CASE
                        WHEN e.Thm1 < 0 AND ec.MeasImpactType LIKE '%FuelSub'
                        THEN 0
                        ELSE
                            ( e.NTGRThm + COALESCE( e.MEBens, @MEBens ) ) *
                            e.IRThm *
                            e.RRThm *
                            e.Thm1 *
                            ( gAC.Gas1 + ISNULL( gfrac.Gasfrac1, 0 ) )
                    END +
                    --- Second Baseline:
                    -- Remove negative savings from benefits from fuel substitution measures:
                    CASE
                        WHEN e.Thm2 < 0 AND ec.MeasImpactType LIKE '%FuelSub'
                        THEN 0
                        ELSE
                            ( e.NTGRThm + COALESCE( e.MEBens, @MEBens ) ) *
                            e.IRThm *
                            e.RRThm *
                            e.Thm2 *
                            (
                                ISNULL( gAC2.Gas2, 0 ) +
                                ISNULL( gfrac2_1.Gasfrac2_1, 0 ) +
                                ISNULL( gfrac2_2.Gasfrac2_2, 0 )
                            )
                    END
                ) /
                --- The following POWER term cancels that in the numerator--both should be replaced by dividing by Rqf
                POWER( s.Rqf, e.Qm )
            ),
            0
        ) AS GasBen
--------------------------------------------------------------------------------
--- ElecBenGross (Lifecycle) ---------------------------------------------------
--- PVBen[E]: Present value gross electricity benefits
        --- ISNULL should be applied inside SUM:
        ,ISNULL(
            SUM(
                --- The following POWER term is cancelled by denominator--both should be replaced by dividing by Rqf:
                POWER( s.Rqf, e.Qm - 1 ) *
                e.Qty *
                (
                    --- First Baseline:
                    -- Remove negative savings from benefits from fuel substitution measures:
                    CASE
                        WHEN e.kWh1 < 0 AND ec.MeasImpactType LIKE '%FuelSub'
                        THEN 0
                        ELSE
                            -- THE FOLLOWING LINE IS INCLUDED TO MATCH EXISTING CODE:
                            ( 1 + COALESCE( e.MEBens, @MEBens ) ) *
                            e.IRkWh *
                            e.RRkWh *
                            e.kWh1 *
                            ( AC.Gen1 + frac.Genfrac1 )
                    END +
                    -- Remove negative savings from benefits from fuel substitution measures:
                    CASE
                        WHEN AC.DS1 < 0 AND ec.MeasImpactType LIKE '%FuelSub'
                        THEN 0
                        ELSE
                            -- REMOVING IRkW and RRkW TO MATCH EXISTING CODE
                            --e.IRkW *
                            --e.RRkW *
                            AC.DS1 *
                            ( AC.TD1 + frac.TDfrac1 )
                    END +
                    --- Second Baseline:
                    -- Remove negative savings from benefits from fuel substitution measures:
                    CASE
                        WHEN e.kWh2 < 0 AND ec.MeasImpactType LIKE '%FuelSub'
                        THEN 0
                        ELSE
                            --- Market Effects correctly are not included:
                            e.IRkWh *
                            e.RRkWh *
                            e.kWh2 *
                            (
                                ISNULL( AC2.Gen2, 0 ) +
                                ISNULL( frac2_1.Genfrac2_1, 0 ) +
                                ISNULL( frac2_2.Genfrac2_2, 0 )
                            )
                    END +
                    -- Remove negative savings from benefits from fuel substitution measures:
                    CASE
                        WHEN ISNULL( AC2.DS2, 0 ) < 0 AND ec.MeasImpactType LIKE '%FuelSub'
                        THEN 0
                        ELSE
                            -- REMOVING IRkW and RRkW ONLY TO MATCH EXISTING CODE
                            --e.IRkW *
                            --e.RRkW *
                            ISNULL( AC2.DS2, 0 ) *
                            (
                                ISNULL( AC2.TD2, 0 ) +
                                ISNULL( frac2_1.TDfrac2_1, 0 ) +
                                ISNULL( frac2_2.TDfrac2_2, 0 )
                            )
                    END
                ) /
                --- The following POWER term cancels that in the numerator--both should be replaced by dividing by Rqf
                 POWER( s.Rqf, e.Qm )
            ),
            0
        ) AS ElecBenGross
--------------------------------------------------------------------------------
--- GasBenGross (Lifecycle) ----------------------------------------------------
--- PVBen[G]: Present value gross gas benefits
        ,ISNULL(
            SUM(
                --- The following POWER term is cancelled by denominator--both should be replaced by dividing by Rqf:
                POWER( s.Rqf, e.Qm - 1 ) *
                e.Qty *
                (
                    --- First Baseline:
                    -- Remove negative savings from benefits from fuel substitution measures:
                    CASE
                        WHEN e.Thm1 < 0 AND ec.MeasImpactType LIKE '%FuelSub'
                        THEN 0
                        ELSE
                            -- THE FOLLOWING LINE IS INCLUDED ONLY TO MATCH EXISTING CODE:
                            ( 1 + COALESCE( e.MEBens, @MEBens ) )*
                            e.IRThm *
                            e.RRThm *
                            e.Thm1 *
                            ( gAC.Gas1 + ISNULL( gfrac.Gasfrac1, 0 ) )
                    END +
                    --- Second Baseline:
                    -- Remove negative savings from benefits from fuel substitution measures:
                    CASE
                        WHEN e.Thm2 < 0 AND ec.MeasImpactType LIKE '%FuelSub'
                        THEN 0
                        ELSE
                            e.IRThm *
                            e.RRThm *
                            e.Thm2 *
                            (
                                ISNULL( gAC2.Gas2, 0 ) +
                                ISNULL( gfrac2_1.Gasfrac2_1, 0 ) +
                                ISNULL( gfrac2_2.Gasfrac2_2, 0 )
                            )
                    END
                ) /
                --- The following POWER term cancels that in the numerator--both should be replaced by dividing by Rqf
                POWER( s.Rqf, e.Qm )
            ),
            0
        ) AS GasBenGross
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--- ADDED THE FOLLOWING 4 FIELDS TO PROVIDE NEGATIVE BENEFITS TO TRC AND PAC --
--- ElecNegBen (Net Lifecycle) -------------------------------------------------
        ,SUM(
            ISNULL(
                --- The following POWER term is cancelled by denominator--both should be replaced by dividing by Rqf:
                POWER( s.Rqf, e.Qm - 1 ) *
                --- IN_M,Q:
                e.Qty *
                (
                    --- First Baseline:
                    -- Include negative savings only from fuel substitution measures:
                    CASE
                        WHEN e.kWh1 < 0 AND ec.MeasImpactType LIKE '%FuelSub'
                        THEN
                            ( e.NTGRkWh + COALESCE( e.MEBens, @MEBens ) ) *
                            e.IRkWh *
                            e.RRkWh *
                            ABS( e.kWh1 ) *
                            --- PV[Gen] -- Present value Generation benefits:
                            ( AC.Gen1 + frac.Genfrac1 )
                        ELSE 0
                    END +
                    -- Include negative savings only from fuel substitution measures:
                    CASE
                        WHEN AC.DS1 < 0 AND ec.MeasImpactType LIKE '%FuelSub'
                        THEN
                            ( e.NTGRkw + COALESCE( e.MEBens, @MEBens ) ) *
                            e.IRkW *
                            e.RRkW *
                            ABS( AC.DS1 ) *
                            --- PV[TD] -- Present value transmission/distribution benefits:
                            ( AC.TD1 + frac.TDfrac1 )
                        ELSE 0
                    END +
                    --- Second Baseline:
                    -- Include negative savings only from fuel substitution measures:
                    CASE
                        WHEN e.kWh2 < 0 AND ec.MeasImpactType LIKE '%FuelSub'
                        THEN
                            ( e.NTGRkWh + COALESCE( e.MEBens, @MEBens ) ) *
                            e.IRkWh *
                            e.RRkWh *
                            ABS( e.kWh2 ) *
                            --- PV[Gen] -- Present value generation benefits:
                            (
                                ISNULL( AC2.Gen2, 0 ) +
                                ISNULL( frac2_1.Genfrac2_1, 0 ) +
                                ISNULL( frac2_2.Genfrac2_2, 0 )
                            )
                        ELSE 0
                    END +
                    -- Include negative savings only from fuel substitution measures:
                    CASE
                        WHEN ISNULL( AC2.DS2, 0 ) < 0 AND ec.MeasImpactType LIKE '%FuelSub'
                        THEN
                            ( e.NTGRkw + COALESCE( e.MEBens, @MEBens ) ) *
                            -- TEMPORARILY REPLACING IRkW AND RRkW WITH kWh VERSIONS
                            e.IRkWh *
                            e.RRkWh *
                            --e.IRkW *
                            --e.RRkW *
                            --- PV[TD] -- Present value transmission/distribution benefits:
                            ABS( AC2.DS2 ) *
                            (
                                ISNULL( AC2.TD2, 0 ) +
                                ISNULL( frac2_1.TDfrac2_1, 0 ) +
                                ISNULL( frac2_2.TDfrac2_2, 0 )
                            )
                        ELSE 0
                    END
                ) /
                --- The following POWER term cancels that in the numerator--both can be replaced by dividing by Rqf
                POWER( s.Rqf, e.Qm )
            ,0)
        ) AS ElecNegBen
--------------------------------------------------------------------------------
--- GasNegBen (Net Lifecycle) --------------------------------------------------
        ,SUM(
            ISNULL(
                --- The following POWER term is cancelled by denominator--both should be replaced by dividing by Rqf:
                POWER( s.Rqf, e.Qm - 1 ) *
                e.Qty *
                (
                    --- First Baseline:
                    -- Include negative savings only from fuel substitution measures:
                    CASE
                        WHEN e.Thm1 < 0 AND ec.MeasImpactType LIKE '%FuelSub'
                        THEN
                            ( e.NTGRThm + COALESCE( e.MEBens, @MEBens ) ) *
                            e.IRThm *
                            e.RRThm *
                            ABS( e.Thm1 ) *
                            ( gAC.Gas1 + ISNULL( gfrac.Gasfrac1, 0 ) )
                        ELSE 0
                    END +
                    --- Second Baseline:
                    -- Include negative savings only from fuel substitution measures:
                    CASE
                        WHEN e.Thm2 < 0 AND ec.MeasImpactType LIKE '%FuelSub'
                        THEN
                            ( e.NTGRThm + COALESCE( e.MEBens, @MEBens ) ) *
                            e.IRThm *
                            e.RRThm *
                            ABS( e.Thm2 ) *
                            (
                                ISNULL( gAC2.Gas2, 0 ) +
                                ISNULL( gfrac2_1.Gasfrac2_1, 0 ) +
                                ISNULL( gfrac2_2.Gasfrac2_2, 0 )
                            )
                        ELSE 0
                    END
                ) /
                --- The following POWER term cancels that in the numerator--both should be replaced by dividing by Rqf
                POWER( s.Rqf, e.Qm )
            ,0)
        ) AS GasNegBen
--------------------------------------------------------------------------------
--- ElecNegBenGross (Lifecycle) ---------------------------------------------------
        ,SUM(
            ISNULL(
                --- The following POWER term is cancelled by denominator--both should be replaced by dividing by Rqf:
                POWER( s.Rqf, e.Qm - 1 ) *
                e.Qty *
                (
                    --- First Baseline:
                    -- Include negative savings only from fuel substitution measures:
                    CASE
                        WHEN e.kWh1 < 0 AND ec.MeasImpactType LIKE '%FuelSub'
                        THEN
                            --ADDING THE FOLLOWING LINE TO MATCH EXISTING CET
                            ( 1 + COALESCE( e.MEBens, @MEBens ) ) *
                            e.IRkWh *
                            e.RRkWh *
                            ABS( e.kWh1 ) *
                            ( AC.Gen1 + frac.Genfrac1 )
                        ELSE 0
                    END +
                    -- Include negative savings only from fuel substitution measures:
                    CASE
                        WHEN AC.DS1 < 0 AND ec.MeasImpactType LIKE '%FuelSub'
                        THEN
                            --REMOVING THE FOLLOWING TWO LINES TO MATCH EXISTING CET
                            --e.IRkW *
                            --e.RRkW *
                            ABS( AC.DS1 ) *
                            ( AC.TD1 + frac.TDfrac1 )
                        ELSE 0
                    END +
                    --- Second Baseline:
                    -- Include negative savings only from fuel substitution measures:
                    CASE
                        WHEN e.kWh2 < 0 AND ec.MeasImpactType LIKE '%FuelSub'
                        THEN
                            --- Market Effects correctly are not included:
                            e.IRkWh *
                            e.RRkWh *
                            ABS( e.kWh2 ) *
                            (
                                ISNULL( AC2.Gen2, 0 ) +
                                ISNULL( frac2_1.Genfrac2_1, 0 ) +
                                ISNULL( frac2_2.Genfrac2_2, 0 )
                            )
                        ELSE 0
                    END +
                    -- Include negative savings only from fuel substitution measures:
                    CASE
                        WHEN ISNULL( AC2.DS2, 0 ) < 0 AND ec.MeasImpactType LIKE '%FuelSub'
                        THEN
                            --REMOVING THE FOLLOWING TWO LINES TO MATCH EXISTING CET
                            --e.IRkW *
                            --e.RRkW *
                            ABS( AC2.DS2 ) *
                            (
                                ISNULL( AC2.TD2, 0 ) +
                                ISNULL( frac2_1.TDfrac2_1, 0 ) +
                                ISNULL( frac2_2.TDfrac2_2, 0 )
                            )
                        ELSE 0
                    END
                ) /
                --- The following POWER term cancels that in the numerator--both should be replaced by dividing by Rqf
                 POWER( s.Rqf, e.Qm )
            ,0)
        ) AS ElecNegBenGross
--------------------------------------------------------------------------------
--- GasNegBenGross (Lifecycle) ----------------------------------------------------
        ,SUM(
            ISNULL(
                --- The following POWER term is cancelled by denominator--both should be replaced by dividing by Rqf:
                POWER( s.Rqf, e.Qm - 1 ) *
                e.Qty *
                (

                    --- First Baseline:
                    -- Include negative savings only from fuel substitution measures:
                    CASE
                        WHEN e.Thm1 < 0 AND ec.MeasImpactType LIKE '%FuelSub'
                        THEN
                            --ADDING THE FOLLOWING LINE TO MATCH EXISTING CET
                            ( 1 + COALESCE( e.MEBens, @MEBens ) ) *
                            e.IRThm *
                            e.RRThm *
                            ABS( e.Thm1 ) *
                            ( gAC.Gas1 + ISNULL( gfrac.Gasfrac1, 0 ) )
                        ELSE 0
                    END +
                    --- Second Baseline:
                    -- Include negative savings only from fuel substitution measures:
                    CASE
                        WHEN e.Thm2 < 0 AND ec.MeasImpactType LIKE '%FuelSub'
                        THEN
                            e.IRThm *
                            e.RRThm *
                            ABS( e.Thm2 ) *
                            (
                                ISNULL( gAC2.Gas2, 0 ) +
                                ISNULL( gfrac2_1.Gasfrac2_1, 0 ) +
                                ISNULL( gfrac2_2.Gasfrac2_2, 0 )
                            )
                        ELSE 0
                    END
                ) /
                --- The following POWER term cancels that in the numerator--both should be replaced by dividing by Rqf
                POWER( s.Rqf, e.Qm )
            ,0)
        ) AS GasNegBenGross

--------------------------------------------------------------------------------
        --Note: below are E3-compatible equations
        --,ISNULL(SUM(POWER(Rqf, Qm - 1) * (Qty * IR * RR * (((NTGRkWh+COALESCE(e.MEBens,@MEBens)) * kWh1 * (Gen1 + Genfrac1) + (e.NTGRkw+COALESCE(e.MEBens,@MEBens)) * DS1 * (TD1 + TDfrac1)) + ((NTGRkWh+COALESCE(e.MEBens,@MEBens)) * kWh2 * (ISNULL(Gen2,0) + ISNULL(Genfrac2_1,0) + ISNULL(Genfrac2_2,0)) + (e.NTGRkw+COALESCE(e.MEBens,@MEBens)) * ISNULL(DS2,0) * (ISNULL(TD2,0) + ISNULL(TDfrac2_1,0) + ISNULL(TDfrac2_2,0))))/ POWER(Rqf, Qm))),0) -- First and second baselines
        --AS ElecBen
        --,ISNULL(SUM(POWER(Rqf, Qm - 1) * (Qty * IR * RR * (((e.NTGRThm+COALESCE(e.MEBens,@MEBens)) * Thm1 * (Gas1 + ISNULL(Gasfrac1, 0))) + ((e.NTGRThm+COALESCE(e.MEBens,@MEBens)) * Thm2 * (ISNULL(Gas2,0) + ISNULL(Gasfrac2_1, 0) + ISNULL(Gasfrac2_2, 0))))/ POWER(Rqf, Qm))),0) -- First and second baselines
        --AS GasBen
        --,ISNULL(SUM(POWER(Rqf, Qm - 1) * (Qty * IR * RR * (((1+COALESCE(e.MEBens,@MEBens)) * kWh1 * (Gen1 + Genfrac1) + DS1 * (TD1 + TDfrac1)) + (kWh2 * (ISNULL(Gen2,0) + ISNULL(Genfrac2_1,0) + ISNULL(Genfrac2_2,0)) + ISNULL(DS2,0) * (ISNULL(TD2,0) + ISNULL(TDfrac2_1,0) + ISNULL(TDfrac2_2,0))))/ POWER(Rqf, Qm))),0) -- First and second baselines
        --AS ElecBenGross
        --,ISNULL(SUM(POWER(Rqf, Qm - 1) * (Qty * IR * RR * (((1+COALESCE(e.MEBens,@MEBens)) * Thm1 * (Gas1 + ISNULL(Gasfrac1, 0))) + (Thm2 * (ISNULL(Gas2,0) + ISNULL(Gasfrac2_1, 0) + ISNULL(Gasfrac2_2, 0))))/ POWER(Rqf, Qm))),0) -- First and second baselines
        --AS GasBenGross

    FROM InputMeasurevw AS e
    LEFT JOIN (SELECT CEInputID, JobID, MeasImpactType FROM InputMeasureCEDARS) AS ec ON e.CET_ID = ec.CEInputID
    LEFT JOIN Settingsvw AS s
    ON e.PA = s.PA AND s.[Version] = @AVCVersion

    --***************************** ELECTRIC  *************************************
    -- Get generation (Gen) and transmission & Distribution (TD) avoided costs, demand scalar (DS) and NTGRkw
    LEFT JOIN (
        SELECT
            CET_ID
            ,SUM( ISNULL( AC.Gen / POWER( AC.Rqf, AC.Qac ), 0 ) ) AS Gen1
            ,SUM( ISNULL( AC.TD / POWER( AC.Rqf, AC.Qac ), 0 ) ) AS TD1
            ,ISNULL( AC.DS1, 0 ) AS DS1
            ,AC.NTGRkw
        FROM AvoidedCostElecvw AS AC
        WHERE AC.Qac BETWEEN Qm AND Qm + CONVERT( INT, eulq1 ) - 1
        GROUP BY CET_ID
            ,DS1
            ,NTGRkw
        ) AS AC ON e.CET_ID = AC.CET_ID

    -- Get fractional generation (Genfrac) and transmission & Distribution (TDfrac) avoided costs. Fractions are effective useful lives (eul) for fractions of a quarter. Fist Baseline fraction
    LEFT JOIN (
        SELECT
            CET_ID
            ,( eulq1 - FLOOR( eulq1 ) ) * (Gen / POWER( Rqf, Qac ) ) AS Genfrac1
            ,( eulq1 - FLOOR( eulq1 ) ) * (TD / POWER( Rqf, Qac ) ) AS TDfrac1
        FROM AvoidedCostElecvw
        WHERE Qac = Qm + CONVERT( INT, eulq1 )
        ) AS frac ON e.CET_ID = frac.CET_ID


    -- Get fractional generation (Genfrac) and transmission & Distribution (TDfrac) avoided costs. Second baseline fraction.
    LEFT JOIN (
        SELECT
            CET_ID
            ,CASE
                WHEN eulq2 > 0 AND ( eulq1 - FLOOR( eulq1 ) ) > 0
                THEN ( 1 - ( eulq1 - FLOOR( eulq1 ) ) ) * ( Gen / POWER( Rqf, Qac ) )
                ELSE 0
            END AS Genfrac2_1
            ,CASE
                WHEN eulq2 > 0 AND ( eulq1 - FLOOR( eulq1 ) ) > 0
                THEN ( 1 - ( eulq1 - FLOOR( eulq1 ) ) ) * ( TD / POWER( Rqf, Qac ) )
                ELSE 0
            END AS TDfrac2_1
        FROM AvoidedCostElecvw
        WHERE Qac = Qm + CONVERT( INT, eulq1 )
        ) AS frac2_1
    ON e.CET_ID = frac2_1.CET_ID


    ---- Get fractional Elec avoided costs (Elecfrac) - Second baseline
    LEFT JOIN (
        SELECT
            CET_ID
            ,SUM( ISNULL( Gen / POWER( Rqf, Qac ), 0 ) ) AS Gen2
            ,SUM( ISNULL( TD / POWER( Rqf, Qac ), 0 ) ) AS TD2
            ,ISNULL( DS2, 0 ) AS DS2
            ,NTGRkw
        FROM AvoidedCostElecvw
        WHERE Qac BETWEEN Qm + eulq1 
                AND Qm + eulq2 - 1  
        GROUP BY CET_ID
            ,DS2
            ,NTGRkw
        ) AS AC2
    ON e.CET_ID = AC2.CET_ID

    -- Get fractional generation (Genfrac) and transmission & Distribution (TDfrac) avoided costs. Fractions are effective useful lives (eul) for fractions of a quarter
    LEFT JOIN (
        SELECT
            CET_ID
            ,( eulq2 - ROUND( eulq2, 0, 1 ) ) * ( Gen / POWER( Rqf, Qac ) ) AS Genfrac2_2
            ,( eulq2 - ROUND( eulq2, 0, 1 ) ) * ( TD / POWER( Rqf, Qac ) ) AS TDfrac2_2
        FROM AvoidedCostElecvw
        WHERE Qac = QM + CONVERT( INT, eulq2 )
        ) AS frac2_2
    ON e.CET_ID = frac2_2.CET_ID

    --***************************** GAS  *************************************
    -- Get Gas avoided costs, and NTGRTherms
    LEFT JOIN (
        SELECT
            CET_ID
            ,SUM( ISNULL( Cost / POWER( Rqf, Qac ), 0 ) ) AS Gas1
            ,NTGRThm
        FROM AvoidedCostGasvw
        WHERE Qac BETWEEN Qm AND Qm + CONVERT( INT, eulq1 ) - 1
        GROUP BY
            CET_ID
            ,NTGRThm
    ) AS gAC
    ON e.CET_ID = gAC.CET_ID


    -- Get fractional Gas avoided costs (Gasfrac). Fractions are effective useful lives (eul) for fractions of a quarter. Fist Baseline fraction
    LEFT JOIN (
        SELECT
            CET_ID
            ,( eulq1 - FLOOR( eulq1 ) ) * ( Cost / POWER( Rqf, Qac ) ) AS Gasfrac1
        FROM AvoidedCostGasvw
        WHERE Qac = Qm + CONVERT( INT, eulq1 )
    ) AS gfrac
    ON e.CET_ID = gfrac.CET_ID


    -- Get fractional Gas avoided costs (Gasfrac) - Second baseline
    LEFT JOIN (
        SELECT
            CET_ID
            ,CASE
                WHEN ( eulq1 - FLOOR( eulq1 ) ) > 0
                THEN ( 1 - ( eulq1 - FLOOR( eulq1 ) ) ) * ( Cost / POWER( Rqf, Qac ) )
                ELSE 0
            END AS Gasfrac2_1
        FROM AvoidedCostGasvw
        WHERE Qac = Qm + CONVERT( INT, eulq1 )
    ) AS gfrac2_1
    ON e.CET_ID = gfrac2_1.CET_ID


    -- Get Gas avoided costs, and NTGRTherms - Second baseline
    LEFT JOIN (
        SELECT
            CET_ID
            ,SUM( ISNULL( Cost / POWER( Rqf, Qac ), 0 ) ) AS Gas2
            ,NTGRThm
        FROM AvoidedCostGasvw
        WHERE Qac BETWEEN Qm + CONVERT( INT, eulq1 ) + 1 AND Qm + CONVERT( INT, eulq2 ) - 1 
        GROUP BY
            CET_ID
            ,NTGRThm
    ) AS gAC2
    ON e.CET_ID = gAC2.CET_ID

    -- Get fractional Gas avoided costs (Gasfrac)
    LEFT JOIN (
        SELECT
            CET_ID
            ,( eulq2 - FLOOR( eulq2 ) ) * ( Cost / POWER( Rqf, Qac ) ) AS Gasfrac2_2
        FROM AvoidedCostGasvw
        WHERE Qac = Qm + CONVERT( INT, eulq2 )
    ) AS gfrac2_2
    ON e.CET_ID = gfrac2_2.CET_ID

    WHERE s.Version = @AVCVersion
    GROUP BY
        e.PA
        ,e.PrgID
        ,e.CET_ID
    ORDER BY
        e.PA
        ,e.PrgID
        ,e.CET_ID

END
PRINT 'Inserting electrical and gas benefits... Message 4'

BEGIN
    -- correct for null elec and gas benefits and EDFilledUnitGrMeaCost
    UPDATE #OutputCE SET ElecBen = ISNULL( ElecBen, 0 ), GasBen = ISNULL( GasBen, 0 ) 
END

PRINT 'Updating TRC and PAC costs...'
PRINT 'Inserting electrical and gas benefits... Message 5'

BEGIN
-- Update OutputCE table with Costs
WITH
ProgramCosts (
    PrgID
    , SumCosts
    , SumCostsNPV
) AS (
    SELECT
        c.PrgID
        ,SUM(
            ISNULL( [AdminCostsOverheadAndGA], 0 ) 
            + ISNULL( [AdminCostsOther], 0 ) 
            + ISNULL( [MarketingOutreach], 0 ) 
            + ISNULL( [DIActivity], 0 ) 
            + ISNULL( [DIInstallation], 0 ) 
            + ISNULL( [DIHardwareAndMaterials], 0 ) 
            + ISNULL( [DIRebateAndInspection], 0 ) 
            + ISNULL( [EMV], 0 ) 
            + ISNULL( [UserInputIncentive], 0 ) 
            + ISNULL( [CostsRecoveredFromOtherSources], 0 )
        ) AS SumCosts
        ,SUM(
            ISNULL( [AdminCostsOverheadAndGA], 0 ) 
            + ISNULL( [AdminCostsOther], 0 ) 
            + ISNULL( [MarketingOutreach], 0 ) 
            + ISNULL( [DIActivity], 0 )
            + ISNULL( [DIInstallation], 0 ) 
            + ISNULL( [DIHardwareAndMaterials], 0 ) 
            + ISNULL( [DIRebateAndInspection], 0 ) 
            + ISNULL( [EMV], 0 ) 
            + ISNULL( [UserInputIncentive], 0 ) 
            + ISNULL( [CostsRecoveredFromOtherSources], 0 )
        ) /
        POWER( s.Raf, Convert( int, [Year]-@FirstYear )
        ) AS SumCostsNPV
    FROM dbo.[InputProgramvw] AS  c
    LEFT JOIN Settingsvw AS s
    ON c.PA = s.PA 
    WHERE s.[Version] = @AVCVersion
    GROUP BY c.PrgID, [Year], s.Raf
)
, ProgramCostsSum (
    PrgID,
    SumCosts,
    SumCostsNPV
) AS (
    SELECT PrgID,
    SUM(ISNULL(SumCosts,0)) AS SumCosts,
    SUM(ISNULL(SumCostsNPV,0)) AS SumCostsNPV
    FROM ProgramCosts
    GROUP BY PrgID
)
, RebatesAndIncentives (
    PrgID,
    CET_ID,
    NTGRCost,
    ExcessIncPV,
    RebatesPV,
    IncentsAndDIPV,
    GrossMeasCostPV,
    MeasureIncCost
) AS (
    SELECT
        PrgID,
        e.CET_ID,
        NTGRCost,
        SUM(
            (
                Qty *
                CASE
                    WHEN (e.IncentiveToOthers + e.DILaborCost + e.DIMaterialCost -e.UnitMeasureGrossCost) <=0
                    THEN 0 
                    ELSE e.IncentiveToOthers + e.DILaborCost + e.DIMaterialCost - e.UnitMeasureGrossCost
                END
            ) / POWER(s.Rqf, Qm)
        ) AS ExcessIncPV,
        SUM(
            Qty * e.EndUserRebate / POWER(s.Rqf, Qm)
        ) AS RebatesPV,
        SUM(
            Qty * (e.IncentiveToOthers + e.DILaborCost + e.DIMaterialCost) / POWER(s.Rqf, Qm)
        ) AS IncentsAndDIPV,
        SUM(
            Qty *
            (
                e.UnitMeasureGrossCost -
                CASE
                    WHEN e.rul > 0
                    THEN (e.UnitMeasureGrossCost - e.MeasIncrCost ) * POWER( ( 1 + e.MeasInflation / 4 ) / s.Rqf, e.rulq )
                    ELSE 0
                END
            ) / POWER(s.Rqf, Qm)
        ) AS GrossMeasCostPV
--      ,SUM(Qty * (e.UnitMeasureGrossCost- CASE WHEN e.rul > 0 THEN (e.UnitMeasureGrossCost - e.MeasIncrCost)/POWER(((1+e.MeasInflation)/4)*Rqf, e.rulq) ELSE 0  END) / POWER(Rqf, Qm)) As GrossMeasCostPV
        ,SUM(Qty * e.MeasIncrCost)  AS MeasureIncCost
    FROM InputMeasurevw e
    LEFT JOIN Settingsvw s ON e.PA = s.PA
    WHERE s.[Version] = @AVCVersion
    GROUP BY PrgID, e.CET_ID, NTGRCost
    )
, BenefitsSum (
    PrgID
    ,SumElecBen
    ,SumGasBen
    ,SumElecBenGross
    ,SumGasBenGross
)
AS (
    SELECT PrgID
        ,SUM(
            CASE
                WHEN ElecBen > 0
                THEN ElecBen
                ELSE 0
            END
        ) AS SumElecBen
        ,SUM(
            CASE
                WHEN GasBen > 0
                THEN GasBen
                ELSE 0
            END
        ) AS SumGasBen
        ,SUM(
            CASE
                WHEN ElecBenGross > 0
                THEN ElecBenGross
                ELSE 0
             END
        ) AS SumElecBenGross
        ,SUM(
            CASE
                WHEN GasBenGross > 0
                THEN GasBenGross
                ELSE 0
            END
        ) AS GasBenGross
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
    , GrossMeasureCostAdjustedPV
    , MarkEffectPlusExcessIncPV
)
AS
(
    SELECT CE.CET_ID
        , ri.GrossMeasCostPV -  (ri.IncentsAndDIPV + ri.RebatesPV) + (ex.ExcessIncentivesPV) AS GrossMeasureCostAdjustedPV
        , COALESCE(e.MECost,@MECost) * ((ri.GrossMeasCostPV) + (ex.ExcessIncentivesPV)) AS MarkEffectPlusExcessIncPV
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
        , ri.GrossMeasCostPV - (ri.IncentsAndDIPV + ri.RebatesPV) + (ex.ExcessIncentivesPV) AS GrossMeasureCostAdjusted
        , ri.NTGRCost * (gma.GrossMeasureCostAdjustedPV) + (COALESCE(e.MECost,@MECost) * (ri.GrossMeasCostPV + ex.ExcessIncentivesPV)) AS ParticipantCost
        , (ri.NTGRCost * (gma.GrossMeasureCostAdjustedPV) + (COALESCE(e.MECost,@MECost) * (ri.GrossMeasCostPV + ex.ExcessIncentivesPV))) / POWER(s.Rqf, Qm) AS ParticipantCostPV
        , ri.GrossMeasCostPV - (ri.IncentsAndDIPV + ri.RebatesPV) + ex.ExcessIncentivesPV AS  GrossParticipantCostAdjustedPV
        , ri.NTGRCost * (ri.GrossMeasCostPV - (ri.IncentsAndDIPV + ri.RebatesPV)+ ex.ExcessIncentivesPV) + MarkEffectPlusExcessIncPV AS  NetParticipantCostAdjustedPV
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
    , PAC_Cost
    , PAC_Cost_NoAdmin
    , TRC_Cost
    , TRC_CostGross
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
    SELECT
        CE.CET_ID
        , (
            CASE
                WHEN (SumElecBen + SumGasBen <> 0)
                THEN
                    (
                        CASE
                            WHEN ElecBen > 0
                            THEN ElecBen
                            ELSE 0
                        END +
                        CASE
                            WHEN GasBen > 0
                            THEN GasBen
                            ELSE 0
                        END
                    ) / ( SumElecBen + SumGasBen )
                ELSE
                    -- If no benefits then divide program costs evenly among claims
                    1.000 / cc.ClaimCount
            END * 
            ISNULL(pcSum.SumCostsNPV,0) +
            e.Qty *
            (
                e.IncentiveToOthers +
                e.DILaborCost +
                e.DIMaterialCost +
                e.EndUserRebate
            ) / POWER(s.Rqf, e.Qm) +
            -- Add negative benefits as costs
            CASE
                WHEN CE.ElecNegBen > 0 AND ec.MeasImpactType LIKE '%FuelSub'
                THEN CE.ElecNegBen
                ELSE 0
            END +
            CASE
                WHEN  CE.GasNegBen > 0 AND ec.MeasImpactType LIKE '%FuelSub'
                THEN  CE.GasNegBen
                ELSE 0
            END
        ) AS PAC_Cost
        , (
            e.Qty *
            (
                e.IncentiveToOthers +
                e.DILaborCost +
                e.DIMaterialCost +
                e.EndUserRebate
            ) / POWER(s.Rqf, e.Qm) +
            -- Add negative benefits as costs
            CASE
                WHEN CE.ElecNegBen > 0 AND ec.MeasImpactType LIKE '%FuelSub'
                THEN CE.ElecNegBen
                ELSE 0
            END +
            CASE
                WHEN  CE.GasNegBen > 0 AND ec.MeasImpactType LIKE '%FuelSub'
                THEN  CE.GasNegBen
                ELSE 0
            END
        ) AS PAC_Cost_NoAdmin
        , (
            CASE 
                WHEN (BensSum.SumElecBen + BensSum.SumGasBen) <> 0
                THEN
                    (
                        CASE 
                            WHEN CE.ElecBen > 0
                            THEN CE.ElecBen
                            ELSE 0
                        END +
                        CASE 
                            WHEN CE.GasBen > 0
                            THEN CE.GasBen
                            ELSE 0
                         END
                    ) / (BensSum.SumElecBen + BensSum.SumGasBen)
                ELSE
                    -- If no benefits then divide program costs evenly among claims
                    1.000 / cc.ClaimCount
            END *
            ISNULL(pcSum.SumCostsNPV,0) +
            e.Qty *
            (
                e.IncentiveToOthers +
                e.DILaborCost +
                e.DIMaterialCost +
                e.EndUserRebate
            ) / POWER(s.Rqf, e.Qm) +
            pc.NetParticipantCostPV +
            -- Add negative benefits as costs
            CASE
                WHEN CE.ElecNegBen > 0 AND ec.MeasImpactType LIKE '%FuelSub'
                THEN CE.ElecNegBen
                ELSE 0
            END +
            CASE
                WHEN  CE.GasNegBen > 0 AND ec.MeasImpactType LIKE '%FuelSub'
                THEN  CE.GasNegBen
                ELSE 0
            END
        ) AS TRC_Cost
        , (
            CASE 
                WHEN (SumElecBenGross + SumGasBenGross) <> 0
                THEN
                    (
                        CASE
                            WHEN ElecBenGross > 0
                            THEN ElecBenGross
                            ELSE 0
                        END +
                        CASE
                            WHEN GasBenGross > 0
                            THEN GasBenGross
                            ELSE 0
                        END
                    ) / (SumElecBenGross + SumGasBenGross)
                ELSE
                    -- If no benefits then divide program costs evenly among claims
                    1.000 / cc.ClaimCount
            END * 
            ISNULL(pcSum.SumCostsNPV,0) +
            e.Qty *
            (
                e.IncentiveToOthers +
                e.DILaborCost +
                e.DIMaterialCost +
                e.EndUserRebate
            ) / POWER(s.Rqf, e.Qm) +
            pc.GrossParticipantCostPV +
            -- Add negative benefits as costs
            CASE
                WHEN CE.ElecNegBen > 0 AND ec.MeasImpactType LIKE '%FuelSub'
                THEN CE.ElecNegBen
                ELSE 0
            END +
            CASE
                WHEN  CE.GasNegBen > 0 AND ec.MeasImpactType LIKE '%FuelSub'
                THEN  CE.GasNegBen
                ELSE 0
            END
        ) AS TRC_CostGross
        , (
            e.Qty *
            (
                e.IncentiveToOthers +
                e.DILaborCost +
                e.DIMaterialCost +
                e.EndUserRebate
            ) / POWER(s.Rqf, e.Qm) +
            pc.NetParticipantCostPV +
            -- Add negative benefits as costs
            CASE
                WHEN CE.ElecNegBen > 0 AND ec.MeasImpactType LIKE '%FuelSub'
                THEN CE.ElecNegBen
                ELSE 0
            END +
            CASE
                WHEN  CE.GasNegBen > 0 AND ec.MeasImpactType LIKE '%FuelSub'
                THEN  CE.GasNegBen
                ELSE 0
            END
        ) AS TRC_Cost_NoAdmin
        , (
            CASE
                WHEN (ISNULL(SumElecBen,0) + ISNULL(SumGasBen,0)) <> 0
                THEN (
                    CASE
                        WHEN ISNULL(ElecBen,0) > 0
                        THEN ElecBen
                        ELSE 0
                    END +
                    CASE
                        WHEN ISNULL(GasBen,0) > 0
                        THEN GasBen
                        ELSE 0
                    END
                ) / (ISNULL(SumElecBen,0) + ISNULL(SumGasBen,0))
                ELSE 
                    1.000 / cc.ClaimCount -- If no benefits then divide program costs evenly among claims
            END
        ) AS WeightedBenefits
        ,(
            CASE
                WHEN SumBenPos <> 0
                THEN ElecBenPos / SumBenPos
                ELSE 0
            END
        ) AS WeightedElectricAlloc
        , (
            CASE 
                WHEN (SumElecBen <> 0 OR SumGasBen <> 0)
                THEN
                    (
                        CASE 
                            WHEN ElecBen > 0
                            THEN ElecBen
                            ELSE 0
                        END +
                        CASE 
                            WHEN GasBen > 0
                            THEN GasBen
                            ELSE 0
                        END
                    ) / (SumElecBen + SumGasBen)
            ELSE 
                1.000 / cc.ClaimCount -- If no benefits then divide program costs evenly among claims
            END * 
            ISNULL(pcSum.SumCosts,0)
        ) AS WeightedProgramCost
        , e.NTGRCost
        , pc.ExcessIncentives
        , pc.GrossMeasureCostAdjusted
        , pc.ParticipantCost
        , pc.ParticipantCostPV
        , pc.GrossParticipantCostPV
        , pc.NetParticipantCostPV
    FROM #OutputCE CE
    LEFT JOIN (SELECT CEInputID, JobID, MeasImpactType FROM InputMeasureCEDARS) AS ec ON CE.CET_ID = ec.CEInputID
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
        , TRCCostGross = c.TRC_CostGross
        , PACCost = c.PAC_Cost
        , TRCCostNoAdmin = c.TRC_Cost_NoAdmin
        , PACCostNoAdmin = c.PAC_Cost_NoAdmin
        , WeightedBenefits = c.WeightedBenefits
        , WeightedElecAlloc = c.WeightedElecAlloc
        , WeightedProgramCost = c.WeightedProgramCost
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
) AS (
    SELECT 
        e.CET_ID
        ,SUM(
            ISNULL(
                Qty *
                IR *
                RR *
                ( NTGRkWh + COALESCE( e.MEBens, @MEBens ) ) *
                (
                    kWh1 *
                    (
                        ISNULL( RateE1, 0 ) +
                        ISNULL( RateEFrac1, 0 )
                    ) +
                    kWh2 *
                    (
                        ISNULL( RateEFrac2_1, 0 ) +
                        ISNULL( RateE2, 0 ) +
                        ISNULL( RateEFrac2_2, 0 )
                    )
                ), 0
            )
        ) AS RIMCostElec
        ,SUM(
            ISNULL(
                Qty *
                IR *
                RR *
                ( NTGRThm + COALESCE( e.MEBens, @MEBens ) ) *
                (
                    Thm1 *
                    (
                        ISNULL( RateG1, 0 ) +
                        ISNULL( RateGFrac1, 0 )
                    ) +
                    Thm2 *
                    (
                        ISNULL( RateGFrac2_1, 0 ) +
                        ISNULL( RateG2, 0 ) +
                        ISNULL( RateGFrac2_2, 0 )
                    )
                ), 0
            )
        ) AS RimCostGas
    FROM InputMeasurevw e
    LEFT JOIN Settingsvw s ON e.PA = s.PA and s.[Version] = @AVCVersion
    
--First baseline
    LEFT JOIN (
        SELECT
            CET_ID 
            ,ISNULL(SUM([RateE] / POWER(Raf, Qy-Yr1)),0) AS [RateE1]
        FROM [E3RateScheduleElecvw] 
        WHERE Qy Between Yr1 and Yr1 + (Convert(int,EUL1)-1)
        GROUP BY CET_ID, EUL1
        ) RE on e.CET_ID = RE.CET_ID

--First baseline, fraction
    LEFT JOIN (
        SELECT
            CET_ID 
            ,(eul1 - Convert(int,eul1)) * [RateE] / POWER(Raf, Qy) AS [RateEFrac1]
        FROM [E3RateScheduleElecvw] 
        WHERE Qy = Convert(INT, Yr1 + (eul1))
        GROUP BY CET_ID, EUL1, RateE, Raf, Qy
        ) REfrac1 on e.CET_ID = REfrac1.CET_ID

--Second Baseline, first fraction
    LEFT JOIN (
        SELECT
            CET_ID 
            ,CASE
                WHEN eul2 > 0 AND (eul1 - Convert(INT, eul1)) > 0
                THEN (1-(eul1 - Convert(INT, eul1))) * (RateE / POWER(Raf, Qy))
                ELSE 0
            END AS RateEfrac2_1
        FROM [E3RateScheduleElecvw] 
        WHERE Qy = Convert(INT, Yr1 + (eul1))
        GROUP BY CET_ID, EUL1, EUL2, RateE, Raf, Qy
        ) REfrac2_1 on e.CET_ID = REfrac2_1.CET_ID

--Second Baseline
    LEFT JOIN (
        SELECT
            CET_ID
            ,ISNULL(SUM(RateE / POWER(Raf, Qy)),0) AS RateE2
        FROM [E3RateScheduleElecvw] 
        WHERE Qy BETWEEN Yr1 + eul1 AND Yr1 + eul2 - 1  
        GROUP BY CET_ID
        ) RE2 ON e.CET_ID = RE2.CET_ID

--Second Baseline, Fraction 2
    LEFT JOIN (
        SELECT CET_ID
            ,(eul2 - Convert(INT, eul2)) * (RateE / POWER(Raf, Qy)) AS RateEFrac2_2
        FROM [E3RateScheduleElecvw] 
        WHERE Qy = Convert(INT, Yr1 + (eul2))
        ) REfrac2_2 ON e.CET_ID = REfrac2_2.CET_ID

--*********************
----First baseline GAS
    LEFT JOIN (
        SELECT CET_ID 
            ,ISNULL(SUM([RateG] / POWER(Raf, Qy-Yr1)),0) AS [RateG1]

        FROM [E3RateScheduleGasvw] 
        WHERE Qy Between Yr1 and Yr1 + (Convert(int,EUL1)-1)
        GROUP BY CET_ID, EUL1
        ) RG on e.CET_ID = RG.CET_ID

--First baseline, fraction
    LEFT JOIN (
        SELECT CET_ID 
            ,(eul1 - Convert(int,eul1)) *[RateG] / POWER(Raf, Qy) AS [RateGFrac1]
        FROM [E3RateScheduleGasvw] 
        WHERE Qy = Convert(INT, Yr1 + (eul1))
        GROUP BY CET_ID, EUL1, RateG, Raf, Qy
        ) RGfrac1 on e.CET_ID = RGfrac1.CET_ID

--Second Baseline, first fraction
    LEFT JOIN (
        SELECT CET_ID 
            ,CASE WHEN eul2 > 0 AND  (eul1 - Convert(INT, eul1)) > 0 THEN (1-(eul1 - Convert(INT, eul1))) * (RateG / POWER(Raf, Qy)) ELSE 0 END AS RateGfrac2_1
        FROM [E3RateScheduleGasvw] 
        WHERE Qy = Convert(INT, Yr1 + (eul1))
        GROUP BY CET_ID, EUL1, EUL2, RateG, Raf, Qy
        ) RGfrac2_1 on e.CET_ID = RGfrac2_1.CET_ID

--Second Baseline
    LEFT JOIN (
        SELECT CET_ID
            ,ISNULL(SUM(RateG / POWER(Raf, Qy)),0) AS RateG2
        FROM [E3RateScheduleGasvw] 
        WHERE Qy BETWEEN Yr1 + eul1 
                AND Yr1 + eul2 - 1  
        GROUP BY CET_ID
        ) RG2 ON e.CET_ID = RG2.CET_ID

--Second Baseline, Fraction 2
    LEFT JOIN (
        SELECT CET_ID
            ,(eul2 - Convert(INT, eul2)) * (RateG / POWER(Raf, Qy)) AS RateGFrac2_2
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
    SET
        TRCRatio =
            CASE 
                WHEN TRCCost <> 0
                THEN (ElecBen + GasBen) / (TRCCost)
                ELSE 0
            END
        ,PACRatio =
            CASE 
                WHEN PACCost <> 0
                THEN (ElecBen + GasBen) / (PACCost)
                ELSE 0
            END
        ,TRCRatioNoAdmin =
            CASE 
                WHEN TRCCostNoAdmin <> 0
                THEN (ElecBen + GasBen) / (TRCCostNoAdmin)
                ELSE 0
            END
        ,PACRatioNoAdmin =
            CASE 
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


