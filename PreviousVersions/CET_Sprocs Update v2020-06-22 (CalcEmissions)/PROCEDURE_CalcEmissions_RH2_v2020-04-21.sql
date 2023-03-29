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
IF NOT EXISTS ( SELECT * FROM sys.objects WHERE type='FN' AND OBJECT_ID = OBJECT_ID('dbo.Qidx'))
	EXEC('CREATE FUNCTION dbo.Qidx(@Qtr NVARCHAR(6)) RETURNS INT AS BEGIN RETURN LEFT(@Qtr,4)*4 + RIGHT(@Qtr,1) END')
GO

ALTER FUNCTION dbo.Qidx ( @Qtr NVARCHAR( 6 ) )
RETURNS INT AS
BEGIN
	RETURN LEFT( @Qtr, 4 ) * 4 + RIGHT( @Qtr, 1 )
END
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
        @JobID AS JobID
        ,e.CET_ID AS CET_ID
        ,em.Qtr AS EmissionsQtr
        --- Create a quarter number based on installation quarter through EUL:
        ,ROW_NUMBER() OVER (PARTITION BY e.CET_ID ORDER BY em.Qtr ASC) AS SeqQtr
--- QuarterlyNetElecCO2 --------------------------------------------------------
        ,ISNULL(
            e.Qty *
            ( e.NTGRkWh + COALESCE( e.MEBens, @MEBens ) ) *
            e.IRkWh *
            e.RRkWh *
            --- CO2 Emissions Rate ( tons CO2 per Annual kWh Savings ):
            em.CO2 *
            --- Applicable annual electric savings rate for each quarter:
            CASE
                --- No RUL, i.e., single baseline measure:
                WHEN ISNULL(e.RUL,0) = 0
                THEN
                    CASE
                        --- Quarter split between EUL and Post-EUL periods -- interpolate between baseline annual savings rate and zero:
                        WHEN dbo.Qidx(e.Qtr) + e.EULq > dbo.Qidx(em.Qtr) AND dbo.Qidx(e.Qtr) + e.EULq < dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh1 * ( CONVERT( DECIMAL( 13, 10 ), e.EULq ) % 1 )
                        --- Quarter fully within EUL
                        ELSE e.kWh1
                    END
                --- Non-Zero RUL, i.e., dual baseline measure (assume EUL>RUL):
                ELSE
                    CASE
                        --- Quarter fully within RUL -- apply first baseline annual savings rate:
                        WHEN dbo.Qidx(e.Qtr) + e.RULq > dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh1
                        --- Quarter fully post-RUL and within EUL -- apply second baseline annual savings rate:
                        WHEN dbo.Qidx(e.Qtr) + e.RULq < dbo.Qidx(em.Qtr) AND dbo.Qidx(e.Qtr) + e.EULq > dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh2
                        --- Quarter contains both EUL and RUL -- weight annual savings rates by time in both baselines and zero savings after:
                        WHEN
                            dbo.Qidx(e.Qtr) + e.RULq > dbo.Qidx(em.Qtr)
                        AND
                            dbo.Qidx(e.Qtr) + e.RULq < dbo.Qidx(em.Qtr) + 1
                        AND
                            dbo.Qidx(e.Qtr) + e.EULq > dbo.Qidx(em.Qtr)
                        AND
                            dbo.Qidx(e.Qtr) + e.EULq < dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh1 * ( CONVERT( DECIMAL( 13, 10 ), e.RULq ) % 1 ) + e.kWh2 * ( e.EULq - e.RULq )
                        --- Quarter contains RUL -- weight annual savings rates by time in either baselines:
                        WHEN dbo.Qidx(e.Qtr) + e.RULq > dbo.Qidx(em.Qtr) AND dbo.Qidx(e.Qtr) + e.RULq < dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh1 * ( CONVERT( DECIMAL( 13, 10 ), e.RULq ) % 1 ) + e.kWh2 * ( 1 - CONVERT( DECIMAL( 13, 10 ), e.RULq ) % 1 )
                        --- Quarter contains EUL -- weight annual savings by time in second baseline and zero savings after:
                        WHEN dbo.Qidx(e.Qtr) + e.EULq > dbo.Qidx(em.Qtr) AND dbo.Qidx(e.Qtr) + e.EULq < dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh2 *  ( ( e.EULq ) - FLOOR( e.EULq ) )
                        --- Quarter fully post-RUL and pre-EUL -- apply second baseline annual savings rate:
                        ELSE e.kWh2
                    END
            END,
            0
        ) as QuarterlyNetElecCO2
-------------------------------------------------------------------------------
--- QuarterlyGrossElecCO2 -----------------------------------------------------
        ,ISNULL(
            e.Qty *
            e.IRkWh *
            e.RRkWh *
            --- CO2 Emissions Rate ( lbs CO2 per Annual kWh Savings ):
            em.CO2 *
            --- Applicable annual electric savings rate for each quarter:
            CASE
                --- No RUL, i.e., single baseline measure:
                WHEN ISNULL(e.RULq,0) = 0
                THEN
                    CASE
                        --- Quarter split between EUL and Post-EUL periods -- interpolate between baseline annual savings rate and zero:
                        WHEN dbo.Qidx(e.Qtr) + e.EULq > dbo.Qidx(em.Qtr) AND dbo.Qidx(e.Qtr) + e.EULq < dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh1 * ( CONVERT( DECIMAL( 13, 10 ), e.EULq ) % 1 )
                        --- Quarter fully within EUL
                        ELSE e.kWh1
                    END
                --- Non-Zero RUL, i.e., dual baseline measure (assume EUL>RUL):
                ELSE
                    CASE
                        --- Quarter fully within RUL -- apply first baseline annual savings rate:
                        WHEN dbo.Qidx(e.Qtr) + e.RULq > dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh1
                        --- Quarter fully post-RUL and within EUL -- apply second baseline annual savings rate:
                        WHEN dbo.Qidx(e.Qtr) + e.EULq > dbo.Qidx(em.Qtr) + 1 AND dbo.Qidx(e.Qtr) + e.RULq < dbo.Qidx(em.Qtr)
                        THEN e.kWh2
                        --- Quarter contains EUL and RUL -- weight annual savings rates by time in both baselines and zero savings after:
                        WHEN
                            dbo.Qidx(e.Qtr) + e.RULq > dbo.Qidx(em.Qtr)
                        AND
                            dbo.Qidx(e.Qtr) + e.RULq < dbo.Qidx(em.Qtr) + 1
                        AND
                            dbo.Qidx(e.Qtr) + e.EULq > dbo.Qidx(em.Qtr)
                        AND
                            dbo.Qidx(e.Qtr) + e.EULq < dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh1 * ( CONVERT( DECIMAL( 13, 10 ), e.RULq ) % 1 ) + e.kWh2 * ( e.EULq - e.RULq )
                        --- Quarter contains RUL -- weight annual savings by time in either baselines:
                        WHEN dbo.Qidx(e.Qtr) + e.RULq > dbo.Qidx(em.Qtr) AND dbo.Qidx(e.Qtr) + e.RULq < dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh1 * ( CONVERT( DECIMAL( 13, 10 ), e.RULq ) % 1 ) + e.kWh2 * ( CEILING( e.RULq ) - e.RULq )
                        --- Quarter contains EUL -- weight annual savings by time in second baseline and zero savings after:
                        WHEN dbo.Qidx(e.Qtr) + e.EULq > dbo.Qidx(em.Qtr) AND dbo.Qidx(e.Qtr) + e.EULq < dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh2 *  ( ( e.EULq ) - FLOOR( e.EULq ) )
                        --- Quarter fully post-RUL and pre-EUL -- apply second baseline annual savings rate:
                        ELSE e.kWh2
                    END
            END,
            0
        ) as QuarterlyGrossElecCO2
-------------------------------------------------------------------------------
--- QuarterlyNetElecNOx -------------------------------------------------------
        ,ISNULL(
            e.Qty *
            ( e.NTGRkWh + COALESCE( e.MEBens, @MEBens ) ) *
            e.IRkWh *
            e.RRkWh *
            --- NOx Emissions Rate ( lbs NOx per Annual kWh Savings ):
            em.NOx *
            --- Applicable quarterly (different from CO2 per Brent Bolii @ E3) electric savings rate for each quarter:
            CASE
                --- No RUL, i.e., single baseline measure:
                WHEN ISNULL(e.RULq,0) = 0
                THEN
                    CASE
                        --- Quarter split between EUL and Post-EUL periods -- interpolate between baseline annual savings rate and zero:
                        WHEN dbo.Qidx(e.Qtr) + e.EULq > dbo.Qidx(em.Qtr) AND dbo.Qidx(e.Qtr) + e.EULq < dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh1 * ( CONVERT( DECIMAL( 13, 10 ), e.EULq ) % 1 )
                        --- Quarter fully within EUL
                        ELSE e.kWh1
                    END
                --- Non-Zero RUL, i.e., dual baseline measure (assume EUL>RUL):
                ELSE
                    CASE
                        --- Quarter fully within RUL -- apply first baseline annual savings rate:
                        WHEN dbo.Qidx(e.Qtr) + e.RULq > dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh1
                        --- Quarter fully post-RUL and within EUL -- apply second baseline annual savings rate:
                        WHEN dbo.Qidx(e.Qtr) + e.RULq < dbo.Qidx(em.Qtr) AND dbo.Qidx(e.Qtr) + e.EULq > dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh2
                        --- Quarter contains EUL and RUL -- weight annual savings by time in both baselines and after:
                        WHEN
                            dbo.Qidx(e.Qtr) + e.RULq > dbo.Qidx(em.Qtr)
                        AND
                            dbo.Qidx(e.Qtr) + e.RULq < dbo.Qidx(em.Qtr) + 1
                        AND
                            dbo.Qidx(e.Qtr) + e.EULq > dbo.Qidx(em.Qtr)
                        AND
                            dbo.Qidx(e.Qtr) + e.EULq < dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh1 * ( CONVERT( DECIMAL( 13, 10 ), e.RULq ) % 1 ) + e.kWh2 * ( e.EULq - e.RULq )
                        --- Quarter contains RUL -- weight annual savings rates by time in either baselines:
                        WHEN dbo.Qidx(e.Qtr) + e.RULq > dbo.Qidx(em.Qtr) AND dbo.Qidx(e.Qtr) + e.RULq < dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh1 * ( CONVERT( DECIMAL( 13, 10 ), e.RULq ) % 1 ) + e.kWh2 * ( CEILING( e.RULq ) - e.RULq )
                        --- Quarter contains EUL -- weight annual savings by time in second baseline and after:
                        WHEN dbo.Qidx(e.Qtr) + e.EULq > dbo.Qidx(em.Qtr) AND dbo.Qidx(e.Qtr) + e.EULq < dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh2 *  ( ( e.EULq ) - FLOOR( e.EULq ) )
                        --- Quarter fully post-RUL and pre-EUL -- apply second baseline:
                        ELSE e.kWh2
                    END
            END / 4, -- Divide annual savings by four to convert to quarterly
            0
        ) as QuarterlyNetElecNOx
-------------------------------------------------------------------------------
--- QuarterlyGrossElecNOx -----------------------------------------------------
        ,ISNULL(
            e.Qty *
            e.IRkWh *
            e.RRkWh *
            --- NOx Emissions Rate ( lbs NOx per Annual kWh Savnigs ):
            em.NOx *
            --- Applicable quarterly (different from CO2 per Brent Bolii @ E3) electric savings rate for each quarter:
            CASE
                --- No RUL, i.e., single baseline measure:
                WHEN ISNULL(e.RULq,0) = 0
                THEN
                    CASE
                        --- Quarter split between EUL and Post-EUL periods -- interpolate between baseline savings rate and zero savings:
                        WHEN dbo.Qidx(e.Qtr) + e.EULq > dbo.Qidx(em.Qtr) AND dbo.Qidx(e.Qtr) + e.EULq < dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh1 * ( CONVERT( DECIMAL( 13, 10 ), e.EULq ) % 1 )
                        --- Quarter fully within EUL
                        ELSE e.kWh1
                    END
                --- Non-Zero RUL, i.e., dual baseline measure (assume EUL>RUL):
                ELSE
                    CASE
                        --- Quarter fully within RUL -- apply first baseline annual savings rate:
                        WHEN dbo.Qidx(e.Qtr) + e.RULq > dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh1
                        --- Quarter fully post-RUL and within EUL -- apply second baseline annual savings rate:
                        WHEN dbo.Qidx(e.Qtr) + e.RULq < dbo.Qidx(em.Qtr) AND dbo.Qidx(e.Qtr) + e.EULq > dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh2
                        --- Quarter contains EUL and RUL -- weight annual savings rates by time in both baselines and zero savings after:
                        WHEN
                            dbo.Qidx(e.Qtr) + e.RULq > dbo.Qidx(em.Qtr)
                        AND
                            dbo.Qidx(e.Qtr) + e.RULq < dbo.Qidx(em.Qtr) + 1
                        AND
                            dbo.Qidx(e.Qtr) + e.EULq > dbo.Qidx(em.Qtr)
                        AND
                            dbo.Qidx(e.Qtr) + e.EULq < dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh1 * ( CONVERT( DECIMAL( 13, 10 ), e.RULq ) % 1 ) + e.kWh2 * ( e.EULq - e.RULq )
                        --- Quarter contains RUL -- weight quarterly savings by time in both baselines:
                        WHEN dbo.Qidx(e.Qtr) + e.RULq > dbo.Qidx(em.Qtr) AND dbo.Qidx(e.Qtr) + e.RULq < dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh1 * ( CONVERT( DECIMAL( 13, 10 ), e.RULq ) % 1 ) + e.kWh2 * ( CEILING( e.RULq ) - e.RULq )
                        --- Quarter contains EUL -- weight annual savings rate by time in second baseline and after:
                        WHEN dbo.Qidx(e.Qtr) + e.EULq > dbo.Qidx(em.Qtr) AND dbo.Qidx(e.Qtr) + e.EULq < dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh2 *  ( ( e.EULq ) - FLOOR( e.EULq ) )
                        --- Quarter fully post-RUL and pre-EUL -- apply second baseline annual savings rate:
                        ELSE e.kWh2
                    END
            END / 4, -- Divide annual savings by four to convert to quarterly
            0
        ) as QuarterlyGrossElecNOx
-------------------------------------------------------------------------------
--- QuarterlyNetPM10 ----------------------------------------------------------
        --- This calculates PM10 savings accounting for electric savings only.
        ,ISNULL(
            e.Qty *
            ( e.NTGRkWh + COALESCE( e.MEBens, @MEBens ) ) *
            e.IRkWh *
            e.RRkWh *
            --- 10-Micron Particulate Matter Emissions Rate ( lbs PM10 per Annual kWh Savings ):
            em.PM10 *
            --- Applicable quarterly (different from CO2 per Brent Bolii @ E3) electric savings rate for each quarter:
            CASE
                --- No RUL, i.e., single baseline measure:
                WHEN ISNULL(e.RUL,0) = 0
                THEN
                    CASE
                        --- Quarter split between EUL and Post-EUL periods -- interpolate between baseline and zero:
                        WHEN dbo.Qidx(e.Qtr) + e.EULq > dbo.Qidx(em.Qtr) AND dbo.Qidx(e.Qtr) + e.EULq < dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh1 * ( CONVERT( DECIMAL( 13, 10 ), e.EULq ) % 1 )
                        --- Quarter fully within EUL
                        ELSE e.kWh1
                    END
                --- Non-Zero RUL, i.e., dual baseline measure (assume EUL>RUL):
                ELSE
                    CASE
                        --- Quarter fully within RUL -- apply first baseline quarterly savings rate:
                        WHEN dbo.Qidx(e.Qtr) + e.RULq > dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh1
                        --- Quarter fully post-RUL and within EUL -- apply second baseline quarterly savings rate:
                        WHEN dbo.Qidx(e.Qtr) + e.RULq < dbo.Qidx(em.Qtr) AND dbo.Qidx(e.Qtr) + e.EULq > dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh2
                        --- Quarter contains EUL and RUL -- weight quarterly savings by time in both baselines and after:
                        WHEN
                            dbo.Qidx(e.Qtr) + e.RULq > dbo.Qidx(em.Qtr)
                        AND
                            dbo.Qidx(e.Qtr) + e.RULq < dbo.Qidx(em.Qtr) + 1
                        AND
                            dbo.Qidx(e.Qtr) + e.EULq > dbo.Qidx(em.Qtr)
                        AND
                            dbo.Qidx(e.Qtr) + e.EULq < dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh1 * ( CONVERT( DECIMAL( 13, 10 ), e.RULq ) % 1 ) + e.kWh2 * ( e.EULq - e.RULq )
                        --- Quarter contains RUL -- weight quarterly savings by time in both baselines:
                        WHEN dbo.Qidx(e.Qtr) + e.RULq > dbo.Qidx(em.Qtr) AND dbo.Qidx(e.Qtr) + e.RULq < dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh1 * ( CONVERT( DECIMAL( 13, 10 ), e.RULq ) % 1 ) + e.kWh2 * ( CEILING( e.RULq ) - e.RULq )
                        --- Quarter contains EUL -- weight quarterly savings by time in second baseline and after:
                        WHEN dbo.Qidx(e.Qtr) + e.EULq > dbo.Qidx(em.Qtr) AND dbo.Qidx(e.Qtr) + e.EULq < dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh2 *  ( ( e.EULq ) - FLOOR( e.EULq ) )
                        --- Quarter fully post-RUL and pre-EUL, i.e., apply second baseline:
                        ELSE e.kWh2
                    END
            END / 4, -- Divide annual savings by four to convert to quarterly
            0
        ) as QuarterlyNetPM10
-------------------------------------------------------------------------------
--- QuarterlyGrossPM10 --------------------------------------------------------
        --- This calculates PM10 savings accounting for electric savings only.
        ,ISNULL(
            e.Qty *
            e.IRkWh *
            e.RRkWh *
            --- 10-Micron Particulate Matter Emissions Rate ( lbs PM10 per Annual kWh Savings ):
            em.PM10 *
            --- Applicable quarterly (different from CO2 per Brent Bolii @ E3) electric savings rate for each quarter:
            CASE
                --- No RUL, i.e., single baseline measure:
                WHEN ISNULL(e.RUL,0) = 0
                THEN
                    CASE
                        --- Quarter split between EUL and Post-EUL periods -- interpolate between baseline annual savings rate and zero:
                        WHEN dbo.Qidx(e.Qtr) + e.EULq > dbo.Qidx(em.Qtr) AND dbo.Qidx(e.Qtr) + e.EULq < dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh1 * ( CONVERT( DECIMAL( 13, 10 ), e.EULq ) % 1 )
                        --- Quarter fully within EUL
                        ELSE e.kWh1
                    END
                --- Non-Zero RUL, i.e., dual baseline measure (assume EUL>RUL):
                ELSE
                    CASE
                        --- Quarter fully within RUL -- apply first baseline annual savings rate:
                        WHEN dbo.Qidx(e.Qtr) + e.RULq > dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh1
                        --- Quarter fully post-RUL and within EUL -- apply second baseline annual savings rate:
                        WHEN dbo.Qidx(e.Qtr) + e.RULq < dbo.Qidx(em.Qtr) AND dbo.Qidx(e.Qtr) + e.EULq > dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh2
                        --- Quarter contains both EUL and RUL -- weight annual savings rates by time in both baselines and zero savings after:
                        WHEN
                            dbo.Qidx(e.Qtr) + e.RULq > dbo.Qidx(em.Qtr)
                        AND
                            dbo.Qidx(e.Qtr) + e.RULq < dbo.Qidx(em.Qtr) + 1
                        AND
                            dbo.Qidx(e.Qtr) + e.EULq > dbo.Qidx(em.Qtr)
                        AND
                            dbo.Qidx(e.Qtr) + e.EULq < dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh1 * ( CONVERT( DECIMAL( 13, 10 ), e.RULq ) % 1 ) + e.kWh2 * ( e.EULq - e.RULq )
                        --- Quarter contains RUL -- weight annual savings rates by time in either baselines:
                        WHEN dbo.Qidx(e.Qtr) + e.RULq > dbo.Qidx(em.Qtr) AND dbo.Qidx(e.Qtr) + e.RULq < dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh1 * ( CONVERT( DECIMAL( 13, 10 ), e.RULq ) % 1 ) + e.kWh2 * ( 1 - CONVERT( DECIMAL( 13, 10 ), e.RULq ) % 1 )
                        --- Quarter contains EUL -- weight annual savings by time in second baseline and zero savings after:
                        WHEN dbo.Qidx(e.Qtr) + e.EULq > dbo.Qidx(em.Qtr) AND dbo.Qidx(e.Qtr) + e.EULq < dbo.Qidx(em.Qtr) + 1
                        THEN e.kWh2 *  ( ( e.EULq ) - FLOOR( e.EULq ) )
                        --- Quarter fully post-RUL and pre-EUL -- apply second baseline annual savings rate:
                        ELSE e.kWh2
                    END
            END / 4, -- Divide annual savings by four to convert to quarterly
            0
        ) as QuarterlyGrossPM10
-------------------------------------------------------------------------------
    FROM
        InputMeasurevw AS e
    LEFT JOIN
        Settingsvw AS s
        ON
            e.PA = s.PA
    --- Join all Emissions table quarters within each measure's EUL:
    LEFT JOIN
        E3EmissionsSourcevw AS em
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
            dbo.Qidx(em.Qtr) >= dbo.Qidx(e.Qtr)
        AND
            --- Quarterly records in emissions table before measure installation + EUL:
            dbo.Qidx(em.Qtr) < dbo.Qidx(e.Qtr) + e.EULq
    WHERE
        e.CET_ID IS NOT NULL
    AND
        s.Version = @AVCVersion
    ORDER BY
        e.PA
        ,e.PrgID
        ,e.CET_ID
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
DROP FUNCTION dbo.Qidx