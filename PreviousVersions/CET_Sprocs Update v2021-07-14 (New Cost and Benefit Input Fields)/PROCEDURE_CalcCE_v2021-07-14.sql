/*
################################################################################
Name             :  CalcCE (procedure)
Date             :  06/30/2016
Author           :  Wayne Hauck
Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose          :  This stored procedure calculates cost effectiveness.
Usage            :  n/a
Called by        :  n/a
Copyright ©      :  Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
Change History   :  06/30/2016  Wayne Hauck added comment header
                 :  12/30/2016  Wayne Hauck added measure inflation
                 :  12/30/2016  Added modified Elec and Gas benefits to use savings-specific installation rate (IR) and realization rate (RR)
                 :  02/11/2020  Robert Hansen reformatted for readability and added comments to identify possible errors
                 :  07/23/2020  Robert Hansen applied logic to remove negative benefits to measure costs
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
                 :  08/03/2020  Robert Hansen added switch to negative benefits logic to apply
                 :              only to measures marked with 'FuelSub' in the MeasImpactType
                 :              field of the InputMeasure table
                 :  11/03/2020  Robert Hansen removed JobID from join between InputMeasurevw
                 :              and InputMeasureCEDARS, used for retrieving MeasImpactType
                 :  11/19/2020  Robert Hansen fixed error in program-level summations in the
                 :              in-memory table "BenefitsSum" introduced when the threshold
                 :              logic applied to each measure which was removed in 07/23/2020
                 :              due to similar logic in ElecBen and GasBen calculations, but
                 :              again became necessary when "FuelSub" tag check was added in
                 :              08/03/2020.
                 :  12/18/2020  Robert Hansen added ISNULL() wrappers to benefits fields in
                 :              WeightedBenefits calculation; replaced erroneous "OR" with
                 :              "AND" in ElecBenGross calculation.
                 :  04/26/2021  Robert Hansen implemented second impact profile for additional
                 :              load associated with fuel substitution measures, used to
                 :              calculate 'negative savings' as new cost.
                 :  05/14/2021  Robert Hansen implemented the following corrections to code errors:
                 :				   + Removed (1+MEBens) from Gross Benefits Calculations
                 :				   + Applied IRkW and RRkW to Demand Savings where
                 :					 missing or where IRkWh and RRkWh are used improperly
                 :				   + Removed Rqf terms from benefits calculations
                 :                  as net-present conversions occur in JOIN sub-queries
                 :				   + Moved ISNULL() functions inside SUM() aggregators
                 :  05/17/2021  Robert Hansen incorporated the following new benefits and
                 :              costs fields in test calculations:
                 :                + UnitGasInfraBens,
                 :                + UnitRefrigCosts,
                 :                + UnitRefrigBens,
                 :                + UnitMiscCosts,
                 :                + MiscCostsDesc,
                 :                + UnitMiscBens,
                 :                + MiscBensDesc,
                 :  05/25/2021  Robert Hansen removed references to MEBens and
                 :              MECost fields from calculations, applying only
				 :              procedure parameters @MEBens and @MECosts.
                 :  05/28/2021  Robert Hansen renamed "NegBens" to "SupplyCost" and added
                 :              Total System Benefits calculations
                 :  06/16/2021  Robert Hansen commented out new fields for fuel
                 :              substitution for implementation at a later date
				 :  07/08/2021  Robert Hansen renamed "TotalSystemBenefits" to
				 :              "TotalSystemBenefit" and included Refrigerant
				 :              Costs in Total System Benefits calculation.
				 :  07/09/2021  Robert Hansen applied net-to-gross to
				 :              new benefits and costs in cost effectiveness
				 :              and total system benefit calculations.
				 :  07/14/2021  Robert Hansen fixed errors in total system
				 :              benefit calculations and program savings
				 :              weighting factors
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
    ElecBenGross FLOAT NULL,
    GasBenGross FLOAT NULL,
	OtherBen FLOAT NULL,
	OtherBenGross FLOAT NULL,
    ElecSupplyCost FLOAT NULL,
    GasSupplyCost FLOAT NULL,
    ElecSupplyCostGross FLOAT NULL,
    GasSupplyCostGross FLOAT NULL,
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
        ,ElecBenGross
        ,GasBenGross
		,OtherBen
		,OtherBenGross
        ,ElecSupplyCost
        ,GasSupplyCost
        ,ElecSupplyCostGross
        ,GasSupplyCostGross
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
				WHEN e.MeasImpactType NOT LIKE '%FuelSub' OR e.kWh1>0
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
							( e.NTGRkw + @MEBens ) *
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
				WHEN e.MeasImpactType NOT LIKE '%FuelSub' OR e.Thm1>0
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
--- ElecBenGross (Lifecycle) ---------------------------------------------------
--- PVBen[E]: Present value gross electricity benefits
        ,SUM(
			CASE
				WHEN e.MeasImpactType NOT LIKE '%FuelSub' OR e.kWh1>0
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
				WHEN e.MeasImpactType NOT LIKE '%FuelSub' OR e.Thm1>0
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
--- OtherBen -------------------------------------------------------------------
--- Naive benefits based on user-input present values:
		,SUM(
			e.Qty *
			(NTGRkWh + @MEBens) *
			(
				ISNULL( UnitGasInfraBens, 0 ) +
				ISNULL( UnitRefrigBens, 0 ) +
				ISNULL( UnitMiscBens, 0 )
			)
		) AS OtherBen
		,SUM(
			e.Qty *
			(
				ISNULL( UnitGasInfraBens, 0 ) +
				ISNULL( UnitRefrigBens, 0 ) +
				ISNULL( UnitMiscBens, 0 )
			)
		) AS OtherBenGross
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--- ADDED THE FOLLOWING 4 FIELDS TO PROVIDE NEGATIVE BENEFITS TO TRC AND PAC ---
--- ElecSupplyCost (Net Lifecycle) ---------------------------------------------
        ,SUM(
			CASE
				WHEN e.MeasImpactType LIKE '%FuelSub' AND e.kWh1<0
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
				WHEN e.MeasImpactType LIKE '%FuelSub' AND e.Thm1<0
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
--- ElecSupplyCostGross (Lifecycle) --------------------------------------------
        ,SUM(
			CASE
				WHEN e.MeasImpactType LIKE '%FuelSub' AND e.kWh1<0
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
				WHEN e.MeasImpactType LIKE '%FuelSub' AND e.Thm1<0
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
--- OtherCost ------------------------------------------------------------------
--- Naive costs based on user-input present values:
		,SUM(
			e.Qty *
			(e.NTGRkWh + @MECost) *
			(
				ISNULL( e.UnitRefrigCosts, 0 ) +
				ISNULL( e.UnitMiscCosts, 0 )
			)
		) AS OtherCost
		,SUM(
			e.Qty *
			(
				ISNULL( e.UnitRefrigCosts, 0 ) +
				ISNULL( e.UnitMiscCosts, 0 )
			)
		) AS OtherCostGross

--------------------------------------------------------------------------------

    FROM InputMeasurevw AS e
    LEFT JOIN (SELECT CEInputID, JobID, MeasImpactType FROM InputMeasureCEDARS) AS ec ON e.CET_ID = ec.CEInputID
    LEFT JOIN Settingsvw AS s
    ON e.PA = s.PA AND s.[Version] = @AVCVersion

    --***************************** ELECTRIC  *************************************
    LEFT JOIN (
		SELECT
			CET_ID
			,SUM(Gen) AS Gen
			--,SUM(Gen_AL) AS Gen_AL
			,SUM(TD) AS TD
			--,SUM(TD_AL) AS TD_AL
			,DS
			--,DS_AL
		FROM (
    -- Get Generation (Gen) and Transmission & Distribution (TD) avoided costs, demand scalar (DS)
			SELECT
				CET_ID
				,ISNULL( Gen / POWER( Rqf, Qac ), 0 ) AS Gen
				--,ISNULL( Gen_AL / POWER( Rqf, Qac ), 0 ) AS Gen_AL
				,ISNULL( TD / POWER( Rqf, Qac ), 0 ) AS TD
				--,ISNULL( TD_AL / POWER( Rqf, Qac ), 0 ) AS TD_AL
				,ISNULL( DS1, 0 ) AS DS
				--,ISNULL( DS1_AL, 0 ) AS DS_AL
			FROM AvoidedCostElecvw
			WHERE Qac BETWEEN Qm AND Qm + CONVERT( INT, eulq1 ) - 1

	-- Get fractional generation (Genfrac) and transmission & Distribution (TDfrac) avoided costs. Fractions are effective useful lives (eul) for fractions of a quarter. Fist Baseline fraction
			UNION SELECT
				CET_ID
				,( eulq1 - FLOOR( eulq1 ) ) * (Gen / POWER( Rqf, Qac ) ) AS Gen
				--,( eulq1 - FLOOR( eulq1 ) ) * (Gen_AL / POWER( Rqf, Qac ) ) AS Gen_AL
				,( eulq1 - FLOOR( eulq1 ) ) * (TD / POWER( Rqf, Qac ) ) AS TD
				--,( eulq1 - FLOOR( eulq1 ) ) * (TD_AL / POWER( Rqf, Qac ) ) AS TD_AL
				,DS1 AS DS
				--,DS1_AL AS DS_AL
			FROM AvoidedCostElecvw
			WHERE Qac = Qm + CONVERT( INT, eulq1 )
		)
		AS A GROUP BY CET_ID, DS/*, DS_AL*/
	) AS ace_1 ON e.CET_ID=ace_1.CET_ID

	LEFT JOIN (
		SELECT
			CET_ID
			,SUM(Gen) AS Gen
			--,SUM(Gen_AL) AS Gen_AL
			,SUM(TD) AS TD
			--,SUM(TD_AL) AS TD_AL
			,DS
			--,DS_AL
		FROM (
    -- Get fractional generation (Genfrac) and transmission & Distribution (TDfrac) avoided costs. Second baseline fraction.
			SELECT
				CET_ID
				,CASE
					WHEN eulq2 > 0 AND ( eulq1 - FLOOR( eulq1 ) ) > 0
					THEN ( 1 - ( eulq1 - FLOOR( eulq1 ) ) ) * ( Gen / POWER( Rqf, Qac ) )
					ELSE 0
				END AS Gen
				--,CASE
				--	WHEN eulq2 > 0 AND ( eulq1 - FLOOR( eulq1 ) ) > 0
				--	THEN ( 1 - ( eulq1 - FLOOR( eulq1 ) ) ) * ( Gen_AL / POWER( Rqf, Qac ) )
				--	ELSE 0
				--END AS Gen_AL
				,CASE
					WHEN eulq2 > 0 AND ( eulq1 - FLOOR( eulq1 ) ) > 0
					THEN ( 1 - ( eulq1 - FLOOR( eulq1 ) ) ) * ( TD / POWER( Rqf, Qac ) )
					ELSE 0
				END AS TD
				--,CASE
				--	WHEN eulq2 > 0 AND ( eulq1 - FLOOR( eulq1 ) ) > 0
				--	THEN ( 1 - ( eulq1 - FLOOR( eulq1 ) ) ) * ( TD_AL / POWER( Rqf, Qac ) )
				--	ELSE 0
				--END AS TD_AL
				,ISNULL( DS2, 0 ) AS DS
				--,ISNULL( DS2_AL, 0 ) AS DS_AL
			FROM AvoidedCostElecvw
			WHERE Qac = Qm + CONVERT( INT, eulq1 )

    ---- Get Elec avoided costs (Elecfrac) - Second baseline
			UNION SELECT
				CET_ID
				,ISNULL( Gen / POWER( Rqf, Qac ), 0 ) AS Gen
				--,ISNULL( Gen_AL / POWER( Rqf, Qac ), 0 ) AS Gen_AL
				,ISNULL( TD / POWER( Rqf, Qac ), 0 ) AS TD
				--,ISNULL( TD_AL / POWER( Rqf, Qac ), 0 ) AS TD_AL
				,ISNULL( DS2, 0 ) AS DS
				--,ISNULL( DS2_AL, 0 ) AS DS_AL
			FROM AvoidedCostElecvw
			WHERE Qac BETWEEN Qm + eulq1 AND Qm + eulq2 - 1

    -- Get fractional generation (Genfrac) and transmission & Distribution (TDfrac) avoided costs. Fractions are effective useful lives (eul) for fractions of a quarter
			UNION SELECT
				CET_ID
				,( eulq2 - ROUND( eulq2, 0, 1 ) ) * ( Gen / POWER( Rqf, Qac ) ) AS Gen
				--,( eulq2 - ROUND( eulq2, 0, 1 ) ) * ( Gen_AL / POWER( Rqf, Qac ) ) AS Gen_AL
				,( eulq2 - ROUND( eulq2, 0, 1 ) ) * ( TD / POWER( Rqf, Qac ) ) AS TD
				--,( eulq2 - ROUND( eulq2, 0, 1 ) ) * ( TD_AL / POWER( Rqf, Qac ) ) AS TD_AL
				,ISNULL( DS2, 0 ) AS DS
				--,ISNULL( DS2_AL, 0 ) AS DS_AL
			FROM AvoidedCostElecvw
			WHERE Qac = Qm + CONVERT( INT, eulq2 )
		) AS A GROUP BY CET_ID, DS/*, DS_AL*/
	) AS ace_2
    ON e.CET_ID = ace_2.CET_ID

    --***************************** GAS  *************************************
    LEFT JOIN (
		SELECT
			CET_ID
			,SUM(Gas) AS Gas
			--,SUM(Gas_AL) AS Gas_AL
		FROM (
    -- Get Gas avoided costs
			SELECT
				CET_ID
				,ISNULL( Cost / POWER( Rqf, Qac ), 0 ) AS Gas
				--,ISNULL( Cost_AL / POWER( Rqf, Qac ), 0 ) AS Gas_AL
			FROM AvoidedCostGasvw
			WHERE Qac BETWEEN Qm AND Qm + CONVERT( INT, eulq1 ) - 1

    -- Get fractional Gas avoided costs (Gasfrac). Fractions are effective useful lives (eul) for fractions of a quarter. First Baseline fraction
		UNION SELECT
            CET_ID
            ,( eulq1 - FLOOR( eulq1 ) ) * ( Cost / POWER( Rqf, Qac ) ) AS Gasfrac1
            --,( eulq1 - FLOOR( eulq1 ) ) * ( Cost_AL / POWER( Rqf, Qac ) ) AS Gasfrac1_AL
        FROM AvoidedCostGasvw
        WHERE Qac = Qm + CONVERT( INT, eulq1 )
		) AS A GROUP BY CET_ID
	) AS acg_1 ON e.CET_ID = acg_1.CET_ID

    -- Get fractional Gas avoided costs (Gasfrac) - Second baseline
    LEFT JOIN (
		SELECT
			CET_ID,
			SUM(Gas) AS Gas--,
			--SUM(Gas_AL) AS Gas_AL
		FROM (
			SELECT
				CET_ID
				,CASE
					WHEN ( eulq1 - FLOOR( eulq1 ) ) > 0
					THEN ( 1 - ( eulq1 - FLOOR( eulq1 ) ) ) * ( Cost / POWER( Rqf, Qac ) )
					ELSE 0
				END AS Gas
				--,CASE
				--	WHEN ( eulq1 - FLOOR( eulq1 ) ) > 0
				--	THEN ( 1 - ( eulq1 - FLOOR( eulq1 ) ) ) * ( Cost_AL / POWER( Rqf, Qac ) )
				--	ELSE 0
				--END AS Gas_AL
			FROM AvoidedCostGasvw
			WHERE Qac = Qm + CONVERT( INT, eulq1 )

    -- Get Gas avoided costs, and NTGRTherms - Second baseline
			UNION SELECT
				CET_ID
				,ISNULL( Cost / POWER( Rqf, Qac ), 0 ) AS Gas
				--,ISNULL( Cost_AL / POWER( Rqf, Qac ), 0 ) AS Gas_AL
			FROM AvoidedCostGasvw
			WHERE Qac BETWEEN Qm + CONVERT( INT, eulq1 ) + 1 AND Qm + CONVERT( INT, eulq2 ) - 1 

    -- Get fractional Gas avoided costs (Gasfrac)
			UNION SELECT
				CET_ID
				,( eulq2 - FLOOR( eulq2 ) ) * ( Cost / POWER( Rqf, Qac ) ) AS Gas
				--,( eulq2 - FLOOR( eulq2 ) ) * ( Cost_AL / POWER( Rqf, Qac ) ) AS Gas_AL
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
		ElecBenGross = ISNULL( ElecBenGross, 0 ),
		GasBenGross = ISNULL( GasBenGross, 0 ),
		ElecSupplyCost = ISNULL( ElecSupplyCost, 0 ),
		GasSupplyCost = ISNULL( GasSupplyCost, 0 ),
		ElecSupplyCostGross = ISNULL( ElecSupplyCostGross, 0 ),
		GasSupplyCostGross = ISNULL( GasSupplyCost, 0 )
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
	,SumOtherBen
    ,SumElecBenGross
    ,SumGasBenGross
	,SumOtherBenGross
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
    FROM #OutputCE
    GROUP BY PrgID
)
, BenPos (
    CET_ID
    ,ElecBenPos
    ,GasBenPos
	,OtherBenPos
    ,SumBenPos
)
AS
(
    SELECT
		CET_ID
        ,CASE WHEN ISNULL(ElecBen,0) > 0 THEN ElecBen ELSE 0 END AS ElecBenPos
        ,CASE WHEN ISNULL(GasBen,0) > 0 THEN GasBen ELSE 0 END AS GasBenPos
		,CASE WHEN ISNULL(OtherBen,0) > 0 THEN OtherBen ELSE 0 END AS OtherBenPos
        ,CASE WHEN ISNULL(ElecBen,0) > 0 THEN ElecBen ELSE 0 END +
		  CASE WHEN ISNULL(GasBen,0) > 0 THEN GasBen ELSE 0 END +
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
        , @MECost * ((ri.GrossMeasCostPV) + (ex.ExcessIncentivesPV)) AS MarkEffectPlusExcessIncPV
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
        , ri.NTGRCost * (gma.GrossMeasureCostAdjustedPV) + (@MECost * (ri.GrossMeasCostPV + ex.ExcessIncentivesPV)) AS ParticipantCost
        , (ri.NTGRCost * (gma.GrossMeasureCostAdjustedPV) + (@MECost * (ri.GrossMeasCostPV + ex.ExcessIncentivesPV))) / POWER(s.Rqf, Qm) AS ParticipantCostPV
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
	, TotalSystemBenefit
	, TotalSystemBenefitGross
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
			ElecBen +
			GasBen +
			ec.Qty * (ec.NTGRkWh + @MEBens) * ISNULL(ec.UnitRefrigBens,0)
		) - (
			ElecSupplyCost +
			GasSupplyCost +
			ec.Qty * (ec.NTGRkWh + @MECost) * ISNULL(ec.UnitRefrigCosts,0)
		) AS TotalSystemBenefit
		, (
			ElecBenGross +
			GasBenGross +
			ec.Qty * ISNULL(ec.UnitRefrigBens,0)
		) - (
			ElecSupplyCostGross +
			GasSupplyCostGross +
			ec.Qty * ISNULL(ec.UnitRefrigCosts,0)
		) AS TotalSystemBenefitGross
        , (
            CASE
                WHEN (SumElecBen + SumGasBen + OtherBen <> 0)
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
                            WHEN ISNULL(OtherBen,0) > 0
                            THEN OtherBen
                            ELSE 0
                        END
                    ) / ( SumElecBen + SumGasBen + SumOtherBen )
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
            -- Increased supply costs, refrigerant costs, and miscellaneous costs
           CE.ElecSupplyCost +
           CE.GasSupplyCost +
           CE.OtherCost
        ) AS PAC_Cost
        , (
            e.Qty *
            (
                e.IncentiveToOthers +
                e.DILaborCost +
                e.DIMaterialCost +
                e.EndUserRebate
            ) / POWER(s.Rqf, e.Qm) +
            -- Increased supply costs, refrigerant costs, and miscellaneous costs
            CE.ElecSupplyCost +
            CE.GasSupplyCost +
			CE.OtherCost
        ) AS PAC_Cost_NoAdmin
        , (
            CASE 
                WHEN (BensSum.SumElecBen + BensSum.SumGasBen + BensSum.SumOtherBen) <> 0
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
                            WHEN ISNULL(CE.OtherBen,0) > 0
                            THEN OtherBen
                            ELSE 0
                        END
                    ) / (BensSum.SumElecBen + BensSum.SumGasBen + BensSum.SumOtherBen)
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
            -- Increased supply costs, refrigerant costs, and miscellaneous costs
            CE.ElecSupplyCost +
            CE.GasSupplyCost +
			CE.OtherCost
        ) AS TRC_Cost
        , (
            CASE 
                WHEN (SumElecBenGross + SumGasBenGross + SumOtherBenGross) <> 0
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
							WHEN ISNULL(OtherBenGross,0) > 0
							THEN OtherBenGross
							ELSE 0
						END
                    ) / (SumElecBenGross + SumGasBenGross + SumOtherBenGross)
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
            -- Increased supply costs, refrigerant costs, and miscellaneous costs
            CE.ElecSupplyCost +
            CE.GasSupplyCost +
			CE.OtherCostGross
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
            -- Increased supply costs, refrigerant costs, and miscellaneous costs
            CE.ElecSupplyCost +
            CE.GasSupplyCost +
			CE.OtherCost
        ) AS TRC_Cost_NoAdmin
        ,CASE
            WHEN (SumElecBen + SumGasBen + SumOtherBen) <> 0
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
					WHEN ISNULL(OtherBen,0) > 0
					THEN OtherBen
					ELSE 0
				END
            ) / (SumElecBen + SumGasBen + SumOtherBen)
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
                WHEN SumElecBen + SumGasBen + SumOtherBen <> 0
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
						WHEN ISNULL(OtherBen,0) > 0
						THEN OtherBen
						ELSE 0
					END
					) / (SumElecBen + SumGasBen + SumOtherBen)
				ELSE 1.000 / cc.ClaimCount -- If no benefits then divide program costs evenly among claims
            END * 
            ISNULL(pcSum.SumCosts,0)
        ) AS WeightedProgramCost
        ,e.NTGRCost
        ,pc.ExcessIncentives
        ,pc.GrossMeasureCostAdjusted
        ,pc.ParticipantCost
        ,pc.ParticipantCostPV
        ,pc.GrossParticipantCostPV
        ,pc.NetParticipantCostPV
    FROM #OutputCE CE
    LEFT JOIN InputMeasurevw AS ec ON CE.CET_ID = ec.CET_ID
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
                THEN (ElecBen + GasBen + OtherBen) / (TRCCost)
                ELSE 0
            END
        ,PACRatio =
            CASE 
                WHEN PACCost <> 0
                THEN (ElecBen + GasBen + OtherBen) / (PACCost)
                ELSE 0
            END
        ,TRCRatioNoAdmin =
            CASE 
                WHEN TRCCostNoAdmin <> 0
                THEN (ElecBen + GasBen + OtherBen) / (TRCCostNoAdmin)
                ELSE 0
            END
        ,PACRatioNoAdmin =
            CASE 
                WHEN PACCostNoAdmin <> 0
                THEN (ElecBen + GasBen + OtherBen) / (PACCostNoAdmin)
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
      ,ElecBenGross
      ,GasBenGross
	  ,OtherBen
	  ,OtherBenGross
	  ,ElecSupplyCost
      ,GasSupplyCost
      ,ElecSupplyCostGross
      ,GasSupplyCostGross
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

DROP TABLE [#OutputCE]

--PRINT 'Done!'

GO