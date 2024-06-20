/*
################################################################################
Name             :  CalcEmissions
Date             :  2016-06-30
Author           :  Wayne Hauck
Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose          :  This stored procedure calculates emissions outputs.
Usage            :  n/a
Called by        :  n/a
Copyright (c)    :  Developed by Pinnacle Consulting Group (aka Intech Energy,
                 :  Inc.) for California Public Utilities Commission (CPUC),
                 :  All Rights Reserved
Change History   :  2016-06-30  Wayne Hauck added comment header
                 :  2019-12-31  Robert Hansen reformatted and added comments to
                 :              code
                 :  2020-01-02  Robert Hansen rewrote to update calculations
                 :  2020-01-03  Robert Hansen identified and corrected errors in
                 :              rewritten code
                 :  2020-01-08  Robert Hansen removed #tmp table use and
                 :              replaced with direct queries
                 :  2020-02-03  Robert Hansen applied future-quarterly emissions
                 :              calculations
                 :  2021-04-27  Robert Hansen updated savings terms to subtract
                 :              additional loads and apply second emissions
                 :              rates for fuel substitution
                 :  2021-05-25  Robert Hansen removed references to MEBens field
                 :              in calculations
                 :  2021-06-16  Robert Hansen commented out new fields for fuel
                 :              substitution for implementation at a later date
                 :  2022-09-19  Robert Hansen included Water Energy fields in
                 :              emissions calculations
                 :  2024-04-23  Robert Hansen renamed the "PA" field to
                 :              "IOU_AC_Territory"
                 :  2024-06-20  Robert Hansen reverted "IOU_AC_Territory" to
                 :              "PA"
################################################################################
*/

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

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
        ,Qty *
        ( NTGRkWh + @MEBens ) *
        IRkWh *
        RRkWh *
        (
            --- CO2 Emissions Rate ( tons CO2 per Annual kWh Savings ):
            ISNULL(CO2 *
            --- Applicable annual electric savings rate for each quarter:
            AnnualkWh, 0) /*-
            --- CO2 Emission Rate for additional load:
            ISNULL(CO2_AL *
            --- Applicable additional annual electric load:
            AnnualkWh_AL, 0)*/
        ) AS QuarterlyNetElecCO2
-------------------------------------------------------------------------------
--- QuarterlyGrossElecCO2 -----------------------------------------------------
        ,Qty *
        IRkWh *
        RRkWh *
        (
            --- CO2 Emissions Rate ( lbs CO2 per Annual kWh Savings ):
            ISNULL(CO2 *
            --- Applicable annual electric savings rate for each quarter:
            AnnualkWh, 0) /*-
            --- CO2 Emission Rate for additional load:
            ISNULL(CO2_AL *
            --- Applicable additional annual electric load:
            AnnualkWh_AL, 0)*/
        ) AS QuarterlyGrossElecCO2
-------------------------------------------------------------------------------
--- QuarterlyNetElecNOx -------------------------------------------------------
        ,Qty *
        ( NTGRkWh + @MEBens ) *
        IRkWh *
        RRkWh *
        (
            --- NOx Emissions Rate ( lbs NOx per Annual kWh Savings ):
            ISNULL(NOx *
            --- Applicable quarterly (different from CO2 per Brent Bolii @ E3) electric savings rate for each quarter:
            AnnualkWh / 4, 0) /*- -- Divide annual savings by four to convert to quarterly
            --- NOx Emission Rate for additional load:
            ISNULL(NOx_AL *
            --- Applicable additional quarterly electric load:
            AnnualkWh_AL / 4, 0)*/
        ) AS QuarterlyNetElecNOx
-------------------------------------------------------------------------------
--- QuarterlyGrossElecNOx -----------------------------------------------------
        ,Qty *
        IRkWh *
        RRkWh *
        (
            --- NOx Emissions Rate ( lbs NOx per Annual kWh Savings ):
            ISNULL(NOx *
            --- Applicable quarterly (different from CO2 per Brent Bolii @ E3) electric savings rate for each quarter:
            AnnualkWh / 4, 0) /*- -- Divide annual savings by four to convert to quarterly
            --- NOx Emission Rate for additional load:
            ISNULL(NOx_AL *
            --- Applicable additional quarterly electric load:
            AnnualkWh_AL / 4, 0)*/
        ) AS QuarterlyGrossElecNOx
-------------------------------------------------------------------------------
--- QuarterlyNetPM10 ----------------------------------------------------------
        --- This calculates PM10 savings accounting for electric savings only.
        ,Qty *
        ( NTGRkWh + @MEBens ) *
        IRkWh *
        RRkWh *
        (
            --- 10-Micron Particulate Matter Emissions Rate ( lbs PM10 per Annual kWh Savings ):
            ISNULL(PM10 *
            --- Applicable quarterly (different from CO2 per Brent Bolii @ E3) electric savings rate for each quarter:
            AnnualkWh / 4, 0) /*- -- Divide annual savings by four to convert to quarterly
            --- NOx Emission Rate for additional load:
            ISNULL(PM10_AL *
            --- Applicable additional quarterly electric load:
            AnnualkWh_AL / 4, 0)*/
        ) AS QuarterlyNetPM10
-------------------------------------------------------------------------------
--- QuarterlyGrossPM10 --------------------------------------------------------
        --- This calculates PM10 savings accounting for electric savings only.
        ,Qty *
        IRkWh *
        RRkWh *
        (
            --- 10-Micron Particulate Matter Emissions Rate ( lbs PM10 per Annual kWh Savings ):
            ISNULL(PM10 *
            --- Applicable quarterly (different from CO2 per Brent Bolii @ E3) electric savings rate for each quarter:
            AnnualkWh / 4, 0) /*- -- Divide annual savings by four to convert to quarterly
            --- NOx Emission Rate for additional load:
            ISNULL(PM10_AL *
            --- Applicable additional quarterly electric load:
            AnnualkWh_AL / 4, 0)*/
        ) AS QuarterlyGrossPM10
    FROM (
-------------------------------------------------------------------------------
        SELECT
            @JobID AS JobID
            ,im.CET_ID AS CET_ID
            ,em1.Qtr AS EmissionsQtr
            ,LEFT( im.Qtr, 4 ) * 4 + RIGHT( im.Qtr, 1 ) AS InstallQtr
            --- Create a quarter number based on installation quarter through EUL:
            ,ROW_NUMBER() OVER (PARTITION BY im.CET_ID ORDER BY em1.Qtr ASC) AS SeqQtr
            ,im.Qty AS Qty
            ,im.NTGRkWh AS NTGRkWh
            ,im.IRkWh AS IRkWh
            ,im.RRkWh AS RRkWh
            ,CASE
                --- Zero RUL, i.e., single baseline measure:
                WHEN ISNULL(im.RULq,0) = 0
                THEN
                    CASE
						--- Bypass calculations when no savings:
						WHEN ISNULL(im.kWh1,0) + ISNULL(im.kWhWater1,0) = 0
						THEN 0
                        --- Quarter split between EUL and Post-EUL periods -- interpolate between baseline annual savings rate and zero:
                        WHEN
                            im.Qidx + im.EULq > em1.Qidx AND im.Qidx + im.EULq < em1.Qidx + 1
                        THEN ( ISNULL(im.kWh1,0) + ISNULL(im.kWhWater1,0) ) * ( CONVERT( DECIMAL( 13, 10 ), im.EULq ) % 1 )
                        --- Quarter fully within EUL
                        ELSE ISNULL(im.kWh1,0) + ISNULL(im.kWhWater1,0)
                    END
                --- Non-Zero RUL, i.e., dual baseline measure (assume EUL>RUL):
                ELSE
                    CASE
						--- Bypass calculations when no savings:
						WHEN ISNULL(im.kWh1,0) + ISNULL(im.kWhWater1,0) = 0 AND ISNULL(im.kWh2,0) + ISNULL(im.kWhWater2,0) = 0
						THEN 0
                        --- Quarter fully within RUL -- apply first baseline annual savings rate:
                        WHEN im.Qidx + im.RULq > em1.Qidx + 1
                        THEN ISNULL(im.kWh1,0) + ISNULL(im.kWhWater1,0)
                        --- Quarter fully post-RUL and within EUL -- apply second baseline annual savings rate:
                        WHEN im.Qidx + im.RULq < em1.Qidx AND im.Qidx + im.EULq > em1.Qidx + 1
                        THEN ISNULL(im.kWh2,0) + ISNULL(im.kWhWater2,0)
                        --- Quarter contains both EUL and RUL -- weight annual savings rates by time in both baselines and zero savings after:
                        WHEN
                            im.Qidx + im.RULq > em1.Qidx
                        AND
                            im.Qidx + im.RULq < em1.Qidx + 1
                        AND
                            im.Qidx + im.EULq > em1.Qidx
                        AND
                            im.Qidx + im.EULq < em1.Qidx + 1
                        THEN (ISNULL(im.kWh1,0) + ISNULL(im.kWhWater1,0)) * ( CONVERT( DECIMAL( 13, 10 ), im.RULq ) % 1 ) +
                            (ISNULL(im.kWh2,0) + ISNULL(im.kWhWater2,0)) * ( im.EULq - im.RULq )
                        --- Quarter contains RUL -- weight annual savings rates by time in either baseline:
                        WHEN im.Qidx + im.RULq > em1.Qidx AND im.Qidx + im.RULq < em1.Qidx + 1
                        THEN (ISNULL(im.kWh1,0) + ISNULL(im.kWhWater1,0)) * ( CONVERT( DECIMAL( 13, 10 ), im.RULq ) % 1 ) +
                            (ISNULL(im.kWh2,0) + ISNULL(im.kWhWater2,0)) * ( 1 - CONVERT( DECIMAL( 13, 10 ), im.RULq ) % 1 )
                        --- Quarter contains EUL -- weight annual savings by time in second baseline and zero savings after:
                        WHEN im.Qidx + im.EULq > em1.Qidx AND im.Qidx + im.EULq < em1.Qidx + 1
                        THEN (ISNULL(im.kWh2,0) + ISNULL(im.kWhWater2,0)) *  ( ( im.EULq ) - FLOOR( im.EULq ) )
                        --- Quarter fully post-RUL and pre-EUL -- apply second baseline annual savings rate:
                        ELSE ISNULL(im.kWh2,0) + ISNULL(im.kWhWater2,0)
                    END
            END AS AnnualkWh
      --      ,CASE
      --          --- Zero RUL, i.e., single baseline measure:
      --          WHEN ISNULL(im.RULq,0) = 0
      --          THEN
      --              CASE
						----- bypass calculations when no additional load:
						--WHEN ISNULL(im.kWh1_AL,0) = 0
						--THEN 0
      --                  --- Quarter split between EUL and Post-EUL periods -- interpolate between baseline annual savings rate and zero:
      --                  WHEN
      --                      im.Qidx + im.EULq > em2.Qidx AND im.Qidx + im.EULq < em2.Qidx + 1
      --                  THEN im.kWh1_AL * ( CONVERT( DECIMAL( 13, 10 ), im.EULq ) % 1 )
      --                  --- Quarter fully within EUL
      --                  ELSE im.kWh1_AL
      --              END
      --          --- Non-Zero RUL, i.e., dual baseline measure (assume EUL>RUL):
      --          ELSE
      --              CASE
						----- bypass calculations when no additional load:
						--WHEN ISNULL(im.kWh1_AL,0) = 0 AND ISNULL(im.kWh2_AL,0) = 0
						--THEN 0
      --                  --- Quarter fully within RUL -- apply first baseline annual savings rate:
      --                  WHEN im.Qidx + im.RULq > em2.Qidx + 1
      --                  THEN ISNULL(im.kWh1_AL,0)
      --                  --- Quarter fully post-RUL and within EUL -- apply second baseline annual savings rate:
      --                  WHEN im.Qidx + im.RULq < em2.Qidx AND im.Qidx + im.EULq > em2.Qidx + 1
      --                  THEN ISNULL(im.kWh2_AL,0)
      --                  --- Quarter contains both EUL and RUL -- weight annual savings rates by time in both baselines and zero savings after:
      --                  WHEN
      --                      im.Qidx + im.RULq > em2.Qidx
      --                  AND
      --                      im.Qidx + im.RULq < em2.Qidx + 1
      --                  AND
      --                      im.Qidx + im.EULq > em2.Qidx
      --                  AND
      --                      im.Qidx + im.EULq < em2.Qidx + 1
      --                  THEN ISNULL(im.kWh1_AL,0) * ( CONVERT( DECIMAL( 13, 10 ), im.RULq ) % 1 ) + ISNULL(im.kWh2_AL,0) * ( im.EULq - im.RULq )
      --                  --- Quarter contains RUL -- weight annual savings rates by time in either baseline:
      --                  WHEN im.Qidx + im.RULq > em2.Qidx AND im.Qidx + im.RULq < em2.Qidx + 1
      --                  THEN ISNULL(im.kWh1_AL,0) * ( CONVERT( DECIMAL( 13, 10 ), im.RULq ) % 1 ) + ISNULL(im.kWh2_AL,0) * ( 1 - CONVERT( DECIMAL( 13, 10 ), im.RULq ) % 1 )
      --                  --- Quarter contains EUL -- weight annual savings by time in second baseline and zero savings after:
      --                  WHEN im.Qidx + im.EULq > em2.Qidx AND im.Qidx + im.EULq < em2.Qidx + 1
      --                  THEN ISNULL(im.kWh2_AL,0) *  ( ( im.EULq ) - FLOOR( im.EULq ) )
      --                  --- Quarter fully post-RUL and pre-EUL -- apply second baseline annual savings rate:
      --                  ELSE ISNULL(im.kWh2_AL,0)
      --              END
      --      END AS AnnualkWh_AL
            ,im.RULq AS RULq
            ,im.EULq AS EULq
            ,em1.CO2 AS CO2
            ,em1.NOx AS NOx
            ,em1.PM10 AS PM10
            --,em2.CO2 AS CO2_AL
            --,em2.NOx AS NOx_AL
            --,em2.PM10 AS PM10_AL
        FROM (
            SELECT
                CET_ID
                ,JobID
                ,PA
                ,TS
                ,EU
                --,EUAL
                ,CZ
                ,Qtr
                ,LEFT(Qtr,4) * 4 + RIGHT(Qtr,1) AS Qidx
                ,Qty
                ,kWh1
                ,kWhWater1
                --,kWh1_AL
                ,kWh2
                --,kWh2_AL
                ,kWhWater2
                ,EULq
                ,RULq
                ,NTGRkWh
                ,IRkWh
                ,RRkWh

            FROM InputMeasurevw 
        ) AS im
        LEFT JOIN
            Settingsvw AS s
            ON
                im.PA = s.PA
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
            ) AS em1
            ON
                s.Version = em1.Version
            AND
                im.PA + im.TS + im.EU + RTRIM(im.CZ) =
                em1.PA +
                CASE
                    WHEN em1.EU LIKE 'Non_res:DEER%'
                    THEN 'Non_res'
                    ELSE
                        CASE
                            WHEN em1.EU LIKE 'res:DEER%'
                            THEN 'Res'
                            ELSE em1.TS
                        END
                END +
                CASE
                    WHEN em1.EU LIKE 'Non_res:DEER%'
                    THEN REPLACE( em1.EU, 'Non_Res:', '' )
                    ELSE
                        CASE
                            WHEN em1.EU LIKE 'res:DEER%'
                            THEN REPLACE( em1.EU, 'res:', '' )
                            ELSE em1.EU
                        END
                END +
                em1.CZ
            AND
                --- Quarterly records in emissions table in or after measure installation:
                em1.Qidx >= im.Qidx
            AND
                --- Quarterly records in emissions table before measure installation + EUL:
                em1.Qidx < im.Qidx + im.EULq
        --LEFT JOIN (
        --        --- Second join to emissions table on end use profile for additional load:
        --        SELECT
        --            PA
        --            ,TS
        --            ,EU
        --            ,CZ
        --            ,Version
        --            ,Qtr
        --            ,LEFT(Qtr,4) * 4 + RIGHT(Qtr,1) AS Qidx
        --            ,CO2
        --            ,NOx
        --            ,PM10
        --        FROM E3EmissionsSourcevw
        --    ) AS em2
        --    ON
        --        s.Version = em2.Version
        --    AND
        --        im.PA + im.TS + im.EUAL + RTRIM(im.CZ) =
        --        em2.PA +
        --        CASE
        --            WHEN em2.EU LIKE 'Non_res:DEER%'
        --            THEN 'Non_res'
        --            ELSE
        --                CASE
        --                    WHEN em2.EU LIKE 'res:DEER%'
        --                    THEN 'Res'
        --                    ELSE em2.TS
        --                END
        --        END +
        --        CASE
        --            WHEN em2.EU LIKE 'Non_res:DEER%'
        --            THEN REPLACE( em2.EU, 'Non_Res:', '' )
        --            ELSE
        --                CASE
        --                    WHEN em2.EU LIKE 'res:DEER%'
        --                    THEN REPLACE( em2.EU, 'res:', '' )
        --                    ELSE em2.EU
        --                END
        --        END +
        --        em2.CZ
        --    AND
        --        em2.Qidx = em1.Qidx
        WHERE
            im.CET_ID IS NOT NULL
        AND
            s.Version = @AVCVersion
    ) AS im
    ORDER BY
        im.CET_ID
        ,SeqQtr

INSERT INTO OutputEmissions
    SELECT
        @JobID AS JobID,
        im.PA AS PA,
        im.PrgID AS PrgID,
        im.CET_ID AS CET_ID,
        FirstYearElecEmissions.NetElecCO2 AS NetElecCO2,
        ISNULL(
            im.Qty *
            ( im.NTGRThm + @MEBens ) *
            im.IRThm *
            im.RRThm *
            --- CO2 savings conversion factor (Therms --> lbs CO2eq):
            s.CO2Gas *
            --- First year natural gas savings:
            CASE
                --- Non-zero RUL, i.e., dual baseline measure:
                WHEN ISNULL( im.RULq, 0 ) > 0
                THEN
                    CASE
                        --- First year fully within RUL:
                        WHEN im.RUL >= 1
                        THEN ISNULL(im.Thm1,0) /*- ISNULL(im.Thm1_AL,0)*/
                        --- Full first year split before and after RUL:
                        WHEN im.RUL < 1 AND im.EUL >= 1
                        THEN im.RUL * ( ISNULL(im.Thm1,0) /*- ISNULL(im.Thm1_AL,0)*/ ) + ( 1 - im.RUL ) * ( ISNULL(im.Thm2,0) /*- ISNULL(im.Thm2_AL,0)*/ )
                        --- Both RUL and EUL within first year:
                        ELSE im.RUL * ( ISNULL(im.Thm1,0) /*- ISNULL(im.Thm1_AL,0)*/ ) + ( im.EUL - im.RUL ) * ( ISNULL(im.Thm2,0) /*- ISNULL(im.Thm2_AL,0)*/ )
                    END
                --- No RUL, i.e., single baseline measure:
                WHEN EUL > 0
                THEN
                    CASE
                        --- First year fully within EUL:
                        WHEN im.EUL > 1
                        THEN ISNULL(im.Thm1,0) /*- ISNULL(im.Thm1_AL,0)*/
                        --- EUL less than 1 year:
                        ELSE im.EUL * ( im.Thm1 /*- ISNULL(im.Thm1_AL,0)*/ )
                    END
                --- Failsafe condition (disallow negative EUL):
                ELSE 0
            END,
            0
        ) as NetGasCO2,
        FirstYearElecEmissions.GrossElecCO2 AS GrossElecCO2,
        ISNULL(
            im.Qty *
            im.IRThm *
            im.RRThm *
            --- CO2 savings conversion factor (Therms --> lbs CO2eq):
            s.CO2Gas *
            --- First year natural gas savings:
            CASE
                --- Non-zero RUL, i.e., dual baseline measure:
                WHEN ISNULL( im.RUL, 0 ) > 0
                THEN
                    CASE
                        --- First year fully within RUL:
                        WHEN im.RUL >= 1
                        THEN ISNULL(im.Thm1,0) /*- ISNULL(im.Thm1_AL,0)*/
                        --- Full first year split before and after RUL:
                        WHEN im.RUL < 1 AND im.EUL >= 1
                        THEN im.RUL * ( ISNULL(im.Thm1,0) /*- ISNULL(im.Thm1_AL,0)*/ ) + ( 1 - im.RUL ) * ( ISNULL(im.Thm2,0) /*- ISNULL(im.Thm2_AL,0)*/ )
                        --- Both RUL and EUL within first year:
                        ELSE im.RUL * ( ISNULL(im.Thm1,0) /*- ISNULL(im.Thm1_AL,0)*/ ) + ( im.EUL - im.RUL ) * ( ISNULL(im.Thm2,0) /*- ISNULL(im.Thm2_AL,0)*/ )
                    END
                --- No RUL, i.e., single baseline measure:
                WHEN EUL > 0
                THEN
                    CASE
                        --- First year fully within EUL:
                        WHEN im.EUL > 1
                        THEN ISNULL(im.Thm1,0) /*- ISNULL(im.Thm1_AL,0)*/
                        --- EUL less than 1 year:
                        ELSE im.EUL * ( ISNULL(im.Thm1,0) /*- ISNULL(im.Thm1_AL,0)*/ )
                    END
                --- Failsafe condition (disallow negative EUL):
                ELSE 0
            END,
            0
        ) as GrossGasCO2,
        LifecycleElecEmissions.NetElecCO2 AS NetElecCO2Lifecycle,
        ISNULL(
            im.Qty *
            ( im.NTGRThm + @MEBens ) *
            im.IRThm *
            im.RRThm *
            --- CO2 savings conversion factor (Therms --> lbs CO2eq):
            s.CO2Gas *
            --- Lifecycle natural gas savings:
            CASE
                --- Non-zero RUL, i.e., Accelerated Replacement:
                WHEN ISNULL( im.RUL, 0 ) > 0
                THEN im.RUL * ( ISNULL(im.Thm1,0) /*- ISNULL(im.Thm1_AL,0)*/ ) + ( im.EUL - im.RUL) * ( ISNULL(im.Thm2,0) /*- ISNULL(im.Thm2_AL,0)*/ )
                --- No RUL, i.e., Replace-on-Burnout:
                WHEN im.EUL > 0
                THEN im.EUL * ( ISNULL(im.Thm1,0) /*- ISNULL(im.Thm1_AL,0)*/ )
                --- Failsafe condition (disallow negative EUL and EUL < RUL):
                ELSE 0
            END,
            0
        ) as NetGasCO2Lifecycle,
        LifecycleElecEmissions.GrossElecCO2 AS GrossElecCO2Lifecycle,
        ISNULL(
            im.Qty *
            im.IRThm *
            im.RRThm *
            --- CO2 savings conversion factor (Therms --> lbs CO2eq):
            s.CO2Gas *
            --- Lifecycle natural gas savings:
            CASE
                --- Non-zero RUL, i.e., Accelerated Replacement:
                WHEN ISNULL( im.RUL, 0 ) > 0
                THEN im.RUL * ( ISNULL(im.Thm1,0) /*- ISNULL(im.Thm1_AL,0)*/ )+ ( im.EUL - im.RUL) * ( ISNULL(im.Thm2,0) /*- ISNULL(im.Thm2_AL,0)*/ )
                --- No RUL, i.e., Replace-on-Burnout:
                WHEN im.EUL > 0
                THEN im.EUL * ( ISNULL(im.Thm1,0) /*- ISNULL(im.Thm1_AL,0)*/ )
                --- Failsafe condition (disallow negative EUL and EUL < RUL):
                ELSE 0
            END,
            0
        ) as GrossGasCO2Lifecycle,
        FirstYearElecEmissions.NetElecNOx AS NetElecNOx,
        ISNULL(
            im.Qty *
            ( im.NTGRThm + @MEBens ) *
            im.IRThm *
            im.RRThm *
            --- CO2 savings conversion factor (Therms --> lbs NOx):
            eg.NOxGas *
            --- First year natural gas savings:
            CASE
                --- Non-zero RUL, i.e., dual baseline measure:
                WHEN ISNULL( im.RUL, 0 ) > 0
                THEN
                    CASE
                        --- First year fully within RUL:
                        WHEN im.RUL >= 1
                        THEN ISNULL(im.Thm1,0) /*- ISNULL(im.Thm1_AL,0)*/
                        --- Full first year split before and after RUL:
                        WHEN im.RUL < 1 AND im.EUL >= 1
                        THEN im.RUL * ( ISNULL(im.Thm1,0) /*- ISNULL(im.Thm1_AL,0)*/ ) + ( 1 - im.RUL ) * ( ISNULL(im.Thm2,0) /*- ISNULL(im.Thm2_AL,0)*/ )
                        --- Both RUL and EUL within first year:
                        ELSE im.RUL * ( ISNULL(im.Thm1,0) /*- ISNULL(im.Thm1_AL,0)*/ ) + ( im.EUL - im.RUL ) * ( ISNULL(im.Thm2,0) /*- ISNULL(im.Thm2_AL,0)*/ )
                    END
                --- No RUL, i.e., single baseline measure:
                WHEN EUL > 0
                THEN
                    CASE
                        --- First year fully within EUL:
                        WHEN im.EUL > 1
                        THEN ISNULL(im.Thm1,0) /*- ISNULL(im.Thm1_AL,0)*/
                        --- EUL less than 1 year:
                        ELSE im.EUL * ( ISNULL(im.Thm1,0) /*- ISNULL(im.Thm1_AL,0)*/ )
                    END
                --- Failsafe condition (disallow negative EUL):
                ELSE 0
            END,
            0
        ) as NetGasNOx,
        FirstYearElecEmissions.GrossElecNOx AS GrossElecNOx,
        ISNULL(
            im.Qty *
            im.IRThm *
            im.RRThm *
            --- NOx savings conversion factor (Therms --> lbs NOx):
            eg.NOxGas *
            --- First year natural gas savings:
            CASE
                --- Non-zero RUL, i.e., dual baseline measure:
                WHEN ISNULL( im.RUL, 0 ) > 0
                THEN
                    CASE
                        --- First year fully within RUL:
                        WHEN im.RUL >= 1
                        THEN ISNULL(im.Thm1,0) /*- ISNULL(im.Thm1_AL,0)*/
                        --- Full first year split before and after RUL:
                        WHEN im.RUL < 1 AND im.EUL >= 1
                        THEN im.RUL * ( ISNULL(im.Thm1,0) /*- ISNULL(im.Thm1_AL,0)*/ ) + ( 1 - im.RUL ) * ( ISNULL(im.Thm2,0) /*- ISNULL(im.Thm2_AL,0)*/ )
                        --- Both RUL and EUL within first year:
                        ELSE im.RUL * ( ISNULL(im.Thm1,0) /*- ISNULL(im.Thm1_AL,0)*/ ) + ( im.EUL - im.RUL ) * ( ISNULL(im.Thm2,0) /*- ISNULL(im.Thm2_AL,0)*/ )
                    END
                --- No RUL, i.e., single baseline measure:
                WHEN EUL > 0
                THEN
                    CASE
                        --- First year fully within EUL:
                        WHEN im.EUL > 1
                        THEN ISNULL(im.Thm1,0) /*- ISNULL(im.Thm1_AL,0)*/
                        --- EUL less than 1 year:
                        ELSE im.EUL * ( ISNULL(im.Thm1,0) /*- ISNULL(im.Thm1_AL,0)*/ )
                    END
                --- Failsafe condition (disallow negative EUL):
                ELSE 0
            END,
            0
        ) as GrossGasNOx,
        LifecycleElecEmissions.NetElecNOx AS NetElecNOxLifecycle,
        ISNULL(
            im.Qty *
            ( im.NTGRThm + @MEBens ) *
            im.IRThm *
            im.RRThm *
            --- NOx savings conversion factor (Therms --> lbs NOx):
            eg.NOxGas *
            --- Lifecycle natural gas savings:
            CASE
                --- Non-zero RUL, i.e., Accelerated Replacement:
                WHEN ISNULL( im.RUL, 0 ) > 0
                THEN im.RUL * ( ISNULL(im.Thm1,0) /*- ISNULL(im.Thm1_AL,0)*/ ) + ( im.EUL - im.RUL) * ( ISNULL(im.Thm2,0) /*- ISNULL(im.Thm2_AL,0)*/ )
                --- No RUL, i.e., Replace-on-Burnout:
                WHEN im.EUL > 0
                THEN im.EUL * ( ISNULL(im.Thm1,0) /*- ISNULL(im.Thm1_AL,0)*/ )
                --- Failsafe condition (disallow negative EUL and EUL < RUL):
                ELSE 0
            END,
            0
        ) as NetGasNOxLifecycle,
        LifecycleElecEmissions.GrossElecNOx AS GrossElecNOxLifecycle,
        ISNULL(
            im.Qty *
            im.IRThm *
            im.RRThm *
            --- NOx savings conversion factor (Therms --> lbs NOx):
            eg.NOxGas *
            --- Lifecycle natural gas savings:
            CASE
                --- Non-zero RUL, i.e., Accelerated Replacement:
                WHEN ISNULL( im.RUL, 0 ) > 0
                THEN im.RUL * ( ISNULL(im.Thm1,0) /*- ISNULL(im.Thm1_AL,0)*/ ) + ( im.EUL - im.RUL) * ( ISNULL(im.Thm2,0) /*- ISNULL(im.Thm2_AL,0)*/ )
                --- No RUL, i.e., Replace-on-Burnout:
                WHEN im.EUL > 0
                THEN im.EUL * ( ISNULL(im.Thm1,0) /*- ISNULL(im.Thm1_AL,0)*/ )
                --- Failsafe condition (disallow negative EUL and EUL < RUL):
                ELSE 0
            END,
            0
        ) as GrossGasNOxLifecycle,
        FirstYearElecEmissions.NetPM10 AS NetPM10,
        FirstYearElecEmissions.GrossPM10 AS GrossPM10,
        LifecycleElecEmissions.NetPM10 AS NetPM10Lifecycle,
        LifecycleElecEmissions.GrossPM10 AS GrossPM10Lifecycle
    FROM InputMeasurevw AS im
    LEFT JOIN
        Settingsvw AS s
    ON
        im.PA = s.PA
    LEFT JOIN
        E3CombustionTypevw AS eg
    ON
        im.CET_ID = eg.CET_ID
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
        im.CET_ID = FirstYearElecEmissions.CET_ID
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
        im.CET_ID = LifecycleElecEmissions.CET_ID
    ORDER BY
        im.PA
        ,im.PrgID
        ,im.CET_ID
GO