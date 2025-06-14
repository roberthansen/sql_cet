/*
################################################################################
Name            :  CalcCE (procedure)
Date            :  2016-06-30
Author          :  Wayne Hauck
Company         :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose         :  This stored procedure calculates cost effectiveness.
Usage           :  n/a
Called by       :  n/a
Copyright       :  Developed by Pinnacle Consulting Group (aka Intech Energy,
                :  Inc.) for California Public Utilities Commission (CPUC), All
                :  Rights Reserved
Change History  :  2016-06-30  Wayne Hauck added comment header
                :  2016-12-30  Wayne Hauck added measure inflation
                :  2016-12-30  Added modified Elec and Gas benefits to use
                :              savings-specific installation rate (IR) and
                :              realization rate (RR)
                :  2020-02-11  Robert Hansen reformatted for readability and
                :              added comments to identify possible errors
                :  2020-07-23  Robert Hansen applied logic to remove negative
                :              benefits to measure costs
                :              Added four fields to #OutputCE table variable:
                :                + ElecNegBen
                :                + GasNegBen
                :                + ElecNegBenGross
                :                + GasNegBenGross
                :              Added ElecNegBen and GasNegBen (and _Gross) to
                :              measure-level cost columns:
                :                + PAC_Cost
                :                + PAC_Cost_NoAdmin
                :                + TRC_Cost
                :                + TRC_CostGross
                :                + TRC_Cost_NoAdmin
                :  2020-08-03  Robert Hansen added switch to negative benefits
                :              logic to apply only to measures marked with
                :              'FuelSub' in the MeasImpactType field of the
                :              InputMeasure table
                :  2020-11-03  Robert Hansen removed JobID from join between
                :              InputMeasurevw and InputMeasureCEDARS, used for
                :              retrieving MeasImpactType
                :  2020-11-19  Robert Hansen fixed error in program-level
                :              summations in the in-memory table "BenefitsSum"
                :              introduced when the threshold logic applied to
                :              each measure which was removed in 2020-07-23 due
                :              to similar logic in ElecBen and GasBen
                :              calculations, but again became necessary when
                :              "FuelSub" tag check was added in 2020-08-03.
                :  2020-12-18  Robert Hansen added ISNULL() wrappers to benefits
                :              fields in WeightedBenefits calculation; replaced
                :              erroneous "OR" with "AND" in ElecBenGross
                :              calculation.
                :  2021-04-26  Robert Hansen implemented second impact profile
                :              for additional load associated with fuel
                :              substitution measures, used to calculate
                :              'negative savings' as new cost.
                :  2021-05-14  Robert Hansen implemented the following corrections
                :              to code errors:
                :                + Removed (1+MEBens) from Gross Benefits
                :                  Calculations
                :                + Applied IRkW and RRkW to Demand Savings where
                :                  missing or where IRkWh and RRkWh are used
                :                  improperly
                :                + Removed Rqf terms from benefits calculations
                :                  as net-present conversions occur in JOIN sub-
                :                  queries
                :                + Moved ISNULL() functions inside SUM()
                :                  aggregators
                :  2021-05-17  Robert Hansen incorporated the following new
                :              benefits and costs fields in test calculations:
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
                :              related to water-energy nexus savings and
                :              included their values in calculating gross and
                :              net savings:
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
                :  2023-04-26  Robert Hansen removed extra comma which was
                :              causing a syntax error when extra fields were
                :              commented out
                :  2024-04-22  Robert Hansen applied the following changes:
                :                + MiscBens and MiscCosts added to OtherBen,
                :                  OtherBenGross, OtherCost, and
                :                  OtherCostGross
                :                + Modified fuel-substitution logic for electric
                :                  and gas net and gross benefits and costs to
                :                  evaluate combined first- and second-baseline
                :                  benefits or costs before evaluating rather
                :                  than checking only first-baseline savings
                :                  rate
                :                + Renamed the "PA" field to "IOU_AC_Territory"
                :  2024-06-20  Robert Hansen reverted the "IOU_AC_Territory" to
                :              "PA"
                :  2024-08-19  Robert Hansen replaced gas infrastructure and
                :              refrigerant benefits and costs with OtherBen and
                :              OtherCost in Total System Benefit calculations
                :  2024-08-20  J Scheuerell fixed errors in script
                :  2025-02-11  Robert Hansen implemented the Societal Cost Test:
                :                + Loaded new fields from the Avoided Cost
                :                  Electric table: Gen_SB, Gen_SH, TD_SB, TD_SH
                :                + Created new calculations and outputs for
                :                  Societal Costs and Benefits: 
                :                    - ElecBen_SB
                :                    - ElecBen_SH
                :                    - ElecBenGross_SB
                :                    - ElecBenGross_SH
                :                    - ElecSupplyCost_SB
                :                    - ElecSupplyCost_SH
                :                    - ElecSupplyCostGross_SB
                :                    - ElecSupplyCostGross_SH
                :                    - SCBCost
                :                    - SCHCost
                :                    - SCBCostGross
                :                    - SCBCostNoAdmin
                :                    - SCHCost
                :                    - SCHCostGross
                :                    - SCHCostNoAdmin
                :                    - SCBRatio
                :                    - SCHRatio
                :                    - SCBRatioNoAdmin
                :                    - SCHRatioNoAdmin
                :  2025-02-18  Robert Hansen added "FuelType" field and updated
                :              logic for fuel substitution accordingly
                :  2025-04-11  Robert Hansen added new UnitTaxCredits field and
                :              included tax credits in TRC tests
                :  2025-04-15  Robert Hansen moved FuelType values to temporary
                :              table variable named
                :              #FuelTypesForFuelSubstitution and updated logic
                :              to use the temporary table variable
                :  2025-04-29  Robert Hansen performed the following
                :              corrections:
                :                + Added SCB and SCH costs to Update
                :                  #OutputCE with values from Calculations
                :                  temporary table, allowing values to propagate
                :                  to OutputCE table properly
                :                + Applied NTGRkWh and MEBens to TaxCredits
                :              Also implemented the following changes:
                :                + Included TaxCredits and TaxCreditsGross in
                :                  OutputCE table
                :                + Calculated RIMCostNoAdmin, RIMRatio, and
                :                  RIMRatioNoAdmin and included values in
                :                  OutputCE
                :                + Reordered fields and calculations for
                :                  consistency
                :  2025-05-15  Incoporporated corrections from Jenn Scheuerell
                :  2025-05-21  Incorporated changes to SCT and RIM test proposed
                :              by Jake Richardson (PG&E):
                :                + Incorporated new societal discount rate from
                :                  E3Settings table
                :                + Applied societal discount rate to SCT terms
                :                + Added SCT fields for gas and water energy:
                :                    - GasBen_SB
                :                    - GasBen_SH
                :                    - GasBenGross_SB
                :                    - GasBenGross_SH
                :                    - WaterEnergyBen_SB
                :                    - WaterEnergyBen_SH
                :                    - GasSupplyCost_SB
                :                    - GasSupplyCost_SH
                :                    - GasSupplyCostGross_SB
                :                    - GasSupplyCostGross_SH
                :                    - WaterEnergyCost_SB
                :                    - WaterEnergyCost_SH
                :                + Applied new gas and water energy SCT fields
                :                  in SCT ratio calculations
                :                + Renamed and added internal calculated fields
                :                  for RIM test, and applied fuel substitution
                :                  logic in calculations:
                :                    - RimCostElec --> BillReducElec
                :                    - BillIncrElec
                :                    - RimCostGas --> BillReducGas
                :                    - BillIncrGas
                :                + Added BillIncrGas and BillIncrElec to
                :                  numerator of RIMRatio
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
CREATE TABLE [#FuelTypesForFuelSubstitution](
    FuelType NVARCHAR(50) NULL
)
CREATE TABLE [#OutputCE](
    JobID INT NULL,
    PA NVARCHAR(24) NULL,
    PrgID NVARCHAR(255) NULL,
    CET_ID NVARCHAR(255) NULL,
    ElecBen FLOAT NULL,
    ElecBen_SB FLOAT NULL,
    ElecBen_SH FLOAT NULL,
    GasBen FLOAT NULL,
    GasBen_SB FLOAT NULL,
    GasBen_SH FLOAT NULL,
    TaxCredits FLOAT NULL,
    WaterEnergyBen FLOAT NULL,
    WaterEnergyBen_SB FLOAT NULL,
    WaterEnergyBen_SH FLOAT NULL,
    OtherBen FLOAT NULL,
    ElecBenGross FLOAT NULL,
    ElecBenGross_SB FLOAT NULL,
    ElecBenGross_SH FLOAT NULL,
    GasBenGross FLOAT NULL,
    GasBenGross_SB FLOAT NULL,
    GasBenGross_SH FLOAT NULL,
    TaxCreditsGross FLOAT NULL,
    WaterEnergyBenGross FLOAT NULL,
    WaterEnergyBenGross_SB FLOAT NULL,
    WaterEnergyBenGross_SH FLOAT NULL,
    OtherBenGross FLOAT NULL,
    ElecSupplyCost FLOAT NULL,
    ElecSupplyCost_SB FLOAT NULL,
    ElecSupplyCost_SH FLOAT NULL,
    GasSupplyCost FLOAT NULL,
    GasSupplyCost_SB FLOAT NULL,
    GasSupplyCost_SH FLOAT NULL,
    WaterEnergyCost FLOAT NULL,
    WaterEnergyCost_SB FLOAT NULL,
    WaterEnergyCost_SH FLOAT NULL,
    OtherCost FLOAT NULL,
    ElecSupplyCostGross FLOAT NULL,
    ElecSupplyCostGross_SB FLOAT NULL,
    ElecSupplyCostGross_SH FLOAT NULL,
    GasSupplyCostGross FLOAT NULL,
    GasSupplyCostGross_SB FLOAT NULL,
    GasSupplyCostGross_SH FLOAT NULL,
    WaterEnergyCostGross FLOAT NULL,
    WaterEnergyCostGross_SB FLOAT NULL,
    WaterEnergyCostGross_SH FLOAT NULL,
    OtherCostGross FLOAT NULL,
    BillReducElec FLOAT NULL,
    BillIncrElec FLOAT NULL,
    BillReducGas FLOAT NULL,
    BillIncrGas FLOAT NULL,
    TotalSystemBenefit FLOAT NULL,
    TotalSystemBenefitGross FLOAT NULL,
    SCBCost FLOAT NULL,
    SCHCost FLOAT NULL,
    TRCCost FLOAT NULL,
    PACCost FLOAT NULL,
    RIMCost FLOAT NULL,
    SCBCostGross FLOAT NULL,
    SCBCostNoAdmin FLOAT NULL,
    SCHCostGross FLOAT NULL,
    SCHCostNoAdmin FLOAT NULL,
    TRCCostGross FLOAT NULL,
    TRCCostNoAdmin FLOAT NULL,
    PACCostNoAdmin FLOAT NULL,
    RIMCostNoAdmin FLOAT NULL,
    SCBRatio FLOAT NULL,
    SCHRatio FLOAT NULL,
    TRCRatio FLOAT NULL,
    PACRatio FLOAT NULL,
    RIMRatio FLOAT NULL,
    SCBRatioNoAdmin FLOAT NULL,
    SCHRatioNoAdmin FLOAT NULL,
    TRCRatioNoAdmin FLOAT NULL,
    PACRatioNoAdmin FLOAT NULL,
    RIMRatioNoAdmin FLOAT NULL,
    WeightedBenefits FLOAT NULL,
    WeightedElecAlloc FLOAT NULL,
    WeightedProgramCost FLOAT NULL
) ON [PRIMARY]

BEGIN
    INSERT INTO #FuelTypesForFuelSubstitution VALUES
        ('AllElec-New'),
        ('FuelSub-ToElec'),
        ('FuelSub-ToGas-Ex')
PRINT 'Inserting electrical and gas benefits... Message 3'
    -- Insert into CE with correction for Null gas and elec
    INSERT INTO #OutputCE (
        JobID
        ,PA
        ,PrgID
        ,CET_ID
        ,ElecBen
        ,ElecBen_SB
        ,ElecBen_SH
        ,GasBen
        ,GasBen_SB
        ,GasBen_SH
        ,TaxCredits
        ,WaterEnergyBen
        ,WaterEnergyBen_SB
        ,WaterEnergyBen_SH
        ,OtherBen
        ,ElecBenGross
        ,ElecBenGross_SB
        ,ElecBenGross_SH
        ,GasBenGross
        ,GasBenGross_SB
        ,GasBenGross_SH
        ,TaxCreditsGross
        ,WaterEnergyBenGross
        ,WaterEnergyBenGross_SB
        ,WaterEnergyBenGross_SH
        ,OtherBenGross
        ,ElecSupplyCost
        ,ElecSupplyCost_SB
        ,ElecSupplyCost_SH
        ,GasSupplyCost
        ,GasSupplyCost_SB
        ,GasSupplyCost_SH
        ,WaterEnergyCost
        ,WaterEnergyCost_SB
        ,WaterEnergyCost_SH
        ,OtherCost
        ,ElecSupplyCostGross
        ,ElecSupplyCostGross_SB
        ,ElecSupplyCostGross_SH
        ,GasSupplyCostGross
        ,GasSupplyCostGross_SB
        ,GasSupplyCostGross_SH
        ,WaterEnergyCostGross
        ,WaterEnergyCostGross_SB
        ,WaterEnergyCostGross_SH
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
                WHEN ISNULL(ft.FuelType,0) = '0'
                    OR (e.kWh1 * ace_1.Gen + e.kWh2 * ISNULL(ace_2.Gen,0)) > 0
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
--- ElecBen_SB (Net Lifecycle, Societal Cost Base) -----------------------------
        ,SUM(
            CASE
                WHEN ISNULL(ft.FuelType,0) = '0'
                    OR (e.kWh1 * ace_1.Gen_SB + e.kWh2 * ISNULL(ace_2.Gen_SB,0)) > 0
                THEN
                    ISNULL(
                        e.Qty *
                        (
                            ( e.NTGRkWh + @MEBens ) *
                            e.IRkWh *
                            e.RRkWh *
                            (
                                e.kWh1 * ace_1.Gen_SB +
                                e.kWh2 * ace_2.Gen_SB
                            )
                            +
                            ( e.NTGRkW + @MEBens ) *
                            e.IRkW *
                            e.RRkW *
                            (
                                ace_1.DS * ace_1.TD_SB +
                                ISNULL( ace_2.DS, 0 ) * ISNULL( ace_2.TD_SB, 0 )
                            )
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS ElecBen_SB
--------------------------------------------------------------------------------
--- ElecBen_SH (Net Lifecycle, Societal Cost High) -----------------------------
        ,SUM(
            CASE
                WHEN ISNULL(ft.FuelType,0) = '0'
                    OR (e.kWh1 * ace_1.Gen_SH + e.kWh2 * ISNULL(ace_2.Gen_SH,0)) > 0
                THEN
                    ISNULL(
                        e.Qty *
                        (
                            ( e.NTGRkWh + @MEBens ) *
                            e.IRkWh *
                            e.RRkWh *
                            (
                                e.kWh1 * ace_1.Gen_SH +
                                e.kWh2 * ace_2.Gen_SH
                            )
                            +
                            ( e.NTGRkW + @MEBens ) *
                            e.IRkW *
                            e.RRkW *
                            (
                                ace_1.DS * ace_1.TD_SH +
                                ISNULL( ace_2.DS, 0 ) * ISNULL( ace_2.TD_SH, 0 )
                            )
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS ElecBen_SH
--------------------------------------------------------------------------------
--- GasBen (Net Lifecycle) -----------------------------------------------------
--- NetPVBenTOT[G]: Present value of net gas benefits
        ,SUM(
            CASE 
                WHEN ISNULL(ft.FuelType,0) = '0'
                    OR (e.Thm1 * acg_1.Gas + e.Thm2 * ISNULL(acg_2.Gas,0)) > 0
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
--- GasBen_SB (Net Lifecycle) --------------------------------------------------
        ,SUM(
            CASE 
                WHEN ISNULL(ft.FuelType,0) = '0'
                    OR (e.Thm1 * acg_1.Gas_SB + e.Thm2 * ISNULL(acg_2.Gas_SB,0)) > 0
                THEN
                    ISNULL(
                        e.Qty *
                        ( e.NTGRThm + @MEBens ) *
                        e.IRThm *
                        e.RRThm *
                        (
                            e.Thm1 * acg_1.Gas_SB +
                            e.Thm2 * ISNULL( acg_2.Gas_SB, 0 )
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS GasBen_SB
--------------------------------------------------------------------------------
--- GasBen_SH (Net Lifecycle) --------------------------------------------------
        ,SUM(
            CASE 
                WHEN ISNULL(ft.FuelType,0) = '0'
                    OR (e.Thm1 * acg_1.Gas_SH + e.Thm2 * ISNULL(acg_2.Gas_SH,0)) > 0
                THEN
                    ISNULL(
                        e.Qty *
                        ( e.NTGRThm + @MEBens ) *
                        e.IRThm *
                        e.RRThm *
                        (
                            e.Thm1 * acg_1.Gas_SH +
                            e.Thm2 * ISNULL( acg_2.Gas_SH, 0 )
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS GasBen_SH
--------------------------------------------------------------------------------
--- TaxCredits (Net) -----------------------------------------------------------
        ,SUM(
            e.Qty * (NTGRkWh + @MEBens) * ISNULL( e.UnitTaxCredits, 0 )
        ) AS TaxCredits
--------------------------------------------------------------------------------
--- WaterEnergyBen (Net) -------------------------------------------------------
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
--- WaterEnergyBen_SB (Net) ----------------------------------------------------
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
                            e.kWhWater1 * ace_1.Gen_SB +
                            e.kWhWater2 * ace_2.Gen_SB
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS WaterEnergyBen_SB
--------------------------------------------------------------------------------
--- WaterEnergyBen_SH (Net) ----------------------------------------------------
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
                            e.kWhWater1 * ace_1.Gen_SH +
                            e.kWhWater2 * ace_2.Gen_SH
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS WaterEnergyBen_SH
--------------------------------------------------------------------------------
--- OtherBen (Net) -------------------------------------------------------------
        ,SUM(
            e.Qty *
            (NTGRkWh + @MEBens) *
            (
                ISNULL( UnitGasInfraBens, 0 ) +
                ISNULL( UnitRefrigBens, 0 ) +
                ISNULL( UnitMiscBens, 0)
            )
        ) AS OtherBen
--------------------------------------------------------------------------------
--- ElecBenGross (Lifecycle) ---------------------------------------------------
--- PVBen[E]: Present value gross electricity benefits
        ,SUM(
            CASE
                WHEN ISNULL(ft.FuelType,0) = '0'
                    OR (e.kWh1 * ace_1.Gen + e.kWh2 * ISNULL(ace_2.Gen,0)) > 0
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
--- ElecBenGross_SB (Lifecycle, Societal Cost Base) ----------------------------
        ,SUM(
            CASE
                WHEN ISNULL(ft.FuelType,0) = '0'
                    OR (e.kWh1 * ace_1.Gen_SB + e.kWh2 * ISNULL(ace_2.Gen_SB,0)) > 0
                THEN
                    ISNULL(
                        e.Qty *
                        (
                            e.IRkWh *
                            e.RRkWh *
                            (
                                e.kWh1 * ace_1.Gen_SB +
                                e.kWh2 * ISNULL( ace_2.Gen_SB, 0 )
                            )
                            +
                            e.IRkW *
                            e.RRkW *
                            (
                                ace_1.DS * ace_1.TD_SB
                                +
                                ISNULL( ace_2.DS, 0 ) * ISNULL( ace_2.TD_SB, 0 )
                            )
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS ElecBenGross_SB
--------------------------------------------------------------------------------
--- ElecBenGross_SH (Lifecycle, Societal Cost High) ----------------------------
        ,SUM(
            CASE
                WHEN ISNULL(ft.FuelType,0) = '0'
                    OR (e.kWh1 * ace_1.Gen_SH + e.kWh2 * ISNULL(ace_2.Gen_SH,0)) > 0
                THEN
                    ISNULL(
                        e.Qty *
                        (
                            e.IRkWh *
                            e.RRkWh *
                            (
                                e.kWh1 * ace_1.Gen_SH +
                                e.kWh2 * ISNULL( ace_2.Gen_SH, 0 )
                            )
                            +
                            e.IRkW *
                            e.RRkW *
                            (
                                ace_1.DS * ace_1.TD_SH
                                +
                                ISNULL( ace_2.DS, 0 ) * ISNULL( ace_2.TD_SH, 0 )
                            )
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS ElecBenGross_SH
--------------------------------------------------------------------------------
--- GasBenGross (Lifecycle) ----------------------------------------------------
--- PVBen[G]: Present value gross gas benefits
        ,SUM(
            CASE
                WHEN ISNULL(ft.FuelType,0) = '0'
                    OR (e.Thm1 * acg_1.Gas + e.Thm2 * ISNULL(acg_2.Gas,0)) > 0
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
--- GasBenGross_SB (Lifecycle) -------------------------------------------------
        ,SUM(
            CASE
                WHEN ISNULL(ft.FuelType,0) = '0'
                    OR (e.Thm1 * acg_1.Gas_SB + e.Thm2 * ISNULL(acg_2.Gas_SB,0)) > 0
                THEN
                    ISNULL(
                        e.Qty *
                        e.IRThm *
                        e.RRThm *
                        (
                            e.Thm1 * acg_1.Gas_SB +
                            e.Thm2 * ISNULL( acg_2.Gas_SB, 0 )
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS GasBenGross_SB
--------------------------------------------------------------------------------
--- GasBenGross_SH (Lifecycle) -------------------------------------------------
        ,SUM(
            CASE
                WHEN ISNULL(ft.FuelType,0) = '0'
                    OR (e.Thm1 * acg_1.Gas_SH + e.Thm2 * ISNULL(acg_2.Gas_SH,0)) > 0
                THEN
                    ISNULL(
                        e.Qty *
                        e.IRThm *
                        e.RRThm *
                        (
                            e.Thm1 * acg_1.Gas_SH +
                            e.Thm2 * ISNULL( acg_2.Gas_SH, 0 )
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS GasBenGross_SH
--------------------------------------------------------------------------------
--- Tax CreditsGross -----------------------------------------------------------
        ,SUM(
            e.Qty * ISNULL( e.UnitTaxCredits, 0 )
        ) AS TaxCreditsGross
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
--- WaterEnergyBenGross_SB -----------------------------------------------------
        ,SUM(
            CASE
                WHEN e.kWhWater1>0
                THEN
                    ISNULL(
                        e.Qty *
                        e.IRkWh *
                        e.RRkWh *
                        (
                            e.kWhWater1 * ace_1.Gen_SB +
                            e.kWhWater2 * ace_2.Gen_SB
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS WaterEnergyBenGross_SB
--------------------------------------------------------------------------------
--- WaterEnergyBenGross_SH -----------------------------------------------------
        ,SUM(
            CASE
                WHEN e.kWhWater1>0
                THEN
                    ISNULL(
                        e.Qty *
                        e.IRkWh *
                        e.RRkWh *
                        (
                            e.kWhWater1 * ace_1.Gen_SH +
                            e.kWhWater2 * ace_2.Gen_SH
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS WaterEnergyBenGross_SH
--------------------------------------------------------------------------------
--- OtherBenGross -------------------------------------------------------------------
        ,SUM(
            e.Qty *
            (
                ISNULL( UnitGasInfraBens, 0 ) +
                ISNULL( UnitRefrigBens, 0 ) +
                ISNULL( UnitMiscBens, 0)
            )
        ) AS OtherBenGross
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--- ADDED THE FOLLOWING 8 FIELDS TO PROVIDE NEGATIVE BENEFITS TO TRC AND PAC ---
--- ElecSupplyCost (Net Lifecycle) ---------------------------------------------
        ,SUM(
            CASE
                WHEN NOT ISNULL(ft.FuelType,0) = '0'
                    AND (e.kWh1 * ace_1.Gen + e.kWh2 * ISNULL(ace_2.Gen,0))<0
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
--- ElecSupplyCost_SB (Net Lifecycle, Societal Cost Base) ----------------------
        ,SUM(
            CASE
                WHEN NOT ISNULL(ft.FuelType,0) = '0'
                    AND (e.kWh1 * ace_1.Gen_SB + e.kWh2 * ISNULL(ace_2.Gen_SB,0)) < 0
                THEN
                    ISNULL(
                        -e.Qty *
                        (
                            ( e.NTGRkWh + @MEBens ) *
                            e.IRkWh *
                            e.RRkWh *
                            (
                                e.kWh1 * ace_1.Gen_SB +
                                e.kWh2 * ISNULL( ace_2.Gen_SB, 0 )
                            )
                            +
                            ( e.NTGRkw + @MEBens ) *
                            e.IRkW *
                            e.RRkW *
                            (
                                ace_1.DS * ace_1.TD_SB +
                                ace_2.DS * ISNULL( ace_2.TD_SB, 0 )
                            )
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS ElecSupplyCost_SB
--------------------------------------------------------------------------------
--- ElecSupplyCost_SH (Net Lifecycle, Societal Cost High) ----------------------
        ,SUM(
            CASE
                WHEN NOT ISNULL(ft.FuelType,0) = '0'
                    AND (e.kWh1 * ace_1.Gen_SH + e.kWh2 * ISNULL(ace_2.Gen_SH,0)) < 0
                THEN
                    ISNULL(
                        -e.Qty *
                        (
                            ( e.NTGRkWh + @MEBens ) *
                            e.IRkWh *
                            e.RRkWh *
                            (
                                e.kWh1 * ace_1.Gen_SH +
                                e.kWh2 * ISNULL( ace_2.Gen_SH, 0 )
                            )
                            +
                            ( e.NTGRkw + @MEBens ) *
                            e.IRkW *
                            e.RRkW *
                            (
                                ace_1.DS * ace_1.TD_SH +
                                ace_2.DS * ISNULL( ace_2.TD_SH, 0 )
                            )
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS ElecSupplyCost_SH
--------------------------------------------------------------------------------
--- GasSupplyCost (Net Lifecycle) ----------------------------------------------
        ,SUM(
            CASE
                WHEN NOT ISNULL(ft.FuelType,0) = '0'
                    AND (e.Thm1 * acg_1.Gas + e.Thm2 * ISNULL(acg_2.Gas,0)) < 0
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
--- GasSupplyCost_SB (Net Lifecycle) -------------------------------------------
        ,SUM(
            CASE
                WHEN NOT ISNULL(ft.FuelType,0) = '0'
                    AND (e.Thm1 * acg_1.Gas_SB + e.Thm2 * ISNULL(acg_2.Gas_SB,0)) < 0
                THEN
                    ISNULL(
                        -e.Qty *
                        ( e.NTGRThm + @MEBens ) *
                        e.IRThm *
                        e.RRThm *
                        (
                            e.Thm1 * acg_1.Gas_SB +
                            e.Thm2 * ISNULL( acg_2.Gas_SB, 0 )
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS GasSupplyCost_SB
--------------------------------------------------------------------------------
--- GasSupplyCost_SH (Net Lifecycle) -------------------------------------------
        ,SUM(
            CASE
                WHEN NOT ISNULL(ft.FuelType,0) = '0'
                    AND (e.Thm1 * acg_1.Gas_SH + e.Thm2 * ISNULL(acg_2.Gas_SH,0)) < 0
                THEN
                    ISNULL(
                        -e.Qty *
                        ( e.NTGRThm + @MEBens ) *
                        e.IRThm *
                        e.RRThm *
                        (
                            e.Thm1 * acg_1.Gas_SH +
                            e.Thm2 * ISNULL( acg_2.Gas_SH, 0 )
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS GasSupplyCost_SH
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
--- WaterEnergyCost_SB ---------------------------------------------------------
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
                            e.kWhWater1 * ace_1.Gen_SB +
                            e.kWhWater2 * ace_2.Gen_SB
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS WaterEnergyCost_SB
--------------------------------------------------------------------------------
--- WaterEnergyCost_SH ---------------------------------------------------------
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
                            e.kWhWater1 * ace_1.Gen_SH +
                            e.kWhWater2 * ace_2.Gen_SH
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS WaterEnergyCost_SH
--------------------------------------------------------------------------------
--- OtherCost (Net) ------------------------------------------------------------
        ,SUM(
            e.Qty *
            (e.NTGRkWh + @MECost) *
            (
                ISNULL( e.UnitRefrigCosts, 0 ) +
                ISNULL( e.UnitMiscCosts, 0 )
            )
        ) AS OtherCost
--------------------------------------------------------------------------------
--- ElecSupplyCostGross (Lifecycle) --------------------------------------------
        ,SUM(
            CASE
                WHEN NOT ISNULL(ft.FuelType,0) = '0'
                    AND (e.kWh1 * ace_1.Gen + e.kWh2 * ISNULL(ace_2.Gen,0)) < 0
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
--- ElecSupplyCostGross_SB (Lifecycle, Societal Cost Base) ---------------------
        ,SUM(
            CASE
                WHEN NOT ISNULL(ft.FuelType,0) = '0'
                    AND (e.kWh1 * ace_1.Gen_SB + e.kWh2 * ISNULL(ace_2.Gen_SB,0)) < 0
                THEN
                    ISNULL(
                        -e.Qty *
                        (
                            e.IRkWh *
                            e.RRkWh *
                            (
                                e.kWh1 * ace_1.Gen_SB +
                                e.kWh2 * ISNULL( ace_2.Gen_SB, 0 )
                            )
                            +
                            e.IRkW *
                            e.RRkW *
                            (
                                ace_1.DS * ace_1.TD_SB +
                                ace_2.DS * ISNULL( ace_2.TD_SB, 0 )
                            )
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS ElecSupplyCostGross_SB
--------------------------------------------------------------------------------
--- ElecSupplyCostGross_SH (Lifecycle, Societal Cost High) ---------------------
        ,SUM(
            CASE
                WHEN NOT ISNULL(ft.FuelType,0) = '0'
                    AND (e.kWh1 * ace_1.Gen_SH + e.kWh2 * ISNULL(ace_2.Gen_SH,0)) < 0
                THEN
                    ISNULL(
                        -e.Qty *
                        (
                            e.IRkWh *
                            e.RRkWh *
                            (
                                e.kWh1 * ace_1.Gen_SH +
                                e.kWh2 * ISNULL( ace_2.Gen_SH, 0 )
                            )
                            +
                            e.IRkW *
                            e.RRkW *
                            (
                                ace_1.DS * ace_1.TD_SH +
                                ace_2.DS * ISNULL( ace_2.TD_SH, 0 )
                            )
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS ElecSupplyCostGross_SH
--------------------------------------------------------------------------------
--- GasSupplyCostGross (Lifecycle) ---------------------------------------------
        ,SUM(
            CASE
                WHEN NOT ISNULL(ft.FuelType,0) = '0'
                    AND (e.Thm1 * acg_1.Gas + e.Thm2 * ISNULL(acg_2.Gas,0)) < 0
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
--- GasSupplyCostGross_SB (Lifecycle) ------------------------------------------
        ,SUM(
            CASE
                WHEN NOT ISNULL(ft.FuelType,0) = '0'
                    AND (e.Thm1 * acg_1.Gas_SB + e.Thm2 * ISNULL(acg_2.Gas_SB,0)) < 0
                THEN
                    ISNULL(
                        -e.Qty *
                        e.IRThm *
                        e.RRThm *
                        (
                            e.Thm1 * acg_1.Gas_SB +
                            e.Thm2 * ISNULL( acg_2.Gas_SB, 0 )
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS GasSupplyCostGross_SB
--------------------------------------------------------------------------------
--- GasSupplyCostGross_SH (Lifecycle) ------------------------------------------
        ,SUM(
            CASE
                WHEN NOT ISNULL(ft.FuelType,0) = '0'
                    AND (e.Thm1 * acg_1.Gas_SH + e.Thm2 * ISNULL(acg_2.Gas_SH,0)) < 0
                THEN
                    ISNULL(
                        -e.Qty *
                        e.IRThm *
                        e.RRThm *
                        (
                            e.Thm1 * acg_1.Gas_SH +
                            e.Thm2 * ISNULL( acg_2.Gas_SH, 0 )
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS GasSupplyCostGross_SH
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
--- WaterEnergyCostGross_SB ----------------------------------------------------
        ,SUM(
            CASE
                WHEN e.kWhWater1<0
                THEN
                    ISNULL(
                        -e.Qty *
                        e.IRkWh *
                        e.RRkWh *
                        (
                            e.kWhWater1 * ace_1.Gen_SB +
                            e.kWhWater2 * ace_2.Gen_SB
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS WaterEnergyCostGross_SB
--------------------------------------------------------------------------------
--- WaterEnergyCostGross_SH ----------------------------------------------------
        ,SUM(
            CASE
                WHEN e.kWhWater1<0
                THEN
                    ISNULL(
                        -e.Qty *
                        e.IRkWh *
                        e.RRkWh *
                        (
                            e.kWhWater1 * ace_1.Gen_SH +
                            e.kWhWater2 * ace_2.Gen_SH
                        ),
                        0
                    )
                ELSE 0
            END
        ) AS WaterEnergyCostGross_SH
--------------------------------------------------------------------------------
--- OtherCostGross -------------------------------------------------------------
        ,SUM(
            e.Qty *
            (
                ISNULL( e.UnitRefrigCosts, 0 ) +
                ISNULL( e.UnitMiscCosts, 0 )
            )
        ) AS OtherCostGross
--------------------------------------------------------------------------------
    FROM InputMeasurevw AS e
    LEFT JOIN #FuelTypesForFuelSubstitution AS ft
    ON e.FuelType = ft.FuelType
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
            ,SUM(Gen_SB) AS Gen_SB
            ,SUM(Gen_SH) AS Gen_SH
            ,SUM(TD) AS TD
            /*,SUM(TD_AL) AS TD_AL*/
            ,SUM(TD_SB) AS TD_SB
            ,SUM(TD_SH) AS TD_SH
            ,DS
            /*,DS_AL*/
        FROM (
            --- Full Quarters, First Baseline ----------------------------------
            SELECT
                CET_ID
                ,ISNULL( Gen / POWER( Rqf, Qac ), 0 ) AS Gen
                /*,ISNULL( Gen_AL / POWER( Rqf, Qac ), 0 ) AS Gen_AL*/
                ,ISNULL( Gen_SB / POWER( Rqf_SCT, Qac), 0 ) AS Gen_SB
                ,ISNULL( Gen_SH / POWER( Rqf_SCT, Qac), 0 ) AS Gen_SH
                ,ISNULL( TD / POWER( Rqf, Qac ), 0 ) AS TD
                /*,ISNULL( TD_AL / POWER( Rqf, Qac ), 0 ) AS TD_AL*/
                ,ISNULL( TD_SB / POWER( Rqf_SCT, Qac), 0 ) AS TD_SB
                ,ISNULL( TD_SH / POWER( Rqf_SCT, Qac), 0 ) AS TD_SH
                ,ISNULL( DS1, 0 ) AS DS
                /*,ISNULL( DS1_AL, 0 ) AS DS_AL*/
            FROM AvoidedCostElecvw
            WHERE Qac BETWEEN Qm AND Qm + CONVERT( INT, eulq1 ) - 1

            --- Last Fractional Quarter, First Baseline ------------------------
            UNION SELECT
                CET_ID
                ,( eulq1 - FLOOR( eulq1 ) ) * (Gen / POWER( Rqf, Qac ) ) AS Gen
                /*,( eulq1 - FLOOR( eulq1 ) ) * (Gen_AL / POWER( Rqf, Qac ) ) AS Gen_AL*/
                ,( eulq1 - FLOOR( eulq1 ) ) * (Gen_SB / POWER( Rqf_SCT, Qac ) ) AS Gen_SB
                ,( eulq1 - FLOOR( eulq1 ) ) * (Gen_SH / POWER( Rqf_SCT, Qac ) ) AS Gen_SH
                ,( eulq1 - FLOOR( eulq1 ) ) * (TD / POWER( Rqf, Qac ) ) AS TD
                /*,( eulq1 - FLOOR( eulq1 ) ) * (TD_AL / POWER( Rqf, Qac ) ) AS TD_AL*/
                ,( eulq1 - FLOOR( eulq1 ) ) * (TD_SB / POWER( Rqf_SCT, Qac ) ) AS TD_SB
                ,( eulq1 - FLOOR( eulq1 ) ) * (TD_SH / POWER( Rqf_SCT, Qac ) ) AS TD_SH
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
            ,SUM(Gen_SB) AS Gen_SB
            ,SUM(Gen_SH) AS Gen_SH
            ,SUM(TD) AS TD
            /*,SUM(TD_AL) AS TD_AL*/
            ,SUM(TD_SB) AS TD_SB
            ,SUM(TD_SH) AS TD_SH
            ,DS
            /*,DS_AL*/
        FROM (
            --- First Fractional Quarter, Second Baseline ----------------------
            SELECT
                CET_ID
                ,( 1 - ( eulq1 - FLOOR( eulq1 ) ) ) * ( Gen / POWER( Rqf, Qac ) ) AS Gen
                /*,( 1 - ( eulq1 - FLOOR( eulq1 ) ) ) * ( Gen_AL / POWER( Rqf, Qac ) ) AS Gen_AL*/
                ,( 1 - ( eulq1 - FLOOR( eulq1 ) ) ) * ( Gen_SB / POWER( Rqf_SCT, Qac ) ) AS Gen_SB
                ,( 1 - ( eulq1 - FLOOR( eulq1 ) ) ) * ( Gen_SH / POWER( Rqf_SCT, Qac ) ) AS Gen_SH
                ,( 1 - ( eulq1 - FLOOR( eulq1 ) ) ) * ( TD / POWER( Rqf, Qac ) ) AS TD
                /*,( 1 - ( eulq1 - FLOOR( eulq1 ) ) ) * ( TD_AL / POWER( Rqf, Qac ) ) AS TD_AL*/
                ,( 1 - ( eulq1 - FLOOR( eulq1 ) ) ) * ( TD_SB / POWER( Rqf_SCT, Qac ) ) AS TD_SB
                ,( 1 - ( eulq1 - FLOOR( eulq1 ) ) ) * ( TD_SH / POWER( Rqf_SCT, Qac ) ) AS TD_SH
                ,ISNULL( DS2, 0 ) AS DS
                /*,ISNULL( DS2_AL, 0 ) AS DS_AL*/
            FROM AvoidedCostElecvw
            WHERE Qac = Qm + CONVERT( INT, eulq1 )

            --- Full Quarters, Second Baseline ---------------------------------
            UNION SELECT
                CET_ID
                ,ISNULL( Gen / POWER( Rqf, Qac ), 0 ) AS Gen
                /*,ISNULL( Gen_AL / POWER( Rqf, Qac ), 0 ) AS Gen_AL*/
                ,ISNULL( Gen_SB / POWER( Rqf_SCT, Qac ), 0 ) AS Gen_SB
                ,ISNULL( Gen_SH / POWER( Rqf_SCT, Qac ), 0 ) AS Gen_SH
                ,ISNULL( TD / POWER( Rqf, Qac ), 0 ) AS TD
                /*,ISNULL( TD_AL / POWER( Rqf, Qac ), 0 ) AS TD_AL*/
                ,ISNULL( TD_SB / POWER( Rqf_SCT, Qac ), 0 ) AS TD_SB
                ,ISNULL( TD_SH / POWER( Rqf_SCT, Qac ), 0 ) AS TD_SH
                ,ISNULL( DS2, 0 ) AS DS
                /*,ISNULL( DS2_AL, 0 ) AS DS_AL*/
            FROM AvoidedCostElecvw
            WHERE Qac BETWEEN Qm + CONVERT( INT, eulq1 ) + 1 AND Qm + CONVERT( INT, eulq2 ) - 1

            --- Last Fractional Quarter, Second Baseline -----------------------
            UNION SELECT
                CET_ID
                ,( eulq2 - FLOOR( eulq2 ) ) * ( Gen / POWER( Rqf, Qac ) ) AS Gen
                /*,( eulq2 - FLOOR( eulq2 ) ) * ( Gen_AL / POWER( Rqf, Qac ) ) AS Gen_AL*/
                ,( eulq2 - FLOOR( eulq2 ) ) * ( Gen_SB / POWER( Rqf_SCT, Qac ) ) AS Gen_SB
                ,( eulq2 - FLOOR( eulq2 ) ) * ( Gen_SH / POWER( Rqf_SCT, Qac ) ) AS Gen_SH
                ,( eulq2 - FLOOR( eulq2 ) ) * ( TD / POWER( Rqf, Qac ) ) AS TD
                ,( eulq2 - FLOOR( eulq2 ) ) * ( TD_SB / POWER( Rqf_SCT, Qac ) ) AS TD_SB
                ,( eulq2 - FLOOR( eulq2 ) ) * ( TD_SH / POWER( Rqf_SCT, Qac ) ) AS TD_SH
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
            ,SUM(Gas_SB) AS Gas_SB
            ,SUM(Gas_SH) AS Gas_SH
            /*,SUM(Gas_AL) AS Gas_AL*/
        FROM (
            --- Full Quarters, First Baseline ----------------------------------
            SELECT
                CET_ID
                ,ISNULL( Cost / POWER( Rqf, Qac ), 0 ) AS Gas
                ,ISNULL( Cost_SB / POWER( Rqf_SCT, Qac ), 0 ) AS Gas_SB
                ,ISNULL( Cost_SH / POWER( Rqf_SCT, Qac ), 0 ) AS Gas_SH
                /*,ISNULL( Cost_AL / POWER( Rqf, Qac ), 0 ) AS Gas_AL*/
            FROM AvoidedCostGasvw
            WHERE Qac BETWEEN Qm AND Qm + CONVERT( INT, eulq1 ) - 1

            --- Last Fractional Quarter, First Baseline ------------------------
            UNION SELECT
                CET_ID
                ,( eulq1 - FLOOR( eulq1 ) ) * ( Cost / POWER( Rqf, Qac ) ) AS Gas
                ,( eulq1 - FLOOR( eulq1 ) ) * ( Cost_SB / POWER( Rqf_SCT, Qac ) ) AS Gas_SB
                ,( eulq1 - FLOOR( eulq1 ) ) * ( Cost_SH / POWER( Rqf_SCT, Qac ) ) AS Gas_SH
                /*,( eulq1 - FLOOR( eulq1 ) ) * ( Cost_AL / POWER( Rqf, Qac ) ) AS Gas_AL*/
            FROM AvoidedCostGasvw
            WHERE Qac = Qm + CONVERT( INT, eulq1 )
        ) AS A GROUP BY CET_ID
    ) AS acg_1 ON e.CET_ID = acg_1.CET_ID

--- Second Baseline Avoided Gas Costs:
    LEFT JOIN (
        SELECT
            CET_ID
            ,SUM(Gas) AS Gas
            ,SUM(Gas_SB) AS Gas_SB
            ,SUM(Gas_SH) AS Gas_SH
            /*,SUM(Gas_AL) AS Gas_AL*/
        FROM (
            --- First Fractional Quarter, Second Baseline ----------------------
            SELECT
                CET_ID
                ,( 1 - ( eulq1 - FLOOR( eulq1 ) ) ) * ( Cost / POWER( Rqf, Qac ) ) AS Gas
                ,( 1 - ( eulq1 - FLOOR( eulq1 ) ) ) * ( Cost_SB / POWER( Rqf_SCT, Qac ) ) AS Gas_SB
                ,( 1 - ( eulq1 - FLOOR( eulq1 ) ) ) * ( Cost_SH / POWER( Rqf_SCT, Qac ) ) AS Gas_SH
                /*,( 1 - ( eulq1 - FLOOR( eulq1 ) ) ) * ( Cost_AL / POWER( Rqf, Qac ) ) AS Gas_AL*/
            FROM AvoidedCostGasvw
            WHERE Qac = Qm + CONVERT( INT, eulq1 )

            --- Full Quarters, Second Baseline ---------------------------------
            UNION SELECT
                CET_ID
                ,ISNULL( Cost / POWER( Rqf, Qac ), 0 ) AS Gas
                ,ISNULL( Cost_SB / POWER( Rqf_SCT, Qac ), 0 ) AS Gas_SB
                ,ISNULL( Cost_SH / POWER( Rqf_SCT, Qac ), 0 ) AS Gas_SH
                /*,ISNULL( Cost_AL / POWER( Rqf, Qac ), 0 ) AS Gas_AL*/
            FROM AvoidedCostGasvw
            WHERE Qac BETWEEN Qm + CONVERT( INT, eulq1 ) + 1 AND Qm + CONVERT( INT, eulq2 ) - 1

            --- Last Fractional Quarter, Second Baseline -----------------------
            UNION SELECT
                CET_ID
                ,( eulq2 - FLOOR( eulq2 ) ) * ( Cost / POWER( Rqf, Qac ) ) AS Gas
                ,( eulq2 - FLOOR( eulq2 ) ) * ( Cost_SB / POWER( Rqf_SCT, Qac ) ) AS Gas_SB
                ,( eulq2 - FLOOR( eulq2 ) ) * ( Cost_SH / POWER( Rqf_SCT, Qac ) ) AS Gas_SH
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
        ElecBen_SB = ISNULL( ElecBen_SB, 0 ),
        ElecBen_SH = ISNULL( ElecBen_SH, 0 ),
        GasBen = ISNULL( GasBen, 0 ),
        GasBen_SB = ISNULL( GasBen_SB, 0 ),
        GasBen_SH = ISNULL( GasBen_SH, 0 ),
        TaxCredits = ISNULL( TaxCredits, 0 ),
        WaterEnergyBen = ISNULL( WaterEnergyBen, 0 ),
        WaterEnergyBen_SB = ISNULL( WaterEnergyBen_SB, 0 ),
        WaterEnergyBen_SH = ISNULL( WaterEnergyBen_SH, 0 ),
        OtherBen = ISNULL( OtherBen, 0 ),
        ElecBenGross = ISNULL( ElecBenGross, 0 ),
        ElecBenGross_SB = ISNULL( ElecBenGross_SB, 0 ),
        ElecBenGross_SH = ISNULL( ElecBenGross_SH, 0 ),
        GasBenGross = ISNULL( GasBenGross, 0 ),
        GasBenGross_SB = ISNULL( GasBenGross_SB, 0 ),
        GasBenGross_SH = ISNULL( GasBenGross_SH, 0 ),
        TaxCreditsGross = ISNULL( TaxCreditsGross, 0 ),
        WaterEnergyBenGross = ISNULL( WaterEnergyBenGross, 0 ),
        WaterEnergyBenGross_SB = ISNULL( WaterEnergyBenGross_SB, 0 ),
        WaterEnergyBenGross_SH = ISNULL( WaterEnergyBenGross_SH, 0 ),
        OtherBenGross = ISNULL( OtherBenGross, 0 ),
        ElecSupplyCost = ISNULL( ElecSupplyCost, 0 ),
        ElecSupplyCost_SB = ISNULL( ElecSupplyCost_SB, 0 ),
        ElecSupplyCost_SH = ISNULL( ElecSupplyCost_SH, 0 ),
        GasSupplyCost = ISNULL( GasSupplyCost, 0 ),
        GasSupplyCost_SB = ISNULL( GasSupplyCost_SB, 0 ),
        GasSupplyCost_SH = ISNULL( GasSupplyCost_SH, 0 ),
        WaterEnergyCost = ISNULL( WaterEnergyCost, 0 ),
        WaterEnergyCost_SB = ISNULL( WaterEnergyCost_SB, 0 ),
        WaterEnergyCost_SH = ISNULL( WaterEnergyCost_SH, 0 ),
        OtherCost = ISNULL( OtherCost, 0 ),
        ElecSupplyCostGross = ISNULL( ElecSupplyCostGross, 0 ),
        ElecSupplyCostGross_SB = ISNULL( ElecSupplyCostGross_SB, 0 ),
        ElecSupplyCostGross_SH = ISNULL( ElecSupplyCostGross_SH, 0 ),
        GasSupplyCostGross = ISNULL( GasSupplyCost, 0 ),
        GasSupplyCostGross_SB = ISNULL( GasSupplyCost_SB, 0 ),
        GasSupplyCostGross_SH = ISNULL( GasSupplyCost_SH, 0 ),
        WaterEnergyCostGross = ISNULL( WaterEnergyCostGross, 0 ),
        WaterEnergyCostGross_SB = ISNULL( WaterEnergyCostGross_SB, 0 ),
        WaterEnergyCostGross_SH = ISNULL( WaterEnergyCostGross_SH, 0 ),
        OtherCostGross = ISNULL( OtherCostGross, 0 )
END

PRINT 'Updating SC, TRC, and PAC costs...'
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
        POWER( s.Raf_SCT, Convert( int, [Year]-@FirstYear )
        ) AS SumCostsNPV_SCT
    FROM dbo.[InputProgramvw] AS  c
    LEFT JOIN Settingsvw AS s
    ON c.PA = s.PA
    WHERE s.[Version] = @AVCVersion
    GROUP BY c.PrgID, [Year], s.Raf
)
, ProgramCostsSum (
    PrgID,
    SumCosts,
    SumCostsNPV,
    SumCostsNPV_SCT
) AS (
    SELECT PrgID,
    SUM(ISNULL(SumCosts,0)) AS SumCosts,
    SUM(ISNULL(SumCostsNPV,0)) AS SumCostsNPV
    SUM(ISNULL(SumCostsNPV_SCT,0)) AS SumCostsNPV_SCT
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
    MeasureIncCost,
    RebatesPV_SCT,
    IncentsAndDIPV_SCT,
    GrossMeasCostPV_SCT
) AS (
    SELECT
        PrgID,
        e.CET_ID,
        SUM(
            (
                Qty *
                CASE
                    WHEN NOT ISNULL(ft.FuelType,0) = '0' OR e.Channel = 'C&S' OR (e.IncentiveToOthers + e.DILaborCost + e.DIMaterialCost - e.UnitMeasureGrossCost > 0)
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
        ,SUM(Qty * e.MeasIncrCost)  AS MeasureIncCost
        SUM(
            Qty * e.EndUserRebate / POWER(s.Rqf_SCT, Qm)
        ) AS RebatesPV_SCT,
        SUM(
            Qty * (e.IncentiveToOthers + e.DILaborCost + e.DIMaterialCost) / POWER(s.Rqf_SCT, Qm)
        ) AS IncentsAndDIPV_SCT,
        SUM(
            Qty *
            (
                e.UnitMeasureGrossCost -
                CASE
                    WHEN e.rul > 0
                    THEN (e.UnitMeasureGrossCost - e.MeasIncrCost ) * POWER( ( 1 + e.MeasInflation / 4 ) / s.Rqf_SCT, e.rulq )
                    ELSE 0
                END
            ) / POWER(s.Rqf_SCT, Qm)
        ) AS GrossMeasCostPV_SCT
        ,SUM(Qty * e.MeasIncrCost)  AS MeasureIncCost
    FROM InputMeasurevw e
    LEFT JOIN Settingsvw s ON e.PA = s.PA
    LEFT JOIN #FuelTypesForFuelSubstitution AS ft ON e.FuelType = ft.FuelType
    WHERE s.[Version] = @AVCVersion
    GROUP BY PrgID, e.CET_ID
    )
, BenefitsSum (
    PrgID
    ,SumElecBen
    ,SumElecBen_SB
    ,SumElecBen_SH
    ,SumGasBen
    ,SumGasBen_SB
    ,SumGasBen_SH
    ,SumOtherBen
    ,SumTaxCredits
    ,SumTaxCreditsGross
    ,SumElecBenGross
    ,SumElecBenGross_SB
    ,SumElecBenGross_SH
    ,SumGasBenGross
    ,SumGasBenGross_SB
    ,SumGasBenGross_SH
    ,SumOtherBenGross
    ,SumWaterEnergyBen
    ,SumWaterEnergyBen_SB
    ,SumWaterEnergyBen_SH
    ,SumWaterEnergyBenGross
    ,SumWaterEnergyBenGross_SB
    ,SumWaterEnergyBenGross_SH
)
AS (
    SELECT
        PrgID
        ,SUM( CASE WHEN ISNULL(ElecBen,0) > 0 THEN ElecBen ELSE 0 END ) AS SumElecBen
        ,SUM( CASE WHEN ISNULL(ElecBen_SB,0) > 0 THEN ElecBen_SB ELSE 0 END ) AS SumElecBen_SB
        ,SUM( CASE WHEN ISNULL(ElecBen_SH,0) > 0 THEN ElecBen_SH ELSE 0 END ) AS SumElecBen_SH
        ,SUM( CASE WHEN ISNULL(GasBen,0) > 0 THEN GasBen ELSE 0 END ) AS SumGasBen
        ,SUM( CASE WHEN ISNULL(GasBen_SB,0) > 0 THEN GasBen_SB ELSE 0 END ) AS SumGasBen_SB
        ,SUM( CASE WHEN ISNULL(GasBen_SH,0) > 0 THEN GasBen_SH ELSE 0 END ) AS SumGasBen_SH
        ,SUM( CASE WHEN ISNULL(OtherBen,0) > 0 THEN OtherBen ELSE 0 END ) AS SumOtherBen
        ,SUM( CASE WHEN ISNULL(ElecBenGross,0) > 0 THEN ElecBenGross ELSE 0 END ) AS SumElecBenGross
        ,SUM( CASE WHEN ISNULL(TaxCredits,0) > 0 THEN TaxCredits ELSE 0 END ) AS SumTaxCredits
        ,SUM( CASE WHEN ISNULL(TaxCreditsGross,0) > 0 THEN TaxCreditsGross ELSE 0 END ) AS SumTaxCreditsGross
        ,SUM( CASE WHEN ISNULL(ElecBenGross_SB,0) > 0 THEN ElecBenGross_SB ELSE 0 END ) AS SumElecBenGross_SB
        ,SUM( CASE WHEN ISNULL(ElecBenGross_SH,0) > 0 THEN ElecBenGross_SH ELSE 0 END ) AS SumElecBenGross_SH
        ,SUM( CASE WHEN ISNULL(GasBenGross,0) > 0 THEN GasBenGross ELSE 0 END ) AS SumGasBenGross
        ,SUM( CASE WHEN ISNULL(GasBenGross_SB,0) > 0 THEN GasBenGross_SB ELSE 0 END ) AS SumGasBenGross_SB
        ,SUM( CASE WHEN ISNULL(GasBenGross_SH,0) > 0 THEN GasBenGross_SH ELSE 0 END ) AS SumGasBenGross_SH
        ,SUM( CASE WHEN ISNULL(OtherBenGross,0) > 0 THEN OtherBenGross ELSE 0 END ) AS SumOtherBenGross
        ,SUM( CASE WHEN ISNULL(WaterEnergyBen,0) > 0 THEN WaterEnergyBen ELSE 0 END ) AS SumWaterEnergyBen
        ,SUM( CASE WHEN ISNULL(WaterEnergyBen_SB,0) > 0 THEN WaterEnergyBen_SB ELSE 0 END ) AS SumWaterEnergyBen_SB
        ,SUM( CASE WHEN ISNULL(WaterEnergyBen_SH,0) > 0 THEN WaterEnergyBen_SH ELSE 0 END ) AS SumWaterEnergyBen_SH
        ,SUM( CASE WHEN ISNULL(WaterEnergyBenGross,0) > 0 THEN WaterEnergyBenGross ELSE 0 END ) AS SumWaterEnergyBenGross
        ,SUM( CASE WHEN ISNULL(WaterEnergyBenGross_SB,0) > 0 THEN WaterEnergyBenGross_SB ELSE 0 END ) AS SumWaterEnergyBenGross_SB
        ,SUM( CASE WHEN ISNULL(WaterEnergyBenGross_SH,0) > 0 THEN WaterEnergyBenGross_SH ELSE 0 END ) AS SumWaterEnergyBenGross_SH
    FROM #OutputCE
    GROUP BY PrgID
)
, BenPos (
    CET_ID
    ,ElecBenPos
    ,ElecBenPos_SB
    ,ElecBenPos_SH
    ,GasBenPos
    ,GasBenPos_SB
    ,GasBenPos_SH
    ,WaterEnergyBenPos
    ,WaterEnergyBenPos_SB
    ,WaterEnergyBenPos_SH
    ,OtherBenPos
    ,SumBenPos
    ,SumBenPos_SB
    ,SumBenPos_SH
)
AS
(
    SELECT
        CET_ID
        ,CASE WHEN ISNULL(ElecBen,0) > 0 THEN ElecBen ELSE 0 END AS ElecBenPos
        ,CASE WHEN ISNULL(ElecBen_SB,0) > 0 THEN ElecBen_SB ELSE 0 END AS ElecBenPos_SB
        ,CASE WHEN ISNULL(ElecBen_SB,0) > 0 THEN ElecBen_SH ELSE 0 END AS ElecBenPos_SH
        ,CASE WHEN ISNULL(GasBen,0) > 0 THEN GasBen ELSE 0 END AS GasBenPos
        ,CASE WHEN ISNULL(GasBen_SB,0) > 0 THEN GasBen_SB ELSE 0 END AS GasBenPos_SB
        ,CASE WHEN ISNULL(GasBen_SH,0) > 0 THEN GasBen_SH ELSE 0 END AS GasBenPos_SH
        ,CASE WHEN ISNULL(WaterEnergyBen,0) > 0 THEN WaterEnergyBen ELSE 0 END AS WaterEnergyBenPos
        ,CASE WHEN ISNULL(WaterEnergyBen_SB,0) > 0 THEN WaterEnergyBen_SB ELSE 0 END AS WaterEnergyBenPos_SB
        ,CASE WHEN ISNULL(WaterEnergyBen_SH,0) > 0 THEN WaterEnergyBen_SH ELSE 0 END AS WaterEnergyBenPos_SH
        ,CASE WHEN ISNULL(OtherBen,0) > 0 THEN OtherBen ELSE 0 END AS OtherBenPos
        ,CASE WHEN ISNULL(ElecBen,0) > 0 THEN ElecBen ELSE 0 END +
          CASE WHEN ISNULL(GasBen,0) > 0 THEN GasBen ELSE 0 END +
          CASE WHEN ISNULL(WaterEnergyBen,0) > 0 THEN WaterEnergyBen ELSE 0 END +
          CASE WHEN ISNULL(OtherBen,0) > 0 THEN OtherBen ELSE 0 END
          AS SumBenPos
        ,CASE WHEN ISNULL(ElecBen_SB,0) > 0 THEN ElecBen_SB ELSE 0 END +
          CASE WHEN ISNULL(GasBen,0) > 0 THEN GasBen ELSE 0 END +
          CASE WHEN ISNULL(WaterEnergyBen,0) > 0 THEN WaterEnergyBen ELSE 0 END +
          CASE WHEN ISNULL(OtherBen,0) > 0 THEN OtherBen ELSE 0 END
          AS SumBenPos_SB
        ,CASE WHEN ISNULL(ElecBen_SH,0) > 0 THEN ElecBen_SH ELSE 0 END +
          CASE WHEN ISNULL(GasBen,0) > 0 THEN GasBen ELSE 0 END +
          CASE WHEN ISNULL(WaterEnergyBen,0) > 0 THEN WaterEnergyBen ELSE 0 END +
          CASE WHEN ISNULL(OtherBen,0) > 0 THEN OtherBen ELSE 0 END
          AS SumBenPos_SH
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
    , ExcessIncentivesPV_SCT
)
AS
(
    SELECT CE.CET_ID
        ,CASE
            WHEN ri.IncentsAndDIPV - ri.GrossMeasCostPV > 0
            THEN ri.IncentsAndDIPV - ri.GrossMeasCostPV
            ELSE 0
        END AS ExcessIncentivesPV
        ,CASE
            WHEN ri.IncentsAndDIPV_SCT - ri.GrossMeasCostPV_SCT > 0
            THEN ri.IncentsAndDIPV_SCT - ri.GrossMeasCostPV_SCT
            ELSE 0
        END AS ExcessIncentivesPV_SCT
    FROM #OutputCE  ce
    LEFT JOIN RebatesAndIncentives AS ri on CE.CET_ID = ri.CET_ID
    LEFT JOIN (SELECT CET_ID, MeasImpactType, Channel FROM InputMeasurevw) AS e ON CE.CET_ID = e.CET_ID
)
,GrossMeasureCostAdjusted (
    CET_ID
    ,GrossMeasureCostAdjustedPV
    ,GrossMeasureCostAdjustedPV_SCT
    ,MarkEffectPlusExcessIncPV
    ,MarkEffectPlusExcessIncPV_SCT
)
AS
(
    SELECT CE.CET_ID
        ,ri.GrossMeasCostPV -  (ri.IncentsAndDIPV + ri.RebatesPV) + (ex.ExcessIncentivesPV) AS GrossMeasureCostAdjustedPV
        ,ri.GrossMeasCostPV_SCT -  (ri.IncentsAndDIPV_SCT + ri.RebatesPV_SCT) + (ex.ExcessIncentivesPV_SCT) AS GrossMeasureCostAdjustedPV_SCT
        ,@MECost * ((ri.GrossMeasCostPV) + (ex.ExcessIncentivesPV)) AS MarkEffectPlusExcessIncPV
        ,@MECost * ((ri.GrossMeasCostPV_SCT) + (ex.ExcessIncentivesPV_SCT)) AS MarkEffectPlusExcessIncPV_SCT
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
    ,GrossParticipantCostPV_SCT
    ,NetParticipantCostPV
    ,NetParticipantCostPV_SCT
)
AS
(
    SELECT CE.CET_ID
        ,ex.ExcessIncentivesPV AS ExcessIncentives
        ,ri.GrossMeasCostPV - (ri.IncentsAndDIPV + ri.RebatesPV) + (ex.ExcessIncentivesPV) AS GrossMeasureCostAdjusted
        ,e.NTGRCost * (gma.GrossMeasureCostAdjustedPV) + (@MECost * (ri.GrossMeasCostPV + ex.ExcessIncentivesPV)) AS ParticipantCost
        ,(e.NTGRCost * (gma.GrossMeasureCostAdjustedPV) + (@MECost * (ri.GrossMeasCostPV + ex.ExcessIncentivesPV))) / POWER(s.Rqf, Qm) AS ParticipantCostPV
        ,ri.GrossMeasCostPV - (ri.IncentsAndDIPV + ri.RebatesPV) + ex.ExcessIncentivesPV AS GrossParticipantCostPV
        ,ri.GrossMeasCostPV_SCT - (ri.IncentsAndDIPV_SCT + ri.RebatesPV_SCT) + ex.ExcessIncentivesPV_SCT AS GrossParticipantCostPV_SCT
        ,e.NTGRCost * (ri.GrossMeasCostPV - (ri.IncentsAndDIPV + ri.RebatesPV)+ ex.ExcessIncentivesPV) + MarkEffectPlusExcessIncPV AS NetParticipantCostPV
        ,e.NTGRCost * (ri.GrossMeasCostPV_SCT - (ri.IncentsAndDIPV_SCT + ri.RebatesPV_SCT)+ ex.ExcessIncentivesPV_SCT) + MarkEffectPlusExcessIncPV_SCT AS NetParticipantCostPV_SCT
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
    ,SCB_Cost
    ,SCB_CostGross
    ,SCB_Cost_NoAdmin
    ,SCH_Cost
    ,SCH_CostGross
    ,SCH_Cost_NoAdmin
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
            OtherBen
        ) - (
            ElecSupplyCost +
            GasSupplyCost +
            WaterEnergyCost +
            OtherCost
        ) AS TotalSystemBenefit
        ,(
            ElecBenGross +
            GasBenGross +
            WaterEnergyBenGross +
            OtherBenGross
        ) - (
            ElecSupplyCostGross +
            GasSupplyCostGross +
            WaterEnergyCostGross +
            OtherCostGross
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
        ,(
            CASE 
                WHEN (BensSum.SumElecBen_SB + BensSum.SumGasBen_SB + BensSum.SumWaterEnergyBen_SB + BensSum.SumOtherBen) <> 0
                THEN
                    (
                       CASE 
                           WHEN ISNULL(CE.ElecBen_SB,0) > 0
                           THEN CE.ElecBen_SB
                           ELSE 0
                       END +
                       CASE 
                           WHEN ISNULL(CE.GasBen_SB,0) > 0
                           THEN CE.GasBen_SB
                           ELSE 0
                        END +
                       CASE 
                           WHEN ISNULL(CE.WaterEnergyBen_SB,0) > 0
                           THEN CE.WaterEnergyBen_SB
                           ELSE 0
                        END +
                        CASE
                            WHEN ISNULL(CE.OtherBen,0) > 0
                            THEN OtherBen
                            ELSE 0
                        END
                    ) / (BensSum.SumElecBen_SB + BensSum.SumGasBen_SB + BensSum.SumWaterEnergyBen_SB + BensSum.SumOtherBen)
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
            ) / POWER(s.Rqf_SCT, Qm) +
            pc.NetParticipantCostPV_SCT +
            -- Increased supply costs, refrigerant costs, and miscellaneous costs
            CE.ElecSupplyCost_SB +
            CE.GasSupplyCost_SB +
            CE.WaterEnergyCost_SB +
            CE.OtherCost
        ) AS SCB_Cost
        ,(
            CASE 
                WHEN (SumElecBenGross_SB + SumGasBenGross_SB + SumWaterEnergyBenGross_SB + SumOtherBenGross) <> 0
                THEN
                    (
                        CASE
                            WHEN ISNULL(ElecBenGross_SB,0) > 0
                            THEN ElecBenGross_SB
                            ELSE 0
                        END +
                        CASE
                            WHEN ISNULL(GasBenGross_SB,0) > 0
                            THEN GasBenGross_SB
                            ELSE 0
                        END + 
                        CASE
                            WHEN ISNULL(WaterEnergyBenGross_SB,0) > 0
                            THEN WaterEnergyBenGross_SB
                            ELSE 0
                        END + 
                        CASE
                            WHEN ISNULL(OtherBenGross,0) > 0
                            THEN OtherBenGross
                            ELSE 0
                        END
                    ) / (SumElecBenGross_SB + SumGasBenGross_SB + SumWaterEnergyBenGross_SB + SumOtherBenGross)
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
            ) / POWER(s.Rqf_SCT, Qm) +
            pc.GrossParticipantCostPV_SCT +
            -- Increased supply costs, refrigerant costs, and miscellaneous costs
            CE.ElecSupplyCost_SB +
            CE.GasSupplyCost_SB +
            CE.WaterEnergyCost_SB +
            CE.OtherCostGross
        ) AS SCB_CostGross
        ,(
            Qty *
            (
                IncentiveToOthers +
                DILaborCost +
                DIMaterialCost +
                EndUserRebate
            ) / POWER(s.Rqf_SCT, Qm) +
            pc.NetParticipantCostPV_SCT +
            -- Increased supply costs, refrigerant costs, and miscellaneous costs
            CE.ElecSupplyCost_SB +
            CE.GasSupplyCost_SB +
            CE.WaterEnergyCost_SB +
            CE.OtherCost
        ) AS SCB_Cost_NoAdmin
        ,(
            CASE 
                WHEN (BensSum.SumElecBen_SH + BensSum.SumGasBen_SH + BensSum.SumWaterEnergyBen_SH + BensSum.SumOtherBen) <> 0
                THEN
                    (
                       CASE 
                           WHEN ISNULL(CE.ElecBen_SH,0) > 0
                           THEN CE.ElecBen_SH
                           ELSE 0
                       END +
                       CASE 
                           WHEN ISNULL(CE.GasBen_SH,0) > 0
                           THEN CE.GasBen_SH
                           ELSE 0
                        END +
                       CASE 
                           WHEN ISNULL(CE.WaterEnergyBen_SH,0) > 0
                           THEN CE.WaterEnergyBen_SH
                           ELSE 0
                        END +
                        CASE
                            WHEN ISNULL(CE.OtherBen,0) > 0
                            THEN OtherBen
                            ELSE 0
                        END
                    ) / (BensSum.SumElecBen_SH + BensSum.SumGasBen_SH + BensSum.SumWaterEnergyBen_SH + BensSum.SumOtherBen)
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
            ) / POWER(s.Rqf_SCT, Qm) +
            pc.NetParticipantCostPV_SCT +
            -- Increased supply costs, refrigerant costs, and miscellaneous costs
            CE.ElecSupplyCost_SH +
            CE.GasSupplyCost_SH +
            CE.WaterEnergyCost_SH +
            CE.OtherCost
        ) AS SCH_Cost
        ,(
            CASE 
                WHEN (SumElecBenGross_SH + SumGasBenGross_SH + SumWaterEnergyBenGross_SH + SumOtherBenGross) <> 0
                THEN
                    (
                        CASE
                            WHEN ISNULL(ElecBenGross_SH,0) > 0
                            THEN ElecBenGross_SH
                            ELSE 0
                        END +
                        CASE
                            WHEN ISNULL(GasBenGross_SH,0) > 0
                            THEN GasBenGross_SH
                            ELSE 0
                        END + 
                        CASE
                            WHEN ISNULL(WaterEnergyBenGross_SH,0) > 0
                            THEN WaterEnergyBenGross_SH
                            ELSE 0
                        END + 
                        CASE
                            WHEN ISNULL(OtherBenGross,0) > 0
                            THEN OtherBenGross
                            ELSE 0
                        END
                    ) / (SumElecBenGross_SH + SumGasBenGross_SH + SumWaterEnergyBenGross_SH + SumOtherBenGross)
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
            ) / POWER(s.Rqf_SCT, Qm) +
            pc.GrossParticipantCostPV_SCT +
            -- Increased supply costs, refrigerant costs, and miscellaneous costs
            CE.ElecSupplyCost_SH +
            CE.GasSupplyCost_SH +
            CE.WaterEnergyCost_SH +
            CE.OtherCostGross
        ) AS SCH_CostGross
        ,(
            Qty *
            (
                IncentiveToOthers +
                DILaborCost +
                DIMaterialCost +
                EndUserRebate
            ) / POWER(s.Rqf_SCT, Qm) +
            pc.NetParticipantCostPV_SCT +
            -- Increased supply costs, refrigerant costs, and miscellaneous costs
            CE.ElecSupplyCost_SH +
            CE.GasSupplyCost_SH +
            CE.WaterEnergyCost_SH +
            CE.OtherCost
        ) AS SCH_Cost_NoAdmin
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
        ) AS WeightedElecAlloc
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
        , SCBCost = c.SCB_Cost
        , SCHCost = c.SCH_Cost
        , TRCCost = c.TRC_Cost
        , PACCost = c.PAC_Cost
        , SCBCostGross = c.SCB_CostGross
        , SCBCostNoAdmin = c.SCB_Cost_NoAdmin
        , SCHCostGross = c.SCH_CostGross
        , SCHCostNoAdmin = c.SCH_Cost_NoAdmin
        , TRCCostGross = c.TRC_CostGross
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
    , BillReducElec
    , BillIncrElec
    , BillReducGas
    , BillIncrGas
) AS (
    SELECT 
        e.CET_ID
        ,SUM(
            CASE
                WHEN NOT ISNULL(ft.FuelType,0) = '0'
                    OR (kWh1 * (ISNULL(RateE1, 0) + ISNULL(RateEFrac1,0)) + kWh2 * (ISNULL(RateEFrac2_1,0)+ISNULL(RateE2,0)+ISNULL(RateEFrac2_2,0))) > 0
                THEN ISNULL(
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
                ELSE 0
            END
        ) AS BillReducElec
        ,SUM(
            CASE
                WHEN NOT ISNULL(ft.FuelType,0) = '0'
                    AND (kWh1 * (ISNULL(RateE1, 0) + ISNULL(RateEFrac1,0)) + kWh2 * (ISNULL(RateEFrac2_1,0)+ISNULL(RateE2,0)+ISNULL(RateEFrac2_2,0))) < 0
                THEN ISNULL(
                    -Qty *
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
                ELSE 0
            END
        ) AS BillIncrElec
        ,SUM(
            CASE
                WHEN NOT ISNULL(ft.FuelType,0) = '0' AND (Thm1 * (ISNULL(RateG1, 0) + ISNULL(RateGFrac1,0)) + Thm2 * (ISNULL(RateGFrac2_1,0)+ISNULL(RateG2,0)+ISNULL(RateGFrac2_2,0)))<0
                THEN
                    ISNULL(
                        -Qty *
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
                ELSE 0
            END
        ) AS BillReducGas
        ,SUM(
            CASE
                WHEN ISNULL(ft.FuelType,0) = '0'
                    AND (Thm1 * (ISNULL(RateG1, 0) + ISNULL(RateGFrac1,0)) + Thm2 * (ISNULL(RateGFrac2_1,0)+ISNULL(RateG2,0)+ISNULL(RateGFrac2_2,0))) < 0
                THEN
                    ISNULL(
                        -Qty *
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
                ELSE 0
            END
        ) AS BillIncrGas
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
    SET
        BillReducElec=t.BillReducElec,
        BillIncrElec=t.BillIncrElec,
        BillReducGas=t.BillReducGas,
        BillIncrGas=t.BillIncrGas,
        RIMCost = t.BillReducElec + t.BillReducGas + ce.PacCost,
        RIMCostNoAdmin = t.BillReducElec + t.BillReducGas + ce.PacCostNoAdmin
    FROM #OutputCE ce
    LEFT JOIN RIMTest t ON CE.CET_ID = t.CET_ID

END 


PRINT 'Updating SC, TRC, PAC, and RIM ratios...'

BEGIN
    -- Update SC, TRC, PAC, RIM ratios at measure level
UPDATE #OutputCE
SET
    SCBRatio =
        CASE
            WHEN SCBCost <> 0
            THEN (ElecBen_SB + GasBen_SB + WaterEnergyBen_SB + OtherBen) / (SCBCost)
            ELSE 0
        END
    ,SCHRatio =
        CASE
            WHEN SCHCost <> 0
            THEN (ElecBen_SH + GasBen_SH + WaterEnergyBen_SH + OtherBen) / (SCHCost)
            ELSE 0
        END
    ,TRCRatio =
        CASE
            WHEN TRCCost <> 0
            THEN (ElecBen + GasBen + WaterEnergyBen + OtherBen + TaxCredits) / (TRCCost)
            ELSE 0
        END
    ,PACRatio =
        CASE 
            WHEN PACCost <> 0
            THEN (ElecBen + GasBen + WaterEnergyBen + OtherBen) / (PACCost)
            ELSE 0
        END
    ,RIMRatio =
        CASE
            WHEN RIMCost <> 0
            THEN (ElecBen + GasBen + WaterEnergyBen + OtherBen + BillIncrElec + BillIncrGas) / (RIMCost)
            ELSE 0
        END
    ,SCBRatioNoAdmin =
        CASE 
            WHEN SCBCostNoAdmin <> 0
            THEN (ElecBen_SB + GasBen_SB + WaterEnergyBen_SB + OtherBen) / (SCBCostNoAdmin)
            ELSE 0
        END
    ,SCHRatioNoAdmin =
        CASE 
            WHEN SCHCostNoAdmin <> 0
            THEN (ElecBen_SH + GasBen_SH + WaterEnergyBen_SH + OtherBen) / (SCHCostNoAdmin)
            ELSE 0
        END
    ,TRCRatioNoAdmin =
        CASE 
            WHEN TRCCostNoAdmin <> 0
            THEN (ElecBen + GasBen + WaterEnergyBen + OtherBen + TaxCredits) / (TRCCostNoAdmin)
            ELSE 0
        END
    ,PACRatioNoAdmin =
        CASE 
            WHEN PACCostNoAdmin <> 0
            THEN (ElecBen + GasBen + WaterEnergyBen + OtherBen) / (PACCostNoAdmin)
            ELSE 0
        END
    ,RIMRatioNoAdmin =
        CASE
            WHEN RIMCostNoAdmin <> 0
            THEN (ElecBen + GasBen + WaterEnergyBen + OtherBen + BillIncrElec + BillIncrGas) / (RIMCostNoAdmin)
            ELSE 0
        END

--Clear OutputCE
DELETE FROM OutputCE WHERE JobID = @JobID
DELETE FROM SavedCE WHERE JobID = @JobID

--Copy data in temporary table to OutputCE
INSERT INTO OutputCE
( 
    JobID
    ,PA
    ,PrgID
    ,CET_ID
    ,ElecBen
    ,ElecBen_SB
    ,ElecBen_SH
    ,GasBen
    ,TaxCredits
    ,WaterEnergyBen
    ,OtherBen
    ,ElecBenGross
    ,ElecBenGross_SB
    ,ElecBenGross_SH
    ,GasBenGross
    ,TaxCreditsGross
    ,WaterEnergyBenGross
    ,OtherBenGross
    ,ElecSupplyCost
    ,ElecSupplyCost_SB
    ,ElecSupplyCost_SH
    ,GasSupplyCost
    ,WaterEnergyCost
    ,OtherCost
    ,ElecSupplyCostGross
    ,ElecSupplyCostGross_SB
    ,ElecSupplyCostGross_SH
    ,GasSupplyCostGross
    ,WaterEnergyCostGross
    ,OtherCostGross
    ,BillReducElec
    ,BillIncrElec
    ,BillReducGas
    ,BillIncrGas
    ,TotalSystemBenefit
    ,TotalSystemBenefitGross
    ,SCBCost
    ,SCHCost
    ,TRCCost
    ,PACCost
    ,RIMCost
    ,SCBCostGross
    ,SCBCostNoAdmin
    ,SCHCostGross
    ,SCHCostNoAdmin
    ,TRCCostGross
    ,TRCCostNoAdmin
    ,PACCostNoAdmin
    ,RIMCostNoAdmin
    ,SCBRatio
    ,SCHRatio
    ,TRCRatio
    ,PACRatio
    ,RIMRatio
    ,SCBRatioNoAdmin
    ,SCHRatioNoAdmin
    ,TRCRatioNoAdmin
    ,PACRatioNoAdmin
    ,RIMRatioNoAdmin
    ,WeightedBenefits
    ,WeightedElecAlloc
    ,WeightedProgramCost
)
SELECT
    JobID
    ,PA
    ,PrgID
    ,CET_ID
    ,ElecBen
    ,ElecBen_SB
    ,ElecBen_SH
    ,GasBen
    ,TaxCredits
    ,WaterEnergyBen
    ,OtherBen
    ,ElecBenGross
    ,ElecBenGross_SB
    ,ElecBenGross_SH
    ,GasBenGross
    ,TaxCreditsGross
    ,WaterEnergyBenGross
    ,OtherBenGross
    ,ElecSupplyCost
    ,ElecSupplyCost_SB
    ,ElecSupplyCost_SH
    ,GasSupplyCost
    ,WaterEnergyCost
    ,OtherCost
    ,ElecSupplyCostGross
    ,ElecSupplyCostGross_SB
    ,ElecSupplyCostGross_SH
    ,GasSupplyCostGross
    ,WaterEnergyCostGross
    ,OtherCostGross
    ,BillReducElec
    ,BillIncrElec
    ,BillReducGas
    ,BillIncrGas
    ,TotalSystemBenefit
    ,TotalSystemBenefitGross
    ,SCBCost
    ,SCHCost
    ,TRCCost
    ,PACCost
    ,RIMCost
    ,SCBCostGross
    ,SCBCostNoAdmin
    ,SCHCostGross
    ,SCHCostNoAdmin
    ,TRCCostGross
    ,TRCCostNoAdmin
    ,PACCostNoAdmin
    ,RIMCostNoAdmin
    ,SCBRatio
    ,SCHRatio
    ,TRCRatio
    ,PACRatio
    ,RIMRatio
    ,SCBRatioNoAdmin
    ,SCHRatioNoAdmin
    ,TRCRatioNoAdmin
    ,PACRatioNoAdmin
    ,RIMRatioNoAdmin
    ,WeightedBenefits
    ,WeightedElecAlloc
    ,WeightedProgramCost
FROM [#OutputCE]
ORDER BY JobID, CET_ID ASC

DROP TABLE [#OutputCE]
DROP TABLE [#FuelTypesForFuelSubstitution]

--PRINT 'Done!'

GO