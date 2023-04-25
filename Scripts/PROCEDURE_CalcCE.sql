/*
################################################################################
Name            :  CalcCE (procedure)
Date            :  06/30/2016
Author          :  Wayne Hauck
Company         :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose         :  This stored procedure calculates cost effectiveness.
Usage           :  n/a
Called by       :  n/a
Copyright �     :  Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
Change History  :  06/30/2016  Wayne Hauck added comment header
                :  12/30/2016  Wayne Hauck added measure inflation
                :  12/30/2016  Added modified Elec and Gas benefits to use savings-specific installation rate (IR) and realization rate (RR)
                :  2020-02-11  Robert Hansen reformatted for readability and added comments to identify possible errors
                :  2020-07-23  Robert Hansen applied logic to remove negative benefits to measure costs
                :              Added four fields to #OutputCE table variable:
                :                + ElecNegBen
                :                + GasNegBen
                :                + ElecNegBenGross
                :                + GasNegBenGross
                :              Added ElecNegBen and GasNegBen (and _Gross) to measure-level cost columns:
                :                + PAC_Cost
                :                + PAC_Cost_NoAdmin
                :                + TRC_Cost
                :                + TRC_CostGross
                :                + TRC_Cost_NoAdmin
                :  2020-08-03  Robert Hansen added switch to negative benefits logic to apply
                :              only to measures marked with 'FuelSub' in the MeasImpactType
                :              field of the InputMeasure table
                :  2020-11-03  Robert Hansen removed JobID from join between InputMeasurevw
                :              and InputMeasureCEDARS, used for retrieving MeasImpactType
                :  2020-11-19  Robert Hansen fixed error in program-level summations in the
                :              in-memory table "BenefitsSum" introduced when the threshold
                :              logic applied to each measure which was removed in 07/23/2020
                :              due to similar logic in ElecBen and GasBen calculations, but
                :              again became necessary when "FuelSub" tag check was added in
                :              08/03/2020.
                :  2020-12-18  Robert Hansen added ISNULL() wrappers to benefits fields in
                :              WeightedBenefits calculation; replaced erroneous "OR" with
                :              "AND" in ElecBenGross calculation.
                :  2021-04-26  Robert Hansen implemented second impact profile for additional
                :              load associated with fuel substitution measures, used to
                :              calculate 'negative savings' as new cost.
                :  2021-05-14  Robert Hansen implemented the following corrections to code errors:
                :                + Removed (1+MEBens) from Gross Benefits Calculations
                :                + Applied IRkW and RRkW to Demand Savings where
                :                  missing or where IRkWh and RRkWh are used improperly
                :                + Removed Rqf terms from benefits calculations
                :                 as net-present conversions occur in JOIN sub-queries
                :                + Moved ISNULL() functions inside SUM() aggregators
                :  2021-05-17  Robert Hansen incorporated the following new benefits and
                :              costs fields in test calculations:
                :                + UnitGasInfraBens,
                :                + UnitRefrigCosts,
                :                + UnitRefrigBens,
                :                + UnitMiscCosts,
                :                + MiscCostsDesc,
                :                + UnitMiscBens,
                :                + MiscBensDesc,
                :  2021-05-25  Robert Hansen removed references to MEBens and
                :              MECost fields from calculations, applying only
                :              procedure parameters @MEBens and @MECosts.
                :  2021-05-28  Robert Hansen renamed "NegBens" to "SupplyCost"
                :              and added Total System Benefits calculations
                :  2021-06-16  Robert Hansen commented out new fields for fuel
                :              substitution for implementation at a later date
                :  2021-07-08  Robert Hansen renamed "TotalSystemBenefits" to
                :              "TotalSystemBenefit" and included Refrigerant
                :              Costs in Total System Benefits calculation.
                :  2021-07-09  Robert Hansen applied net-to-gross to
                :              new benefits and costs in cost effectiveness
                :              and total system benefit calculations.
                :  2021-07-14  Robert Hansen fixed errors in total system
                :              benefit calculations and program savings
                :              weighting factors
                :  2021-09-03  Robert Hansen performed the following changes:
                :                + Include Avoided Gas Infrastructure Costs
                :                  (GasInfraBens) in Total System Benefit
                :                  calculations
                :                + Relax constraint against negative
                :                  participant costs for all measures except
                :                  fuel substitution and codes & standards
                :  2021-09-07  Robert Hansen removed MiscBens and MiscCosts
                :              from OtherBen and OtherCost, respectively.
                :  2021-12-06  Robert Hansen removed logic in calculating
                :              negative participant costs for fuel substitution
                :              and codes and standards measures
                :  2022-09-02  Robert Hansen added the following new fields
                :              related to water-energy nexus savings and included
                :              their values in calculating gross and net savings:
                :                + kWhWater1 (UnitkWhIOUWater1stBaseline in
                :                  InputMeasureCEDARS)
                :                + kWhWater2 (UnitkWhIOUWater2ndBaseline in
                :                  InputMeasureCEDARS)
                :              The following calculated output fields are also
                :              added:
                :                + WaterEnergyBen
                :                + WaterEnergyBenGross
                :                + WaterEnergyCost
                :                + WaterEnergyCostGross
                :  2022-11-04  Robert Hansen fixed error in WaterEnergyCost and
                :              WaterEnergyCostGross calculations so that the
                :              results are positive costs.
                :  2023-02-07  Robert Hansen added logic to treat all electric
                :              new construction (NC-AE) the same as fuel
                :              substitution
                :  2023-03-01  Robert Hansen fixed minor errors in updates for
                :              water-energy nexus and all electric new
                :              construction
                :  2023-03-07  Robert Hansen substituted calls to acw_1.Gen and
                :              acw_1.Gen with ace_1.Gen and ace_2 fields
                :  2023-03-08  Robert Hansen fixed error in logic for handling
                :              benefits and supply costs for fuel-substitution
                :              and all-electric new construction
                :  2023-03-13  Robert Hansen fixed error in TRC_Cost calculation
                :  2023-03-29  Robert Hansen fixed error in summing avoided gas
                :              cost quarters
                :  2023-04-04  Robert Hansen implemented sorting on CET_ID for
                :              output table
                :  2023-04-24  Robert Hansen renamed 'Gasfrac1' as 'Gas' in the
                :              acg_1 SELECT statement, allowing correct
                :              aggregation and summation of avoided gas costs.
################################################################################
*/

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

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
    JobID INT NULL,
    PA NVARCHAR(24) NULL,
    PrgID NVARCHAR(255) NULL,
    CET_ID NVARCHAR(255) NULL,
    ElecBen FLOAT NULL,
    GasBen FLOAT NULL,
    WaterEnergyBen FLOAT NULL,
    ElecBenGross FLOAT NULL,
    GasBenGross FLOAT NULL,
    WaterEnergyBenGross FLOAT NULL,
    OtherBen FLOAT NULL,
    OtherBenGross FLOAT NULL,
    ElecSupplyCost FLOAT NULL,
    GasSupplyCost FLOAT NULL,
    ElecSupplyCostGross FLOAT NULL,
    GasSupplyCostGross FLOAT NULL,
    /* New Water Energy Fields */
    WaterEnergyCost FLOAT NULL,
    WaterEnergyCostGross FLOAT NULL,
    /* End New Water Energy Fields */
    OtherCost FLOAT NULL,
    OtherCostGross FLOAT NULL,
    TotalSystemBenefit FLOAT NULL,
    TotalSystemBenefitGross FLOAT NULL,
    TRCCost FLOAT NULL,
    PACCost FLOAT NULL,
    TRCCostGross FLOAT NULL,
    TRCCostNoAdmin FLOAT NULL,
    PACCostNoAdmin FLOAT NULL,
    TRCRatio FLOAT NULL,
    PACRatio FLOAT NULL,
    TRCRatioNoAdmin FLOAT NULL,
    PACRatioNoAdmin FLOAT NULL,
    BillReducElec FLOAT NULL,
    BillReducGas FLOAT NULL,
    RIMCost FLOAT NULL,
    WeightedBenefits FLOAT NULL,
    WeightedElecAlloc FLOAT NULL,
    WeightedProgramCost FLOAT NULL
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
        ,WaterEnergyBen
        ,ElecBenGross
        ,GasBenGross
        ,WaterEnergyBenGross
        ,OtherBen
        ,OtherBenGross
        ,ElecSupplyCost
        ,GasSupplyCost
        ,WaterEnergyCost
        ,ElecSupplyCostGross
        ,GasSupplyCostGross
        ,WaterEnergyCostGross
        ,OtherCost
        ,OtherCostGross
    )
    SELECT
        @JobID AS JobID
        ,e.PA AS PA
        ,e.PrgID AS PrgID
        ,e.CET_ID AS CET_ID
--- ElecBen (Net Lifecycle) ----------------------------------------------------
--- PVBenNet[E]: Present value net electricity benefits
        ,SUM(
            CASE
                WHEN (e.MeasImpactType NOT LIKE '%FuelSub' AND e.MeasImpactType NOT LIKE '%NC-AE') OR e.kWh1>0
                THEN
                    ISNULL(
                        e.Qty *
                        (
                            ( e.NTGRkWh + @MEBens ) *
                            e.IRkWh *
                            e.RRkWh *
                            (
                                e.kWh1 * ace_1.Gen +
                                e.kWh2 * ace_2.Gen
                            )
                            +
                            ( e.NTGRkW + @MEBens ) *
                            e.IRkW *
                            e.RRkW *
                            (
                                ace_1.DS * ace_1.TD +
                                ISNULL( ace_2.DS, 0 ) * ISNULL( ace_2.TD, 0 )
                            )
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS ElecBen
--------------------------------------------------------------------------------
--- GasBen (Net Lifecycle) -----------------------------------------------------
--- NetPVBenTOT[G]: Present value of net gas benefits
        ,SUM(
            CASE 
                WHEN (e.MeasImpactType NOT LIKE '%FuelSub' AND e.MeasImpactType NOT LIKE '%NC-AE') OR e.Thm1>0
                THEN
                    ISNULL(
                        e.Qty *
                        ( e.NTGRThm + @MEBens ) *
                        e.IRThm *
                        e.RRThm *
                        (
                            e.Thm1 * acg_1.Gas +
                            e.Thm2 * ISNULL( acg_2.Gas, 0 )
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS GasBen
--------------------------------------------------------------------------------
--- WaterEnergyBen -------------------------------------------------------------
        ,SUM(
            CASE
                WHEN e.kWhWater1>0
                THEN
                    ISNULL(
                        e.Qty *
                        ( e.NTGRkWh + @MEBens ) *
                        e.IRkWh *
                        e.RRkWh *
                        (
                            e.kWhWater1 * ace_1.Gen +
                            e.kWhWater2 * ace_2.Gen
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS WaterEnergyBen
--------------------------------------------------------------------------------
--- ElecBenGross (Lifecycle) ---------------------------------------------------
--- PVBen[E]: Present value gross electricity benefits
        ,SUM(
            CASE
                WHEN (e.MeasImpactType NOT LIKE '%FuelSub' AND e.MeasImpactType NOT LIKE '%NC-AE') OR e.kWh1>0
                THEN
                    ISNULL(
                        e.Qty *
                        (
                            e.IRkWh *
                            e.RRkWh *
                            (
                                e.kWh1 * ace_1.Gen +
                                e.kWh2 * ISNULL( ace_2.Gen, 0 )
                            )
                            +
                            e.IRkW *
                            e.RRkW *
                            (
                                ace_1.DS * ace_1.TD
                                +
                                ISNULL( ace_2.DS, 0 ) * ISNULL( ace_2.TD, 0 )
                            )
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS ElecBenGross
--------------------------------------------------------------------------------
--- GasBenGross (Lifecycle) ----------------------------------------------------
--- PVBen[G]: Present value gross gas benefits
        ,SUM(
            CASE
                WHEN (e.MeasImpactType NOT LIKE '%FuelSub' AND e.MeasImpactType NOT LIKE '%NC-AE') OR e.Thm1>0
                THEN
                    ISNULL(
                        e.Qty *
                        e.IRThm *
                        e.RRThm *
                        (
                            e.Thm1 * acg_1.Gas +
                            e.Thm2 * ISNULL( acg_2.Gas, 0 )
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS GasBenGross
--------------------------------------------------------------------------------
--- WaterEnergyBenGross --------------------------------------------------------
        ,SUM(
            CASE
                WHEN e.kWhWater1>0
                THEN
                    ISNULL(
                        e.Qty *
                        e.IRkWh *
                        e.RRkWh *
                        (
                            e.kWhWater1 * ace_1.Gen +
                            e.kWhWater2 * ace_2.Gen
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS WaterEnergyBenGross
--------------------------------------------------------------------------------
--- OtherBen -------------------------------------------------------------------
--- Naive benefits based on user-input present values:
        ,SUM(
            e.Qty *
            (NTGRkWh + @MEBens) *
            (
                ISNULL( UnitGasInfraBens, 0 ) +
                ISNULL( UnitRefrigBens, 0 )
            )
        ) AS OtherBen
        ,SUM(
            e.Qty *
            (
                ISNULL( UnitGasInfraBens, 0 ) +
                ISNULL( UnitRefrigBens, 0 )
            )
        ) AS OtherBenGross
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--- ADDED THE FOLLOWING 4 FIELDS TO PROVIDE NEGATIVE BENEFITS TO TRC AND PAC ---
--- ElecSupplyCost (Net Lifecycle) ---------------------------------------------
        ,SUM(
            CASE
                WHEN (e.MeasImpactType LIKE '%FuelSub' OR e.MeasImpactType LIKE '%NC-AE') AND e.kWh1<0
                THEN
                    ISNULL(
                        -e.Qty *
                        (
                            ( e.NTGRkWh + @MEBens ) *
                            e.IRkWh *
                            e.RRkWh *
                            (
                                e.kWh1 * ace_1.Gen +
                                e.kWh2 * ISNULL( ace_2.Gen, 0 )
                            )
                            +
                            ( e.NTGRkw + @MEBens ) *
                            e.IRkW *
                            e.RRkW *
                            (
                                ace_1.DS * ace_1.TD +
                                ace_2.DS * ISNULL( ace_2.TD, 0 )
                            )
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS ElecSupplyCost
--------------------------------------------------------------------------------
--- GasSupplyCost (Net Lifecycle) ----------------------------------------------
        ,SUM(
            CASE
                WHEN (e.MeasImpactType LIKE '%FuelSub' OR e.MeasImpactType LIKE '%NC-AE') AND e.Thm1<0
                THEN
                    ISNULL(
                        -e.Qty *
                        ( e.NTGRThm + @MEBens ) *
                        e.IRThm *
                        e.RRThm *
                        (
                            e.Thm1 * acg_1.Gas +
                            e.Thm2 * ISNULL( acg_2.Gas, 0 )
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS GasSupplyCost
--------------------------------------------------------------------------------
--- WaterEnergyCost ------------------------------------------------------------
        ,SUM(
            CASE
                WHEN e.kWhWater1<0
                THEN
                    ISNULL(
                        -e.Qty *
                        ( e.NTGRkWh + @MEBens ) *
                        e.IRkWh *
                        e.RRkWh *
                        (
                            e.kWhWater1 * ace_1.Gen +
                            e.kWhWater2 * ace_2.Gen
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS WaterEnergyCost
--------------------------------------------------------------------------------
--- ElecSupplyCostGross (Lifecycle) --------------------------------------------
        ,SUM(
            CASE
                WHEN (e.MeasImpactType LIKE '%FuelSub' OR e.MeasImpactType LIKE '%NC-AE') AND e.kWh1<0
                THEN
                    ISNULL(
                        -e.Qty *
                        (
                            e.IRkWh *
                            e.RRkWh *
                            (
                                e.kWh1 * ace_1.Gen +
                                e.kWh2 * ISNULL( ace_2.Gen, 0 )
                            )
                            +
                            e.IRkW *
                            e.RRkW *
                            (
                                ace_1.DS * ace_1.TD +
                                ace_2.DS * ISNULL( ace_2.TD, 0 )
                            )
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS ElecSupplyCostGross
--------------------------------------------------------------------------------
--- GasSupplyCostGross (Lifecycle) ---------------------------------------------
        ,SUM(
            CASE
                WHEN (e.MeasImpactType LIKE '%FuelSub' OR e.MeasImpactType LIKE '%NC-AE') AND e.Thm1<0
                THEN
                    ISNULL(
                        -e.Qty *
                        e.IRThm *
                        e.RRThm *
                        (
                            e.Thm1 * acg_1.Gas +
                            e.Thm2 * ISNULL( acg_2.Gas, 0 )
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS GasSupplyCostGross
--------------------------------------------------------------------------------
--- WaterEnergyCostGross -------------------------------------------------------
        ,SUM(
            CASE
                WHEN e.kWhWater1<0
                THEN
                    ISNULL(
                        -e.Qty *
                        e.IRkWh *
                        e.RRkWh *
                        (
                            e.kWhWater1 * ace_1.Gen +
                            e.kWhWater2 * ace_2.Gen
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS WaterEnergyCostGross
--------------------------------------------------------------------------------
--- OtherCost ------------------------------------------------------------------
--- Naive costs based on user-input present values:
        ,SUM(
            e.Qty *
            (e.NTGRkWh + @MECost) *
            (
                ISNULL( e.UnitRefrigCosts, 0 )
            )
        ) AS OtherCost
        ,SUM(
            e.Qty *
            (
                ISNULL( e.UnitRefrigCosts, 0 )
            )
        ) AS OtherCostGross
    FROM InputMeasurevw AS e
    LEFT JOIN Settingsvw AS s
    ON e.PA = s.PA AND s.[Version] = @AVCVersion

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--- Avoided Electric Costs -----------------------------------------------------
--- First Baseline Avoided Electric Costs:
    LEFT JOIN (
        SELECT
            CET_ID
            ,SUM(Gen) AS Gen
            /*,SUM(Gen_AL) AS Gen_AL*/
            ,SUM(TD) AS TD
            /*,SUM(TD_AL) AS TD_AL*/
            ,DS
            /*,DS_AL*/
        FROM (
            --- Full Quarters, First Baseline ----------------------------------
            SELECT
                CET_ID
                ,ISNULL( Gen / POWER( Rqf, Qac ), 0 ) AS Gen
                /*,ISNULL( Gen_AL / POWER( Rqf, Qac ), 0 ) AS Gen_AL*/
                ,ISNULL( TD / POWER( Rqf, Qac ), 0 ) AS TD
                /*,ISNULL( TD_AL / POWER( Rqf, Qac ), 0 ) AS TD_AL*/
                ,ISNULL( DS1, 0 ) AS DS
                /*,ISNULL( DS1_AL, 0 ) AS DS_AL*/
            FROM AvoidedCostElecvw
            WHERE Qac BETWEEN Qm AND Qm + CONVERT( INT, eulq1 ) - 1

            --- Last Fractional Quarter, First Baseline ------------------------
            UNION SELECT
                CET_ID
                ,( eulq1 - FLOOR( eulq1 ) ) * (Gen / POWER( Rqf, Qac ) ) AS Gen
                /*,( eulq1 - FLOOR( eulq1 ) ) * (Gen_AL / POWER( Rqf, Qac ) ) AS Gen_AL*/
                ,( eulq1 - FLOOR( eulq1 ) ) * (TD / POWER( Rqf, Qac ) ) AS TD
                /*,( eulq1 - FLOOR( eulq1 ) ) * (TD_AL / POWER( Rqf, Qac ) ) AS TD_AL*/
                ,DS1 AS DS
                /*,DS1_AL AS DS_AL*/
            FROM AvoidedCostElecvw
            WHERE Qac = Qm + CONVERT( INT, eulq1 )
        )
        AS A GROUP BY CET_ID, DS/*, DS_AL*/
    ) AS ace_1 ON e.CET_ID=ace_1.CET_ID

--- Second Baseline Avoided Electric Costs:
    LEFT JOIN (
        SELECT
            CET_ID
            ,SUM(Gen) AS Gen
            /*,SUM(Gen_AL) AS Gen_AL*/
            ,SUM(TD) AS TD
            /*,SUM(TD_AL) AS TD_AL*/
            ,DS
            /*,DS_AL*/
        FROM (
            --- First Fractional Quarter, Second Baseline ----------------------
            SELECT
                CET_ID
                ,( 1 - ( eulq1 - FLOOR( eulq1 ) ) ) * ( Gen / POWER( Rqf, Qac ) ) AS Gen
                /*,( 1 - ( eulq1 - FLOOR( eulq1 ) ) ) * ( Gen_AL / POWER( Rqf, Qac ) ) AS Gen_AL*/
                ,( 1 - ( eulq1 - FLOOR( eulq1 ) ) ) * ( TD / POWER( Rqf, Qac ) ) AS TD
                /*,( 1 - ( eulq1 - FLOOR( eulq1 ) ) ) * ( TD_AL / POWER( Rqf, Qac ) ) AS TD_AL*/
                ,ISNULL( DS2, 0 ) AS DS
                /*,ISNULL( DS2_AL, 0 ) AS DS_AL*/
            FROM AvoidedCostElecvw
            WHERE Qac = Qm + CONVERT( INT, eulq1 )

            --- Full Quarters, Second Baseline ---------------------------------
            UNION SELECT
                CET_ID
                ,ISNULL( Gen / POWER( Rqf, Qac ), 0 ) AS Gen
                /*,ISNULL( Gen_AL / POWER( Rqf, Qac ), 0 ) AS Gen_AL*/
                ,ISNULL( TD / POWER( Rqf, Qac ), 0 ) AS TD
                /*,ISNULL( TD_AL / POWER( Rqf, Qac ), 0 ) AS TD_AL*/
                ,ISNULL( DS2, 0 ) AS DS
                /*,ISNULL( DS2_AL, 0 ) AS DS_AL*/
            FROM AvoidedCostElecvw
            WHERE Qac BETWEEN Qm + CONVERT( INT, eulq1 ) + 1 AND Qm + CONVERT( INT, eulq2 ) - 1

            --- Last Fractional Quarter, Second Baseline -----------------------
            UNION SELECT
                CET_ID
                ,( eulq2 - FLOOR( eulq2 ) ) * ( Gen / POWER( Rqf, Qac ) ) AS Gen
                /*,( eulq2 - FLOOR( eulq2 ) ) * ( Gen_AL / POWER( Rqf, Qac ) ) AS Gen_AL*/
                ,( eulq2 - FLOOR( eulq2 ) ) * ( TD / POWER( Rqf, Qac ) ) AS TD
                /*,( eulq2 - FLOOR( eulq2 ) ) * ( TD_AL / POWER( Rqf, Qac ) ) AS TD_AL*/
                ,ISNULL( DS2, 0 ) AS DS
                /*,ISNULL( DS2_AL, 0 ) AS DS_AL*/
            FROM AvoidedCostElecvw
            WHERE Qac = Qm + CONVERT( INT, eulq2 )
        ) AS A GROUP BY CET_ID, DS/*, DS_AL*/
    ) AS ace_2
    ON e.CET_ID = ace_2.CET_ID

--------------------------------------------------------------------------------
--- Avoided Gas Costs ----------------------------------------------------------
--- First Baseline Avoided Gas Costs:
    LEFT JOIN (
        SELECT
            CET_ID
            ,SUM(Gas) AS Gas
            --,SUM(Gas_AL) AS Gas_AL
        FROM (
            --- Full Quarters, First Baseline ----------------------------------
            SELECT
                CET_ID
                ,ISNULL( Cost / POWER( Rqf, Qac ), 0 ) AS Gas
                /*,ISNULL( Cost_AL / POWER( Rqf, Qac ), 0 ) AS Gas_AL*/
            FROM AvoidedCostGasvw
            WHERE Qac BETWEEN Qm AND Qm + CONVERT( INT, eulq1 ) - 1

            --- Last Fractional Quarter, First Baseline ------------------------
            UNION SELECT
                CET_ID
                ,( eulq1 - FLOOR( eulq1 ) ) * ( Cost / POWER( Rqf, Qac ) ) AS Gas
                /*,( eulq1 - FLOOR( eulq1 ) ) * ( Cost_AL / POWER( Rqf, Qac ) ) AS Gas_AL*/
            FROM AvoidedCostGasvw
            WHERE Qac = Qm + CONVERT( INT, eulq1 )
        ) AS A GROUP BY CET_ID
    ) AS acg_1 ON e.CET_ID = acg_1.CET_ID

--- Second Baseline Avoided Gas Costs:
    LEFT JOIN (
        SELECT
            CET_ID,
            SUM(Gas) AS Gas,
            /*SUM(Gas_AL) AS Gas_AL*/
        FROM (
            --- First Fractional Quarter, Second Baseline ----------------------
            SELECT
                CET_ID
                ,( 1 - ( eulq1 - FLOOR( eulq1 ) ) ) * ( Cost / POWER( Rqf, Qac ) ) AS Gas
                /*,( 1 - ( eulq1 - FLOOR( eulq1 ) ) ) * ( Cost_AL / POWER( Rqf, Qac ) ) AS Gas_AL*/
            FROM AvoidedCostGasvw
            WHERE Qac = Qm + CONVERT( INT, eulq1 )

            --- Full Quarters, Second Baseline ---------------------------------
            UNION SELECT
                CET_ID
                ,ISNULL( Cost / POWER( Rqf, Qac ), 0 ) AS Gas
                /*,ISNULL( Cost_AL / POWER( Rqf, Qac ), 0 ) AS Gas_AL*/
            FROM AvoidedCostGasvw
            WHERE Qac BETWEEN Qm + CONVERT( INT, eulq1 ) + 1 AND Qm + CONVERT( INT, eulq2 ) - 1

            --- Last Fractional Quarter, Second Baseline -----------------------
            UNION SELECT
                CET_ID
                ,( eulq2 - FLOOR( eulq2 ) ) * ( Cost / POWER( Rqf, Qac ) ) AS Gas
                /*,( eulq2 - FLOOR( eulq2 ) ) * ( Cost_AL / POWER( Rqf, Qac ) ) AS Gas_AL*/
            FROM AvoidedCostGasvw
            WHERE Qac = Qm + CONVERT( INT, eulq2 )
        ) AS A GROUP BY CET_ID
    ) AS acg_2 ON e.CET_ID = acg_2.CET_ID
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
    UPDATE #OutputCE SET
        ElecBen = ISNULL( ElecBen, 0 ),
        GasBen = ISNULL( GasBen, 0 ),
        WaterEnergyBen = ISNULL( WaterEnergyBen, 0 ),
        ElecBenGross = ISNULL( ElecBenGross, 0 ),
        GasBenGross = ISNULL( GasBenGross, 0 ),
        WaterEnergyBenGross = ISNULL( WaterEnergyBenGross, 0 ),
        ElecSupplyCost = ISNULL( ElecSupplyCost, 0 ),
        GasSupplyCost = ISNULL( GasSupplyCost, 0 ),
        WaterEnergyCost = ISNULL( WaterEnergyCost, 0 ),
        ElecSupplyCostGross = ISNULL( ElecSupplyCostGross, 0 ),
        GasSupplyCostGross = ISNULL( GasSupplyCost, 0 ),
        WaterEnergyCostGross = ISNULL( WaterEnergyCostGross, 0 )
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
    ExcessIncPV,
    RebatesPV,
    IncentsAndDIPV,
    GrossMeasCostPV,
    MeasureIncCost
) AS (
    SELECT
        PrgID,
        e.CET_ID,
        SUM(
            (
                Qty *
                CASE
                    WHEN e.MeasImpactType LIKE '%FuelSub' OR e.MeasImpactType LIKE '%NC-AE' OR e.Channel = 'C&S' OR (e.IncentiveToOthers + e.DILaborCost + e.DIMaterialCost - e.UnitMeasureGrossCost > 0)
                    THEN e.IncentiveToOthers + e.DILaborCost + e.DIMaterialCost - e.UnitMeasureGrossCost 
                    ELSE 0
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
    GROUP BY PrgID, e.CET_ID
    )
, BenefitsSum (
    PrgID
    ,SumElecBen
    ,SumGasBen
    ,SumOtherBen
    ,SumElecBenGross
    ,SumGasBenGross
    ,SumOtherBenGross
    ,SumWaterEnergyBen
    ,SumWaterEnergyBenGross
)
AS (
    SELECT
        PrgID
        ,SUM( CASE WHEN ISNULL(ElecBen,0) > 0 THEN ElecBen ELSE 0 END ) AS SumElecBen
        ,SUM( CASE WHEN ISNULL(GasBen,0) > 0 THEN GasBen ELSE 0 END ) AS SumGasBen
        ,SUM( CASE WHEN ISNULL(OtherBen,0) > 0 THEN OtherBen ELSE 0 END ) AS SumOtherBen
        ,SUM( CASE WHEN ISNULL(ElecBenGross,0) > 0 THEN ElecBenGross ELSE 0 END ) AS SumElecBenGross
        ,SUM( CASE WHEN ISNULL(GasBenGross,0) > 0 THEN GasBenGross ELSE 0 END ) AS SumGasBenGross
        ,SUM( CASE WHEN ISNULL(OtherBenGross,0) > 0 THEN OtherBenGross ELSE 0 END ) AS SumOtherBenGross
        ,SUM( CASE WHEN ISNULL(WaterEnergyBen,0) > 0 THEN WaterEnergyBen ELSE 0 END ) AS SumWaterEnergyBen
        ,SUM( CASE WHEN ISNULL(WaterEnergyBenGross,0) > 0 THEN WaterEnergyBenGross ELSE 0 END ) AS SumWaterEnergyBenGross
    FROM #OutputCE
    GROUP BY PrgID
)
, BenPos (
    CET_ID
    ,ElecBenPos
    ,GasBenPos
    ,WaterEnergyBenPos
    ,OtherBenPos
    ,SumBenPos
)
AS
(
    SELECT
        CET_ID
        ,CASE WHEN ISNULL(ElecBen,0) > 0 THEN ElecBen ELSE 0 END AS ElecBenPos
        ,CASE WHEN ISNULL(GasBen,0) > 0 THEN GasBen ELSE 0 END AS GasBenPos
        ,CASE WHEN ISNULL(WaterEnergyBen,0) > 0 THEN WaterEnergyBen ELSE 0 END AS WaterEnergyBenPos
        ,CASE WHEN ISNULL(OtherBen,0) > 0 THEN OtherBen ELSE 0 END AS OtherBenPos
        ,CASE WHEN ISNULL(ElecBen,0) > 0 THEN ElecBen ELSE 0 END +
          CASE WHEN ISNULL(GasBen,0) > 0 THEN GasBen ELSE 0 END +
          CASE WHEN ISNULL(WaterEnergyBen,0) > 0 THEN WaterEnergyBen ELSE 0 END +
          CASE WHEN ISNULL(OtherBen,0) > 0 THEN OtherBen ELSE 0 END
          AS SumBenPos
    FROM #OutputCE ce 
)
, ClaimCount (
      PrgID
    , ClaimCount
)
AS (
    SELECT PrgID
        ,COUNT(CET_ID) As ClaimCount
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
        ,CASE
            WHEN ri.IncentsAndDIPV - ri.GrossMeasCostPV > 0
            THEN ri.IncentsAndDIPV - ri.GrossMeasCostPV
            ELSE 0
        END AS ExcessIncentivesPV
    FROM #OutputCE  ce
    LEFT JOIN RebatesAndIncentives AS ri on CE.CET_ID = ri.CET_ID
    LEFT JOIN (SELECT CET_ID, MeasImpactType, Channel FROM InputMeasurevw) AS e ON CE.CET_ID = e.CET_ID
)
,GrossMeasureCostAdjusted (
    CET_ID
    ,GrossMeasureCostAdjustedPV
    ,MarkEffectPlusExcessIncPV
)
AS
(
    SELECT CE.CET_ID
        ,ri.GrossMeasCostPV -  (ri.IncentsAndDIPV + ri.RebatesPV) + (ex.ExcessIncentivesPV) AS GrossMeasureCostAdjustedPV
        ,@MECost * ((ri.GrossMeasCostPV) + (ex.ExcessIncentivesPV)) AS MarkEffectPlusExcessIncPV
    FROM #OutputCE  ce
    LEFT JOIN RebatesAndIncentives AS ri ON CE.CET_ID = ri.CET_ID
    LEFT JOIN InputMeasurevw AS e ON CE.CET_ID = e.CET_ID
    LEFT JOIN ExcessIncentives AS ex ON ce.CET_ID = ex.CET_ID
)
, ParticipantCost (
    CET_ID
    ,ExcessIncentives
    ,GrossMeasureCostAdjusted
    ,ParticipantCost
    ,ParticipantCostPV
    ,GrossParticipantCostPV
    ,NetParticipantCostPV
)
AS
(
    SELECT CE.CET_ID
        ,ex.ExcessIncentivesPV AS ExcessIncentives
        ,ri.GrossMeasCostPV - (ri.IncentsAndDIPV + ri.RebatesPV) + (ex.ExcessIncentivesPV) AS GrossMeasureCostAdjusted
        ,e.NTGRCost * (gma.GrossMeasureCostAdjustedPV) + (@MECost * (ri.GrossMeasCostPV + ex.ExcessIncentivesPV)) AS ParticipantCost
        ,(e.NTGRCost * (gma.GrossMeasureCostAdjustedPV) + (@MECost * (ri.GrossMeasCostPV + ex.ExcessIncentivesPV))) / POWER(s.Rqf, Qm) AS ParticipantCostPV
        ,ri.GrossMeasCostPV - (ri.IncentsAndDIPV + ri.RebatesPV) + ex.ExcessIncentivesPV AS GrossParticipantCostAdjustedPV
        ,e.NTGRCost * (ri.GrossMeasCostPV - (ri.IncentsAndDIPV + ri.RebatesPV)+ ex.ExcessIncentivesPV) + MarkEffectPlusExcessIncPV AS NetParticipantCostAdjustedPV
    FROM #OutputCE AS ce
    LEFT JOIN RebatesAndIncentives ri on ce.CET_ID = ri.CET_ID
    LEFT JOIN ExcessIncentives ex on ri.CET_ID = ex.CET_ID
    LEFT JOIN InputMeasurevw e ON ce.CET_ID = e.CET_ID
    LEFT JOIN GrossMeasureCostAdjusted gma on ce.CET_ID = gma.CET_ID
    LEFT JOIN Settingsvw s ON e.PA = s.PA
    WHERE s.[Version] = @AVCVersion
)
, Calculations (
    CET_ID
    ,TotalSystemBenefit
    ,TotalSystemBenefitGross
    ,PAC_Cost
    ,PAC_Cost_NoAdmin
    ,TRC_Cost
    ,TRC_CostGross
    ,TRC_Cost_NoAdmin
    ,WeightedBenefits
    ,WeightedElecAlloc
    ,WeightedProgramCost
    ,ExcessIncentives
    ,GrossMeasureCostAdjusted
    ,ParticipantCost
    ,ParticipantCostPV
    ,GrossParticipantCostPV
    ,NetParticipantCostPV
)
AS
(
    SELECT
        CE.CET_ID
        ,(
            ElecBen +
            GasBen +
            WaterEnergyBen +
            Qty * (NTGRkWh + @MEBens) * (
                ISNULL(UnitGasInfraBens,0) +
                ISNULL(UnitRefrigBens,0)
            )
        ) - (
            ElecSupplyCost +
            GasSupplyCost +
            WaterEnergyCost +
            Qty * (NTGRkWh + @MECost) * ISNULL(UnitRefrigCosts,0)
        ) AS TotalSystemBenefit
        ,(
            ElecBenGross +
            GasBenGross +
            WaterEnergyBenGross +
            Qty * (
                ISNULL(UnitGasInfraBens,0) +
                ISNULL(UnitRefrigBens,0)
            )
        ) - (
            ElecSupplyCostGross +
            GasSupplyCostGross +
            WaterEnergyCostGross +
            Qty * ISNULL(UnitRefrigCosts,0)
        ) AS TotalSystemBenefitGross
        ,(
            CASE
                WHEN (SumElecBen + SumGasBen + WaterEnergyBen + OtherBen <> 0)
                THEN
                    (
                        CASE
                            WHEN ISNULL(ElecBen,0) > 0
                            THEN ElecBen
                            ELSE 0
                        END +
                        CASE
                            WHEN ISNULL(GasBen,0) > 0
                            THEN GasBen
                            ELSE 0
                        END +
                        CASE
                            WHEN ISNULL(WaterEnergyBen,0) > 0
                            THEN WaterEnergyBen
                            ELSE 0
                        END +
                        CASE
                            WHEN ISNULL(OtherBen,0) > 0
                            THEN OtherBen
                            ELSE 0
                        END
                    ) / ( SumElecBen + SumGasBen + SumWaterEnergyBen + SumOtherBen )
                ELSE
                    -- If no benefits then divide program costs evenly among claims
                    1.000 / cc.ClaimCount
            END * 
            ISNULL(pcSum.SumCostsNPV,0) +
            Qty *
            (
                IncentiveToOthers +
                DILaborCost +
                DIMaterialCost +
                EndUserRebate
            ) / POWER(s.Rqf, Qm) +
            -- Increased supply costs, refrigerant costs, and miscellaneous costs
           CE.ElecSupplyCost +
           CE.GasSupplyCost +
           CE.WaterEnergyCost +
           CE.OtherCost
        ) AS PAC_Cost
        ,(
            Qty *
            (
                IncentiveToOthers +
                DILaborCost +
                DIMaterialCost +
                EndUserRebate
            ) / POWER(s.Rqf, Qm) +
            -- Increased supply costs, refrigerant costs, and miscellaneous costs
            CE.ElecSupplyCost +
            CE.GasSupplyCost +
            CE.WaterEnergyCost +
            CE.OtherCost
        ) AS PAC_Cost_NoAdmin
        ,(
            CASE 
                WHEN (BensSum.SumElecBen + BensSum.SumGasBen + BensSum.SumWaterEnergyBen + BensSum.SumOtherBen) <> 0
                THEN
                    (
                       CASE 
                           WHEN ISNULL(CE.ElecBen,0) > 0
                           THEN CE.ElecBen
                           ELSE 0
                       END +
                       CASE 
                           WHEN ISNULL(CE.GasBen,0) > 0
                           THEN CE.GasBen
                           ELSE 0
                        END +
                       CASE 
                           WHEN ISNULL(CE.WaterEnergyBen,0) > 0
                           THEN CE.WaterEnergyBen
                           ELSE 0
                        END +
                        CASE
                            WHEN ISNULL(CE.OtherBen,0) > 0
                            THEN OtherBen
                            ELSE 0
                        END
                    ) / (BensSum.SumElecBen + BensSum.SumGasBen + BensSum.SumWaterEnergyBen + BensSum.SumOtherBen)
                ELSE
                    -- If no benefits then divide program costs evenly among claims
                    1.000 / cc.ClaimCount
            END *
            ISNULL(pcSum.SumCostsNPV,0) +
            Qty *
            (
                IncentiveToOthers +
                DILaborCost +
                DIMaterialCost +
                EndUserRebate
            ) / POWER(s.Rqf, Qm) +
            pc.NetParticipantCostPV +
            -- Increased supply costs, refrigerant costs, and miscellaneous costs
            CE.ElecSupplyCost +
            CE.GasSupplyCost +
            CE.WaterEnergyCost +
            CE.OtherCost
        ) AS TRC_Cost
        ,(
            CASE 
                WHEN (SumElecBenGross + SumGasBenGross + SumWaterEnergyBenGross + SumOtherBenGross) <> 0
                THEN
                    (
                        CASE
                            WHEN ISNULL(ElecBenGross,0) > 0
                            THEN ElecBenGross
                            ELSE 0
                        END +
                        CASE
                            WHEN ISNULL(GasBenGross,0) > 0
                            THEN GasBenGross
                            ELSE 0
                        END + 
                        CASE
                            WHEN ISNULL(WaterEnergyBenGross,0) > 0
                            THEN WaterEnergyBenGross
                            ELSE 0
                        END + 
                        CASE
                            WHEN ISNULL(OtherBenGross,0) > 0
                            THEN OtherBenGross
                            ELSE 0
                        END
                    ) / (SumElecBenGross + SumGasBenGross + SumWaterEnergyBenGross + SumOtherBenGross)
                ELSE
                    -- If no benefits then divide program costs evenly among claims
                    1.000 / cc.ClaimCount
            END * 
            ISNULL(pcSum.SumCostsNPV,0) +
            Qty *
            (
                IncentiveToOthers +
                DILaborCost +
                DIMaterialCost +
                EndUserRebate
            ) / POWER(s.Rqf, Qm) +
            pc.GrossParticipantCostPV +
            -- Increased supply costs, refrigerant costs, and miscellaneous costs
            CE.ElecSupplyCost +
            CE.GasSupplyCost +
            CE.WaterEnergyCost +
            CE.OtherCostGross
        ) AS TRC_CostGross
,(
    Qty *
    (
        IncentiveToOthers +
        DILaborCost +
        DIMaterialCost +
        EndUserRebate
    ) / POWER(s.Rqf, Qm) +
    pc.NetParticipantCostPV +
    -- Increased supply costs, refrigerant costs, and miscellaneous costs
    CE.ElecSupplyCost +
    CE.GasSupplyCost +
    CE.WaterEnergyCost +
    CE.OtherCost
) AS TRC_Cost_NoAdmin
        ,CASE
            WHEN (SumElecBen + SumGasBen + SumWaterEnergyBen + SumOtherBen) <> 0
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
                END +
                CASE
                    WHEN ISNULL(WaterEnergyBen,0) > 0
                    THEN WaterEnergyBen
                    ELSE 0
                END +
                CASE
                    WHEN ISNULL(OtherBen,0) > 0
                    THEN OtherBen
                    ELSE 0
                END
            ) / (SumElecBen + SumGasBen + SumWaterEnergyBen + SumOtherBen)
            ELSE 
                1.000 / cc.ClaimCount -- If no benefits then divide program costs evenly among claims
        END AS WeightedBenefits
        ,(
            CASE
                WHEN SumBenPos <> 0
                THEN ElecBenPos / SumBenPos
                ELSE 0
            END
        ) AS WeightedElectricAlloc
        ,(
            CASE 
                WHEN SumElecBen + SumGasBen + SumWaterEnergyBen + SumOtherBen <> 0
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
                    END +
                    CASE
                        WHEN ISNULL(WaterEnergyBen,0) > 0
                        THEN WaterEnergyBen
                        ELSE 0
                    END +
                    CASE
                        WHEN ISNULL(OtherBen,0) > 0
                        THEN OtherBen
                        ELSE 0
                    END
                    ) / (SumElecBen + SumGasBen + SumWaterEnergyBen + SumOtherBen)
                ELSE 1.000 / cc.ClaimCount -- If no benefits then divide program costs evenly among claims
            END * 
            ISNULL(pcSum.SumCosts,0)
        ) AS WeightedProgramCost
        ,pc.ExcessIncentives
        ,pc.GrossMeasureCostAdjusted
        ,pc.ParticipantCost
        ,pc.ParticipantCostPV
        ,pc.GrossParticipantCostPV
        ,pc.NetParticipantCostPV
    FROM #OutputCE CE
    LEFT JOIN InputMeasurevw AS e ON CE.CET_ID = e.CET_ID
    LEFT JOIN ProgramCostsSum pcSum ON CE.PrgID = pcSum.PrgID
    LEFT JOIN RebatesAndIncentives ri on CE.CET_ID = ri.CET_ID
    LEFT JOIN ParticipantCost pc on ce.CET_ID = pc.CET_ID
    LEFT JOIN BenefitsSum bensSum ON CE.PrgID = bensSum.PrgID
    LEFT JOIN BenPos bp on ce.CET_ID = bp.CET_ID
    LEFT JOIN ClaimCount cc on CE.PrgID = cc.PrgID
    LEFT JOIN Settingsvw s ON e.PA = s.PA
    WHERE s.[Version] = @AVCVersion
)
    UPDATE #OutputCE 
    SET 
        TotalSystemBenefit = c.TotalSystemBenefit
        , TotalSystemBenefitGross = c.TotalSystemBenefitGross
        , TRCCost = c.TRC_Cost
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
                ( NTGRkWh + @MEBens ) *
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
                ( NTGRThm + @MEBens ) *
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
        ) AS RIMCostGas
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
            THEN (ElecBen + GasBen + WaterEnergyBen + OtherBen) / (TRCCost)
            ELSE 0
        END
    ,PACRatio =
        CASE 
            WHEN PACCost <> 0
            THEN (ElecBen + GasBen + WaterEnergyBen + OtherBen) / (PACCost)
            ELSE 0
        END
    ,TRCRatioNoAdmin =
        CASE 
            WHEN TRCCostNoAdmin <> 0
            THEN (ElecBen + GasBen + WaterEnergyBen + OtherBen) / (TRCCostNoAdmin)
            ELSE 0
        END
    ,PACRatioNoAdmin =
        CASE 
            WHEN PACCostNoAdmin <> 0
            THEN (ElecBen + GasBen + WaterEnergyBen + OtherBen) / (PACCostNoAdmin)
            ELSE 0
        END
END

--Clear OutputCE
DELETE FROM OutputCE WHERE JobID = @JobID
DELETE FROM SavedCE WHERE JobID = @JobID

--Copy data in temporary table to OutputCE
INSERT INTO OutputCE
SELECT 
    JobID
    ,PA
    ,PrgID
    ,CET_ID
    ,ElecBen
    ,GasBen
    ,WaterEnergyBen
    ,ElecBenGross
    ,GasBenGross
    ,WaterEnergyBenGross
    ,OtherBen
    ,OtherBenGross
    ,ElecSupplyCost
    ,GasSupplyCost
    ,WaterEnergyCost
    ,ElecSupplyCostGross
    ,GasSupplyCostGross
    ,WaterEnergyCostGross
    ,OtherCost
    ,OtherCostGross
    ,TotalSystemBenefit
    ,TotalSystemBenefitGross
    ,TRCCost
    ,PACCost
    ,TRCCostGross
    ,TRCCostNoAdmin
    ,PACCostNoAdmin
    ,TRCRatio
    ,PACRatio
    ,TRCRatioNoAdmin
    ,PACRatioNoAdmin
    ,BillReducElec
    ,BillReducGas
    ,RIMCost
    ,WeightedBenefits
    ,WeightedElecAlloc
    ,WeightedProgramCost
FROM [#OutputCE]
ORDER BY JobID, CET_ID ASC

DROP TABLE [#OutputCE]

--PRINT 'Done!'

GO