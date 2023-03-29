--USE EDStaff_CET_2020
--GO

/****** Object:  StoredProcedure [dbo].[CalcEmissions]    Script Date: 12/16/2019 1:14:00 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


--#################################################################################################
-- Name             :  CalcEmissions
-- Date             :  06/30/2016
-- Author           :  Wayne Hauck
-- Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
-- Purpose          :  This stored procedure calculates emissions outputs.
-- Usage            :  n/a
-- Called by        :  n/a
-- Copyright (c)    :  Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
-- Change History   :  06/30/2016  Wayne Hauck added comment header
--                  :  12/31/2019  Robert Hansen reformatted and added comments to code
--                  :  01/02/2020  Robert Hansen rewrote to update calculations
--                  :  01/03/2020  Robert Hansen identified and corrected errors in rewritten code
--                  :  01/08/2020  Robert Hansen removed #tmp table use and replaced with direct queries
--                  :  02/03/2020  Robert Hansen applied future-quarterly emissions calculations
--                     
--#################################################################################################

-------------------------------------------------------------------------------

IF NOT EXISTS ( SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID( 'dbo.CalcEmissions' ) )
   EXEC( 'CREATE PROCEDURE [dbo].[CalcEmissions] AS BEGIN SET NOCOUNT ON; END' )
GO

ALTER PROCEDURE [dbo].[CalcEmissions]
@JobID INT = -1,
@MEBens FLOAT = NULL, -- market effects benefits
@AVCVersion VARCHAR(255)

AS

SET NOCOUNT ON

--Clear Output
DELETE FROM OutputEmissions WHERE JobID = @JobID
DELETE FROM SavedEmissions WHERE JobID = @JobID

-- If no Market Effects is passed, check the Jobs table
IF @MEBens IS NULL
    BEGIN
        SET @MEBens = ISNULL( ( SELECT MarketEffectBens FROM CETJobs WHERE ID = @JobID ), 0 )
    END
PRINT 'Inserting electrical and gas emissions...'

-------------------------------------------------------------------------------
DECLARE @QuarterlyElecEmissions TABLE (
    JobID INT NULL,
    CET_ID NVARCHAR(255) NOT NULL,
    EmissionsQtr NVARCHAR(6),
    SeqQtr INT NOT NULL,
    QuarterlyNetElecCO2 FLOAT NULL,
    QuarterlyGrossElecCO2 FLOAT NULL,
    QuarterlyNetElecNOx FLOAT NULL,
    QuarterlyGrossElecNOx FLOAT NULL,
    QuarterlyNetPM10 FLOAT NULL,
    QuarterlyGrossPM10 FLOAT NULL
)

INSERT INTO @QuarterlyElecEmissions
    SELECT
        JobID
        ,CET_ID
        ,EmissionsQtr
        ,SeqQtr
--- QuarterlyNetElecCO2 --------------------------------------------------------
        ,ISNULL(
            Qty *
            ( NTGRkWh + COALESCE( MEBens, @MEBens ) ) *
            IRkWh *
            RRkWh *
            --- CO2 Emissions Rate ( tons CO2 per Annual kWh Savings ):
            CO2 *
            --- Applicable annual electric savings rate for each quarter:
            AnnualkWh,
            0
        ) as QuarterlyNetElecCO2
-------------------------------------------------------------------------------
--- QuarterlyGrossElecCO2 -----------------------------------------------------
        ,ISNULL(
            Qty *
            IRkWh *
            RRkWh *
            --- CO2 Emissions Rate ( lbs CO2 per Annual kWh Savings ):
            CO2 *
            --- Applicable annual electric savings rate for each quarter:
            AnnualkWh,
            0
        ) as QuarterlyGrossElecCO2
-------------------------------------------------------------------------------
--- QuarterlyNetElecNOx -------------------------------------------------------
        ,ISNULL(
            Qty *
            ( NTGRkWh + COALESCE( MEBens, @MEBens ) ) *
            IRkWh *
            RRkWh *
            --- NOx Emissions Rate ( lbs NOx per Annual kWh Savings ):
            NOx *
            --- Applicable quarterly (different from CO2 per Brent Bolii @ E3) electric savings rate for each quarter:
            AnnualkWh / 4, -- Divide annual savings by four to convert to quarterly
            0
        ) as QuarterlyNetElecNOx
-------------------------------------------------------------------------------
--- QuarterlyGrossElecNOx -----------------------------------------------------
        ,ISNULL(
            Qty *
            IRkWh *
            RRkWh *
            --- NOx Emissions Rate ( lbs NOx per Annual kWh Savings ):
            NOx *
            --- Applicable quarterly (different from CO2 per Brent Bolii @ E3) electric savings rate for each quarter:
            AnnualkWh / 4, -- Divide annual savings by four to convert to quarterly
            0
        ) as QuarterlyGrossElecNOx
-------------------------------------------------------------------------------
--- QuarterlyNetPM10 ----------------------------------------------------------
        --- This calculates PM10 savings accounting for electric savings only.
        ,ISNULL(
            Qty *
            ( NTGRkWh + COALESCE( MEBens, @MEBens ) ) *
            IRkWh *
            RRkWh *
            --- 10-Micron Particulate Matter Emissions Rate ( lbs PM10 per Annual kWh Savings ):
            PM10 *
            --- Applicable quarterly (different from CO2 per Brent Bolii @ E3) electric savings rate for each quarter:
            AnnualkWh / 4, -- Divide annual savings by four to convert to quarterly
            0
        ) as QuarterlyNetPM10
-------------------------------------------------------------------------------
--- QuarterlyGrossPM10 --------------------------------------------------------
        --- This calculates PM10 savings accounting for electric savings only.
        ,ISNULL(
            Qty *
            IRkWh *
            RRkWh *
            --- 10-Micron Particulate Matter Emissions Rate ( lbs PM10 per Annual kWh Savings ):
            PM10 *
            --- Applicable quarterly (different from CO2 per Brent Bolii @ E3) electric savings rate for each quarter:
            AnnualkWh / 4, -- Divide annual savings by four to convert to quarterly
            0
        ) as QuarterlyGrossPM10
    FROM (
-------------------------------------------------------------------------------
        SELECT
            @JobID AS JobID
            ,e.CET_ID AS CET_ID
            ,em.Qtr AS EmissionsQtr
            ,LEFT( e.Qtr, 4 ) * 4 + RIGHT( e.Qtr, 1 ) AS InstallQtr
            --- Create a quarter number based on installation quarter through EUL:
            ,ROW_NUMBER() OVER (PARTITION BY e.CET_ID ORDER BY em.Qtr ASC) AS SeqQtr
            ,e.Qty AS Qty
            ,e.NTGRkWh AS NTGRkWh
            ,e.MEBens AS MEBens
            ,e.IRkWh AS IRkWh
            ,e.RRkWh AS RRkWh
            ,CASE
                --- Zero RUL, i.e., single baseline measure:
                WHEN ISNULL(e.RULq,0) = 0
                THEN
                    CASE
                        --- Quarter split between EUL and Post-EUL periods -- interpolate between baseline annual savings rate and zero:
                        WHEN
                            e.Qidx + e.EULq > em.Qidx AND e.Qidx + e.EULq < em.Qidx + 1
                        THEN e.kWh1 * ( CONVERT( DECIMAL( 13, 10 ), e.EULq ) % 1 )
                        --- Quarter fully within EUL
                        ELSE e.kWh1
                    END
                --- Non-Zero RUL, i.e., dual baseline measure (assume EUL>RUL):
                ELSE
                    CASE
                        --- Quarter fully within RUL -- apply first baseline annual savings rate:
                        WHEN e.Qidx + e.RULq > em.Qidx + 1
                        THEN e.kWh1
                        --- Quarter fully post-RUL and within EUL -- apply second baseline annual savings rate:
                        WHEN e.Qidx + e.RULq < em.Qidx AND e.Qidx + e.EULq > em.Qidx + 1
                        THEN e.kWh2
                        --- Quarter contains both EUL and RUL -- weight annual savings rates by time in both baselines and zero savings after:
                        WHEN
                            e.Qidx + e.RULq > em.Qidx
                        AND
                            e.Qidx + e.RULq < em.Qidx + 1
                        AND
                            e.Qidx + e.EULq > em.Qidx
                        AND
                            e.Qidx + e.EULq < em.Qidx + 1
                        THEN e.kWh1 * ( CONVERT( DECIMAL( 13, 10 ), e.RULq ) % 1 ) + e.kWh2 * ( e.EULq - e.RULq )
                        --- Quarter contains RUL -- weight annual savings rates by time in either baselines:
                        WHEN e.Qidx + e.RULq > em.Qidx AND e.Qidx + e.RULq < em.Qidx + 1
                        THEN e.kWh1 * ( CONVERT( DECIMAL( 13, 10 ), e.RULq ) % 1 ) + e.kWh2 * ( 1 - CONVERT( DECIMAL( 13, 10 ), e.RULq ) % 1 )
                        --- Quarter contains EUL -- weight annual savings by time in second baseline and zero savings after:
                        WHEN e.Qidx + e.EULq > em.Qidx AND e.Qidx + e.EULq < em.Qidx + 1
                        THEN e.kWh2 *  ( ( e.EULq ) - FLOOR( e.EULq ) )
                        --- Quarter fully post-RUL and pre-EUL -- apply second baseline annual savings rate:
                        ELSE e.kWh2
                    END
            END AS AnnualkWh
            ,e.RULq AS RULq
            ,e.EULq AS EULq
            ,em.CO2 AS CO2
            ,em.NOx AS NOx
            ,em.PM10 AS PM10
        FROM (
            SELECT
                CET_ID
                ,JobID
                ,PA
                ,TS
                ,EU
                ,CZ
                ,Qtr
                ,LEFT(Qtr,4) * 4 + RIGHT(Qtr,1) AS Qidx
                ,Qty
                ,kWh1
                ,kWh2
                ,EULq
                ,RULq
                ,NTGRkWh
                ,MEBens
                ,IRkWh
                ,RRkWh

            FROM InputMeasurevw 
        ) AS e
        LEFT JOIN
            Settingsvw AS s
            ON
                e.PA = s.PA
        --- Join all Emissions table quarters within each measure's EUL:
        LEFT JOIN (
                SELECT
                    PA
                    ,TS
                    ,EU
                    ,CZ
                    ,Version
                    ,Qtr
                    ,LEFT(Qtr,4) * 4 + RIGHT(Qtr,1) AS Qidx
                    ,CO2
                    ,NOx
                    ,PM10
                FROM E3EmissionsSourcevw
            ) AS em
            ON
                s.Version = em.Version
            AND
                e.PA + e.TS + e.EU + RTRIM(e.CZ) =
                em.PA +
                CASE
                    WHEN em.EU LIKE 'Non_res:DEER%'
                    THEN 'Non_res'
                    ELSE
                        CASE
                            WHEN em.EU LIKE 'res:DEER%'
                            THEN 'Res'
                            ELSE em.TS
                        END
                END +
                CASE
                    WHEN em.EU LIKE 'Non_res:DEER%'
                    THEN REPLACE( em.EU, 'Non_Res:', '' )
                    ELSE
                        CASE
                            WHEN em.EU LIKE 'res:DEER%'
                            THEN REPLACE( em.EU, 'res:', '' )
                            ELSE em.EU
                        END
                END +
                em.CZ
            AND
                --- Quarterly records in emissions table in or after measure installation:
                em.Qidx >= e.Qidx
            AND
                --- Quarterly records in emissions table before measure installation + EUL:
                em.Qidx < e.Qidx + e.EULq
        WHERE
            e.CET_ID IS NOT NULL
        AND
            s.Version = @AVCVersion
    ) AS e
    ORDER BY
        e.CET_ID
        ,SeqQtr

INSERT INTO OutputEmissions
    SELECT
        @JobID AS JobID,
        e.PA AS PA,
        e.PrgID AS PrgID,
        e.CET_ID AS CET_ID,
        FirstYearElecEmissions.NetElecCO2 AS NetElecCO2,
        ISNULL(
            e.Qty *
            ( e.NTGRThm + COALESCE( e.MEBens, @MEBens ) ) *
            e.IRThm *
            e.RRThm *
            --- CO2 savings conversion factor (Therms --> lbs CO2eq):
            s.CO2Gas *
            --- First year natural gas savings:
            CASE
                --- Non-zero RUL, i.e., dual baseline measure:
                WHEN ISNULL( e.RULq, 0 ) > 0
                THEN
                    CASE
                        --- First year fully within RUL:
                        WHEN e.RUL >= 1
                        THEN e.Thm1
                        --- Full first year split before and after RUL:
                        WHEN e.RUL < 1 AND e.EUL >= 1
                        THEN e.RUL * e.Thm1 + ( 1 - e.RUL ) * e.Thm2
                        --- Both RUL and EUL within first year:
                        ELSE e.RUL * e.Thm1 + ( e.EUL - e.RUL ) * e.Thm2
                    END
                --- No RUL, i.e., single baseline measure:
                WHEN EUL > 0
                THEN
                    CASE
                        --- First year fully within EUL:
                        WHEN e.EUL > 1
                        THEN e.Thm1
                        --- EUL less than 1 year:
                        ELSE e.EUL * e.Thm1
                    END
                --- Failsafe condition (disallow negative EUL):
                ELSE 0
            END,
            0
        ) as NetGasCO2,
        FirstYearElecEmissions.GrossElecCO2 AS GrossElecCO2,
        ISNULL(
            e.Qty *
            e.IRThm *
            e.RRThm *
            --- CO2 savings conversion factor (Therms --> lbs CO2eq):
            s.CO2Gas *
            --- First year natural gas savings:
            CASE
                --- Non-zero RUL, i.e., dual baseline measure:
                WHEN ISNULL( e.RUL, 0 ) > 0
                THEN
                    CASE
                        --- First year fully within RUL:
                        WHEN e.RUL >= 1
                        THEN e.Thm1
                        --- Full first year split before and after RUL:
                        WHEN e.RUL < 1 AND e.EUL >= 1
                        THEN e.RUL * e.Thm1 + ( 1 - e.RUL ) * e.Thm2
                        --- Both RUL and EUL within first year:
                        ELSE e.RUL * e.Thm1 + ( e.EUL - e.RUL ) * e.Thm2
                    END
                --- No RUL, i.e., single baseline measure:
                WHEN EUL > 0
                THEN
                    CASE
                        --- First year fully within EUL:
                        WHEN e.EUL > 1
                        THEN e.Thm1
                        --- EUL less than 1 year:
                        ELSE e.EUL * e.Thm1
                    END
                --- Failsafe condition (disallow negative EUL):
                ELSE 0
            END,
            0
        ) as GrossGasCO2,
        LifecycleElecEmissions.NetElecCO2 AS NetElecCO2Lifecycle,
        ISNULL(
            e.Qty *
            ( e.NTGRThm + COALESCE( e.MEBens, @MEBens ) ) *
            e.IRThm *
            e.RRThm *
            --- CO2 savings conversion factor (Therms --> lbs CO2eq):
            s.CO2Gas *
            --- Lifecycle natural gas savings:
            CASE
                --- Non-zero RUL, i.e., Accelerated Replacement:
                WHEN ISNULL( e.RUL, 0 ) > 0
                THEN e.RUL * e.Thm1 + ( e.EUL - e.RUL) * e.Thm2
                --- No RUL, i.e., Replace-on-Burnout:
                WHEN e.EUL > 0
                THEN e.EUL * e.Thm1
                --- Failsafe condition (disallow negative EUL and EUL < RUL):
                ELSE 0
            END,
            0
        ) as NetGasCO2Lifecycle,
        LifecycleElecEmissions.GrossElecCO2 AS GrossElecCO2Lifecycle,
        ISNULL(
            e.Qty *
            e.IRThm *
            e.RRThm *
            --- CO2 savings conversion factor (Therms --> lbs CO2eq):
            s.CO2Gas *
            --- Lifecycle natural gas savings:
            CASE
                --- Non-zero RUL, i.e., Accelerated Replacement:
                WHEN ISNULL( e.RUL, 0 ) > 0
                THEN e.RUL * e.Thm1 + ( e.EUL - e.RUL) * e.Thm2
                --- No RUL, i.e., Replace-on-Burnout:
                WHEN e.EUL > 0
                THEN e.EUL * e.Thm1
                --- Failsafe condition (disallow negative EUL and EUL < RUL):
                ELSE 0
            END,
            0
        ) as GrossGasCO2Lifecycle,
        FirstYearElecEmissions.NetElecNOx AS NetElecNOx,
        ISNULL(
            e.Qty *
            ( e.NTGRThm + COALESCE( e.MEBens, @MEBens ) ) *
            e.IRThm *
            e.RRThm *
            --- CO2 savings conversion factor (Therms --> lbs NOx):
            eg.NOxGas *
            --- First year natural gas savings:
            CASE
                --- Non-zero RUL, i.e., dual baseline measure:
                WHEN ISNULL( e.RUL, 0 ) > 0
                THEN
                    CASE
                        --- First year fully within RUL:
                        WHEN e.RUL >= 1
                        THEN e.Thm1
                        --- Full first year split before and after RUL:
                        WHEN e.RUL < 1 AND e.EUL >= 1
                        THEN e.RUL * e.Thm1 + ( 1 - e.RUL ) * e.Thm2
                        --- Both RUL and EUL within first year:
                        ELSE e.RUL * e.Thm1 + ( e.EUL - e.RUL ) * e.Thm2
                    END
                --- No RUL, i.e., single baseline measure:
                WHEN EUL > 0
                THEN
                    CASE
                        --- First year fully within EUL:
                        WHEN e.EUL > 1
                        THEN e.Thm1
                        --- EUL less than 1 year:
                        ELSE e.EUL * e.Thm1
                    END
                --- Failsafe condition (disallow negative EUL):
                ELSE 0
            END,
            0
        ) as NetGasNOx,
        FirstYearElecEmissions.GrossElecNOx AS GrossElecNOx,
        ISNULL(
            e.Qty *
            e.IRThm *
            e.RRThm *
            --- NOx savings conversion factor (Therms --> lbs NOx):
            eg.NOxGas *
            --- First year natural gas savings:
            CASE
                --- Non-zero RUL, i.e., dual baseline measure:
                WHEN ISNULL( e.RUL, 0 ) > 0
                THEN
                    CASE
                        --- First year fully within RUL:
                        WHEN e.RUL >= 1
                        THEN e.Thm1
                        --- Full first year split before and after RUL:
                        WHEN e.RUL < 1 AND e.EUL >= 1
                        THEN e.RUL * e.Thm1 + ( 1 - e.RUL ) * e.Thm2
                        --- Both RUL and EUL within first year:
                        ELSE e.RUL * e.Thm1 + ( e.EUL - e.RUL ) * e.Thm2
                    END
                --- No RUL, i.e., single baseline measure:
                WHEN EUL > 0
                THEN
                    CASE
                        --- First year fully within EUL:
                        WHEN e.EUL > 1
                        THEN e.Thm1
                        --- EUL less than 1 year:
                        ELSE e.EUL * e.Thm1
                    END
                --- Failsafe condition (disallow negative EUL):
                ELSE 0
            END,
            0
        ) as GrossGasNOx,
        LifecycleElecEmissions.NetElecNOx AS NetElecNOxLifecycle,
        ISNULL(
            e.Qty *
            ( e.NTGRThm + COALESCE( e.MEBens, @MEBens ) ) *
            e.IRThm *
            e.RRThm *
            --- NOx savings conversion factor (Therms --> lbs NOx):
            eg.NOxGas *
            --- Lifecycle natural gas savings:
            CASE
                --- Non-zero RUL, i.e., Accelerated Replacement:
                WHEN ISNULL( e.RUL, 0 ) > 0
                THEN e.RUL * e.Thm1 + ( e.EUL - e.RUL) * e.Thm2
                --- No RUL, i.e., Replace-on-Burnout:
                WHEN e.EUL > 0
                THEN e.EUL * e.Thm1
                --- Failsafe condition (disallow negative EUL and EUL < RUL):
                ELSE 0
            END,
            0
        ) as NetGasNOxLifecycle,
        LifecycleElecEmissions.GrossElecNOx AS GrossElecNOxLifecycle,
        ISNULL(
            e.Qty *
            e.IRThm *
            e.RRThm *
            --- NOx savings conversion factor (Therms --> lbs NOx):
            eg.NOxGas *
            --- Lifecycle natural gas savings:
            CASE
                --- Non-zero RUL, i.e., Accelerated Replacement:
                WHEN ISNULL( e.RUL, 0 ) > 0
                THEN e.RUL * e.Thm1 + ( e.EUL - e.RUL) * e.Thm2
                --- No RUL, i.e., Replace-on-Burnout:
                WHEN e.EUL > 0
                THEN e.EUL * e.Thm1
                --- Failsafe condition (disallow negative EUL and EUL < RUL):
                ELSE 0
            END,
            0
        ) as GrossGasNOxLifecycle,
        FirstYearElecEmissions.NetPM10 AS NetPM10,
        FirstYearElecEmissions.GrossPM10 AS GrossPM10,
        LifecycleElecEmissions.NetPM10 AS NetPM10Lifecycle,
        LifecycleElecEmissions.GrossPM10 AS GrossPM10Lifecycle
    FROM InputMeasurevw AS e
    LEFT JOIN
        Settingsvw AS s
    ON
        e.PA = s.PA
    LEFT JOIN
        E3CombustionTypevw AS eg
    ON
        e.CET_ID = eg.CET_ID
    --- Sum electric emissions reductions for up to the first four quarters (1 year) for each input measure:
    LEFT JOIN
        (SELECT
            CET_ID,
            SUM(QuarterlyNetElecCO2) AS NetElecCO2,
            SUM(QuarterlyGrossElecCO2) AS GrossElecCO2,
            SUM(QuarterlyNetElecNOx) AS NetElecNOx,
            SUM(QuarterlyGrossElecNOx) AS GrossElecNOx,
            SUM(QuarterlyNetPM10) AS NetPM10,
            SUM(QuarterlyGrossPM10) AS GrossPM10
            FROM @QuarterlyElecEmissions
            --- Only use first four quarters for each input measure record:
            WHERE SeqQtr <= 4
            GROUP BY CET_ID
        ) AS FirstYearElecEmissions
    ON
        e.CET_ID = FirstYearElecEmissions.CET_ID
    --- Sum electric emissions reductions for all quarters across each input measure's lifecycle:
    LEFT JOIN
        (SELECT
            CET_ID,
            SUM(QuarterlyNetElecCO2) AS NetElecCO2,
            SUM(QuarterlyGrossElecCO2) AS GrossElecCO2,
            SUM(QuarterlyNetElecNOx) AS NetElecNOx,
            SUM(QuarterlyGrossElecNOx) AS GrossElecNOx,
            SUM(QuarterlyNetPM10) AS NetPM10,
            SUM(QuarterlyGrossPM10) AS GrossPM10
            FROM @QuarterlyElecEmissions
            GROUP BY CET_ID
        ) AS LifecycleElecEmissions
    ON
        e.CET_ID = LifecycleElecEmissions.CET_ID
    ORDER BY
        e.PA
        ,e.PrgID
        ,e.CET_ID
GO
