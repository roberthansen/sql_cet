USE EDStaff_CET_2020
GO

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
-- Copyright ©      :  Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
-- Change History   :  06/30/2016  Wayne Hauck added comment header
--                     12/31/2019  Robert Hansen reformatted and added comments to code
--                     
--#################################################################################################


CREATE PROCEDURE [dbo].[CalcEmissions]
@JobID INT = -1,
@MEBens FLOAT=NULL, -- market effects benefits
@AVCVersion VARCHAR(255) 

AS

SET NOCOUNT ON

--Clear Output
DELETE FROM OutputEmissions WHERE JobID = @JobID
DELETE FROM SavedEmissions WHERE JobID = @JobID

-- If no Market Effects is passed, check the Jobs table
IF @MEBens Is Null
    BEGIN
        SET @MEBens = IsNull((SELECT MarketEffectBens from CETJobs WHERE ID = @JobID),0)
    END 

PRINT 'Inserting electrical and gas emissions...'

CREATE TABLE [#OutputEmissions](
    [JobID] [int] NULL,
    [PA] [nvarchar](8) NULL,
    [PrgID] [nvarchar](255) NULL,
    [CET_ID] [nvarchar](255) NOT NULL,
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


--***********  Insert Emissions into temp table for em.CZ <> 'NA' AND em.TS <> '0'  ***************
SELECT DISTINCT  s.[Version]
        ,em.PA
        , e.CET_ID
        , e.PrgID
        , e.TS
        , e.EU
        , e.CZ
        , IsNull(em.CO2,0) As CO2
        , IsNull(em.NOx,0) AS NOx
        , IsNull(em.PM10,0) AS PM10
INTO #tmp1
FROM dbo.E3Settings s
LEFT JOIN  E3EmissionsSourcevw em  ON s.[PA] = em.[PA] and s.[Version] = em.[Version] 
LEFT JOIN dbo.InputMeasurevw AS e ON em.Qtr = e.Qtr and  em.PA + CASE WHEN em.EU like 'Non_res:DEER%' THEN 'Non_res' ELSE  CASE WHEN em.EU like 'res:DEER%' THEN 'Res' ELSE  em.TS END END + CASE WHEN em.EU like 'Non_res:DEER%' THEN Replace(em.EU,'Non_Res:','') ELSE  CASE WHEN em.EU like 'res:DEER%' THEN Replace(em.EU,'res:','') ELSE  em.EU END END + em.CZ = e.PA + e.TS + e.EU + RTrim(e.CZ)
WHERE CET_ID Is Not Null
AND s.[Version] = @AVCVersion
--- When would TS (Target Sector?) be '0' rather than '' or null?
AND em.CZ <> 'NA' AND em.TS <> '0'


BEGIN
    -- Insert into CE Emissions
    INSERT INTO dbo.#OutputEmissions (
    JobID,
    PA,
    PrgID,
    CET_ID,
    NetElecCO2,
    NetGasCO2,
    GrossElecCO2,
    GrossGasCO2,
    NetElecCO2Lifecycle,
    NetGasCO2Lifecycle,
    GrossElecCO2Lifecycle,
    GrossGasCO2Lifecycle,
    NetElecNOx,
    NetGasNOx,
    GrossElecNOx,
    GrossGasNOx,
    NetElecNOxLifecycle,
    NetGasNOxLifecycle,
    GrossElecNOxLifecycle,
    GrossGasNOxLifecycle,
    NetPM10,
    GrossPM10,
    NetPM10Lifecycle,
    GrossPM10Lifecycle
        )
        SELECT
        @JobID
        ,e.PA
        ,e.PrgID
        ,e.CET_ID
-------------------------------------------------------------------------------
--- NetElecCO2 ----------------------------------------------------------------
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.CO2 *
                                --- The following term appears to be a
                                --- weighting factor which applies lifecycle
                                --- savings in two phases to the calculation of
                                --- first year savings. Should this instead
                                --- calculate savings only in the first year,
                                --- i.e., RUL only or EUL less RUL?
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 )+
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        -- The following eul value should match CASE statement above:
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce (e.MEBens, @MEBens )
                                ) *
                                em.CO2 *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as NetElecCO2
-------------------------------------------------------------------------------
--- NetGasCO2 -----------------------------------------------------------------
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRThm +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                s.CO2Gas  *
                                --- The following term appears to be a
                                --- weighting factor which applies lifecycle
                                --- savings in two phases to the calculation of
                                --- first year savings. Should this instead
                                --- calculate savings only in the first year,
                                --- i.e., RUL only or EUL less RUL?
                                (
                                    IRThm *
                                    RRThm *
                                    e.Thm1 *
                                    IsNull( rul, 0 ) +
                                    IRThm *
                                    RRThm *
                                    e.Thm2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRThm +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                s.CO2Gas *
                                IRkWh *
                                RRkWh *
                                e.Thm1
                            ELSE 0
                        END
                END,
                0
            )
        ) as NetGasCO2
-------------------------------------------------------------------------------
--- GrossElecCO2 --------------------------------------------------------------
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.CO2 *
                                --- The following term appears to be a
                                --- weighting factor which applies lifecycle
                                --- savings in two phases to the calculation of
                                --- first year savings. Should this instead
                                --- calculate savings only in the first year,
                                --- i.e., rul only or eul less rul?
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.CO2 *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as GrossElecCO2
-------------------------------------------------------------------------------
--- GrossGasCO2 ---------------------------------------------------------------
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                s.CO2Gas *
                                --- The following term appears to be a
                                --- weighting factor which applies lifecycle
                                --- savings in two phases to the calculation of
                                --- first year savings. Should this instead
                                --- calculate savings only in the first year,
                                --- i.e., rul only or eul less rul?
                                (
                                    IRThm *
                                    RRThm *
                                    e.Thm1 *
                                    IsNull( rul, 0 ) +
                                    IRThm *
                                    RRThm *
                                    e.Thm2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                s.CO2Gas *
                                IRThm *
                                RRThm *
                                e.Thm1
                            ELSE 0
                        END
                END,
                0
            )
        ) as GrossGasCO2
-------------------------------------------------------------------------------
--- NetElecCO2Lifecycle -------------------------------------------------------
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                --- Unclear why the following instance of eul is
                                --- limited to the range (0,1) for lifecycle
                                --- savings (Note that the effect of this term, if
                                --- any, will be to reduce calculated savings):
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.CO2 *
                                --- This second instance of eul is cancelled by
                                --- the denominator:
                                eul *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    --- The following term does not apply IR
                                    --- and RR values, differing from other
                                    --- field calculations:
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                --- Unclear why the following instance of eul is
                                --- limited to the range (0,1) for lifecycle
                                --- savings (Note that the effect of this term, if
                                --- any, will be to reduce calculated savings):
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.CO2 *
                                --- Second instance of an EUL term in numerator:
                                eul *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as NetElecCO2Lifecycle
-------------------------------------------------------------------------------
--- NetGasCO2Lifecycle --------------------------------------------------------
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                --- Unclear why the following instance of eul is
                                --- limited to the range (0,1) for lifecycle
                                --- savings (Note that the effect of this term, if
                                --- any, will be to reduce calculated savings):
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRThm +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                s.CO2Gas *
                                --- This second instance of eul is cancelled by
                                --- the denominator:
                                eul *
                                (
                                    IRThm *
                                    RRThm *
                                    e.Thm1 *
                                    IsNull( rul, 0 ) +
                                    IRThm *
                                    RRThm *
                                    e.Thm2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                --- Unclear why the following instance of eul is
                                --- limited to the range (0,1) for lifecycle
                                --- savings (Note that the effect of this term, if
                                --- any, will be to reduce calculated savings):
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRThm +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                s.CO2Gas *
                                --- Second instance of an EUL term in numerator:
                                eul *
                                IRThm *
                                RRThm *
                                e.Thm1
                            ELSE 0
                        END
                END,
                0
            )
        ) as NetGasCO2Lifecycle
-------------------------------------------------------------------------------
--- GrossElecCO2Lifecycle -----------------------------------------------------
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                --- Unclear why the following instance of eul is
                                --- limited to the range (0,1) for lifecycle
                                --- savings (Note that the effect of this term, if
                                --- any, will be to reduce calculated savings):
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.CO2 *
                                eul *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                --- Unclear why the following instance of eul is
                                --- limited to the range (0,1) for lifecycle
                                --- savings (Note that the effect of this term, if
                                --- any, will be to reduce calculated savings):
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.CO2 *
                                --- Second instance of an EUL term in numerator:
                                eul *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as GrossElecCO2Lifecycle
-------------------------------------------------------------------------------
--- GrossGasCO2Lifecycle ------------------------------------------------------
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                --- Unclear why the following instance of eul is
                                --- limited to the range (0,1) for lifecycle
                                --- savings (Note that the effect of this term, if
                                --- any, will be to reduce calculated savings):
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                s.CO2Gas *
                                --- This second instance of eul is cancelled by
                                --- the denominator:
                                eul *
                                (
                                    IRThm *
                                    RRThm *
                                    e.Thm1 *
                                    IsNull( rul, 0 ) +
                                    IRThm *
                                    RRThm *
                                    e.Thm2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                --- Unclear why the following instance of eul is
                                --- limited to the range (0,1) for lifecycle
                                --- savings (Note that the effect of this term, if
                                --- any, will be to reduce calculated savings):
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                s.CO2Gas *
                                --- Second instance of an EUL term in numerator:
                                eul *
                                IRThm *
                                RRThm *
                                e.Thm1
                            ELSE 0
                        END
                END,
                0
            )
        ) as GrossGasCO2Lifecycle
-------------------------------------------------------------------------------
--- NetElecNOx ----------------------------------------------------------------
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.NOx *
                                --- The following term appears to be a
                                --- weighting factor which applies lifecycle
                                --- savings in two phases to the calculation of
                                --- first year savings. Should this instead
                                --- calculate savings only in the first year,
                                --- i.e., rul only or eul less rul?
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.NOx *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as NetElecNOx
-------------------------------------------------------------------------------
--- NetGasNOx -----------------------------------------------------------------
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRThm +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                eg.NOxGas *
                                (
                                    IRThm *
                                    RRThm *
                                    e.Thm1 *
                                    IsNull( rul, 0 ) +
                                    IRThm *
                                    RRThm *
                                    e.Thm2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRThm +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                eg.NOxGas *
                                IRThm *
                                RRThm *
                                e.Thm1
                            ELSE 0
                        END
                END,
                0
            )
        ) as NetGasNOx
-------------------------------------------------------------------------------
--- GrossElecNOx --------------------------------------------------------------
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.NOx *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.NOx *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as GrossElecNOx
-------------------------------------------------------------------------------
--- GrossGasNOx ---------------------------------------------------------------
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                eg.NOxGas *
                                (
                                    IRThm *
                                    RRThm *
                                    e.Thm1 *
                                    IsNull( rul, 0 ) +
                                    IRThm *
                                    RRThm *
                                    e.Thm2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                eg.NOxGas *
                                IRThm *
                                RRThm *
                                e.Thm1
                            ELSE 0
                        END
                END,
                0
            )
        ) as GrossGasNOx
-------------------------------------------------------------------------------
--- NetElecNOxLifecycle -------------------------------------------------------
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                --- Unclear why the following instance of eul is
                                --- limited to the range (0,1) for lifecycle
                                --- savings (Note that the effect of this term, if
                                --- any, will be to reduce calculated savings):
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.NOx *
                                --- This second instance of eul is cancelled by
                                --- the denominator:
                                eul *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.NOx *
                                --- Second instance of an EUL term in numerator:
                                eul *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as NetElecNOxLifecycle
-------------------------------------------------------------------------------
--- NetGasNOxLifecycle --------------------------------------------------------
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                --- Unclear why the following instance of eul is
                                --- limited to the range (0,1) for lifecycle
                                --- savings (Note that the effect of this term, if
                                --- any, will be to reduce calculated savings):
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRThm +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                eg.NOxGas *
                                --- This second instance of eul is cancelled by
                                --- the denominator:
                                eul *
                                (
                                    IRThm *
                                    RRThm *
                                    e.Thm1 *
                                    IsNull( rul, 0 ) +
                                    IRThm *
                                    RRThm *
                                    e.Thm2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                --- Unclear why the following instance of eul is
                                --- limited to the range (0,1) for lifecycle
                                --- savings (Note that the effect of this term, if
                                --- any, will be to reduce calculated savings):
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRThm +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                eg.NOxGas *
                                eul *
                                IRThm *
                                RRThm *
                                e.Thm1
                            ELSE 0
                        END
                END,
                0
            )
        ) as NetGasNOxLifecycle
-------------------------------------------------------------------------------
--- GrossElecNOxLifecycle -----------------------------------------------------
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                --- Unclear why the following instance of eul is
                                --- limited to the range (0,1) for lifecycle
                                --- savings (Note that the effect of this term, if
                                --- any, will be to reduce calculated savings):
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.NOx *
                                --- This second instance of eul is cancelled by
                                --- the denominator:
                                eul *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                --- Unclear why the following instance of eul is
                                --- limited to the range (0,1) for lifecycle
                                --- savings (Note that the effect of this term, if
                                --- any, will be to reduce calculated savings):
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.NOx *
                                --- Second instance of an EUL term in numerator:
                                eul *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as GrossElecNOxLifecycle
-------------------------------------------------------------------------------
--- GrossGasNOxLifecycle ------------------------------------------------------
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                --- Unclear why the following instance of eul is
                                --- limited to the range (0,1) for lifecycle
                                --- savings (Note that the effect of this term, if
                                --- any, will be to reduce calculated savings):
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                eg.NOxGas *
                                --- This second instance of eul is cancelled by
                                --- the denominator:
                                eul *
                                (
                                    IRThm *
                                    RRThm *
                                    e.Thm1 *
                                    IsNull( rul, 0 ) +
                                    IRThm *
                                    RRThm *
                                    e.Thm2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                --- Unclear why the following instance of eul is
                                --- limited to the range (0,1) for lifecycle
                                --- savings (Note that the effect of this term, if
                                --- any, will be to reduce calculated savings):
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                eg.NOxGas *
                                --- Second instance of an EUL term in numerator:
                                eul *
                                IRThm *
                                RRThm *
                                e.Thm1
                            ELSE 0
                        END
                END,
                0
            )
        ) as GrossGasNOxLifecycle
-------------------------------------------------------------------------------
--- NetPM10 -------------------------------------------------------------------
        --- This calculates PM10 savings accounting for electric savings only.
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.PM10 *
                                --- The following term appears to be a
                                --- weighting factor which applies lifecycle
                                --- savings in two phases to the calculation of
                                --- first year savings. Should this instead
                                --- calculate savings only in the first year,
                                --- i.e., RUL only or EUL less RUL?
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        -- The following eul value should match CASE statement above:
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.PM10 *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as NetPM10
-------------------------------------------------------------------------------
--- GrossPM10 -----------------------------------------------------------------
        --- This calculates PM10 savings accounting for electric savings only.
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.PM10 *
                                --- The following term appears to be a
                                --- weighting factor which applies lifecycle
                                --- savings in two phases to the calculation of
                                --- first year savings. Should this instead
                                --- calculate savings only in the first year,
                                --- i.e., rul only or eul less rul?
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.PM10 *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as GrossPM10
-------------------------------------------------------------------------------
--- NetPM10Lifecycle ----------------------------------------------------------
        --- This calculates PM10 savings accounting for electric savings only.
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                --- Unclear why the following instance of eul is
                                --- limited to the range (0,1) for lifecycle
                                --- savings (Note that the effect of this term, if
                                --- any, will be to reduce calculated savings):
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.PM10 *
                                --- This second instance of eul is cancelled by
                                --- the denominator:
                                eul *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                --- Unclear why the following instance of eul is
                                --- limited to the range (0,1) for lifecycle
                                --- savings (Note that the effect of this term, if
                                --- any, will be to reduce calculated savings):
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.PM10 *
                                --- Second instance of an EUL term in numerator:
                                eul *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as NetPM10Lifecycle
-------------------------------------------------------------------------------
--- GrossPM10Lifecycle --------------------------------------------------------
        --- This calculates PM10 savings accounting for electric savings only.
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                --- Unclear why the following instance of eul is
                                --- limited to the range (0,1) for lifecycle
                                --- savings (Note that the effect of this term, if
                                --- any, will be to reduce calculated savings):
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.PM10 *
                                --- This second instance of eul is cancelled by
                                --- the denominator:
                                eul *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                --- Unclear why the following instance of eul is
                                --- limited to the range (0,1) for lifecycle
                                --- savings (Note that the effect of this term, if
                                --- any, will be to reduce calculated savings):
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.PM10 *
                                --- Second instance of an EUL term in numerator:
                                eul *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as GrossPM10Lifecycle
-------------------------------------------------------------------------------
    FROM InputMeasurevw e
    LEFT JOIN Settingsvw s ON e.PA = s.PA
    LEFT JOIN #tmp1 em ON e.CET_ID = em.CET_ID
    LEFT JOIN E3CombustionTypevw eg ON e.CET_ID = eg.CET_ID
    WHERE e.CET_ID is not null
    AND s.[Version] = @AVCVersion
    GROUP BY e.PA
        ,e.PrgID
        ,e.CET_ID
    ORDER BY e.PA
        ,e.PrgID
        ,e.CET_ID
END

DROP Table #tmp1

--***********  Insert Emissions into temp table for em.CZ = 'NA' and em.TS <> '0' and ((e.PA = 'SDGE' AND e.CZ <> 'System') OR e.PA <> 'SDGE')   ***************
SELECT DISTINCT s.Version
        ,em.PA
        , e.CET_ID
        , e.PrgID
        , e.TS
        , e.EU
        , e.CZ
        , IsNull(em.CO2,0) As CO2
        , IsNull(em.NOx,0) AS NOx
        , IsNull(em.PM10,0) AS PM10
INTO #tmp2
FROM    dbo.Settingsvw AS s 
LEFT JOIN  E3EmissionsSourcevw em  ON s.[PA] = em.[PA] and s.[Version] = em.[Version]
LEFT JOIN dbo.InputMeasurevw AS e ON em.Qtr = e.Qtr and  em.PA + CASE WHEN em.EU like 'Non_res:DEER%' THEN 'Non_res' ELSE  CASE WHEN em.EU like 'res:DEER%' THEN 'Res' ELSE  em.TS END END + CASE WHEN em.EU like 'Non_res:DEER%' THEN Replace(em.EU,'Non_Res:','') ELSE  CASE WHEN em.EU like 'res:DEER%' THEN Replace(em.EU,'res:','') ELSE  em.EU END END + em.CZ = e.PA + e.TS + e.EU + RTrim(e.CZ)
WHERE CET_ID Is Not Null
AND s.[Version] = @AVCVersion
--- This is the only iteration of #OutputEmissions which stipulates PA, potentially
--- resulting in exclusion of measures where PA=='SDGE' and CZ=='System'.
---
--- [ ] Verify exclusion is intentional, or
--- [ ] Ensure all possible inputs are handled correctly
---
--- When would TS (Target Sector?) be '0' rather than '' or null?
AND em.CZ = 'NA' and em.TS <> '0' and ((e.PA = 'SDGE' AND e.CZ <> 'System') OR e.PA <> 'SDGE')

BEGIN
    -- Insert into CE Emissions
    INSERT INTO dbo.#OutputEmissions (
    JobID,
    PA,
    PrgID,
    CET_ID,
    NetElecCO2,
    NetGasCO2,
    GrossElecCO2,
    GrossGasCO2,
    NetElecCO2Lifecycle,
    NetGasCO2Lifecycle,
    GrossElecCO2Lifecycle,
    GrossGasCO2Lifecycle,
    NetElecNOx,
    NetGasNOx,
    GrossElecNOx,
    GrossGasNOx,
    NetElecNOxLifecycle,
    NetGasNOxLifecycle,
    GrossElecNOxLifecycle,
    GrossGasNOxLifecycle,
    NetPM10,
    GrossPM10,
    NetPM10Lifecycle,
    GrossPM10Lifecycle
        )
        SELECT
        @JobID
        ,e.PA
        ,e.PrgID
        ,e.CET_ID
--- NetElecCO2 ----------------------------------------------------------------
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.CO2 *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.CO2 *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as NetElecCO2
-------------------------------------------------------------------------------
--- NetGasCO2 -----------------------------------------------------------------
        --- Why is this value 0 when Climate Zone = 'NA' and Target Sector = '0'?
        ,0 as NetGasCO2
-------------------------------------------------------------------------------
--- GrossElecCO2 --------------------------------------------------------------
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.CO2 *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.CO2 *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as GrossElecCO2
-------------------------------------------------------------------------------
--- GrossGasCO2 ---------------------------------------------------------------
        --- Why is this value 0 when Climate Zone = 'NA' and Target Sector = '0'?
        ,0 as GrossGasCO2
-------------------------------------------------------------------------------
--- NetElecCO2Lifecycle -------------------------------------------------------
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.CO2 *
                                eul *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.CO2 *
                                eul *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as NetElecCO2Lifecycle
-------------------------------------------------------------------------------
--- NetGasCO2Lifecycle --------------------------------------------------------
        --- Why is this value 0 when Climate Zone = 'NA' and Target Sector = '0'?
        ,0 as NetGasCO2Lifecycle
-------------------------------------------------------------------------------
--- GrossElecCO2Lifecycle -----------------------------------------------------
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.CO2 *
                                eul *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.CO2 *
                                eul *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as GrossElecCO2Lifecycle
-------------------------------------------------------------------------------
--- GrossGasCO2Lifecycle ------------------------------------------------------
        --- Why is this value 0 when Climate Zone = 'NA' and Target Sector = '0'?
        ,0 as GrossGasCO2Lifecycle
-------------------------------------------------------------------------------
--- NetElecNOx ----------------------------------------------------------------
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.NOx *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.NOx *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as NetElecNOx
-------------------------------------------------------------------------------
--- NetGasNOx -----------------------------------------------------------------
        --- Why is this value 0 when Climate Zone = 'NA' and Target Sector = '0'?
        ,0 as NetGasNOx
-------------------------------------------------------------------------------
--- GrossElecNOx --------------------------------------------------------------
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.NOx *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.NOx *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as GrossElecNOx
-------------------------------------------------------------------------------
--- GrossGasNOx ---------------------------------------------------------------
        --- Why is this value 0 when Climate Zone = 'NA' and Target Sector = '0'?
        ,0 as GrossGasNOx
-------------------------------------------------------------------------------
--- NetElecNOxLifecycle -------------------------------------------------------
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.NOx *
                                eul *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.NOx *
                                eul *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as NetElecNOxLifecycle
-------------------------------------------------------------------------------
--- NetGasNOxLifecycle --------------------------------------------------------
        --- Why is this value 0 when Climate Zone = 'NA' and Target Sector = '0'?
        ,0 as NetGasNOxLifecycle
-------------------------------------------------------------------------------
--- GrossElecNOxLifecycle -----------------------------------------------------
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.NOx *
                                eul *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.NOx *
                                eul *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as GrossElecNOxLifecycle
-------------------------------------------------------------------------------
--- GrossGasNOxLifecycle ------------------------------------------------------
        --- Why is this value 0 when Climate Zone = 'NA' and Target Sector = '0'?
        ,0 as GrossGasNOxLifecycle
-------------------------------------------------------------------------------
--- NetPM10 -------------------------------------------------------------------
        --- This calculates PM10 savings accounting for electric savings only.
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.PM10 *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.PM10 *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as NetPM10
-------------------------------------------------------------------------------
--- GrossPM10 -----------------------------------------------------------------
        --- This calculates PM10 savings accounting for electric savings only.
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.PM10 *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.PM10 *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as GrossPM10
-------------------------------------------------------------------------------
--- NetPM10Lifecycle ----------------------------------------------------------
        --- This calculates PM10 savings accounting for electric savings only.
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.PM10 *
                                eul *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.PM10 *
                                eul *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as NetPM10Lifecycle
-------------------------------------------------------------------------------
--- GrossPM10Lifecycle --------------------------------------------------------
        --- This calculates PM10 savings accounting for electric savings only.
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.PM10 *
                                eul *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.PM10 *
                                eul *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as GrossPM10Lifecycle
-------------------------------------------------------------------------------
    FROM InputMeasurevw e
    LEFT JOIN Settingsvw s ON e.PA = s.PA
    LEFT JOIN #tmp2 em ON e.CET_ID = em.CET_ID
    LEFT JOIN E3CombustionTypevw eg ON e.CET_ID = eg.CET_ID
    WHERE e.CET_ID is not null 
    AND s.[Version] = @AVCVersion
    GROUP BY e.PA
        ,e.PrgID
        ,e.CET_ID
    ORDER BY e.PA
        ,e.PrgID
        ,e.CET_ID
END

DROP Table #tmp2

--***********  Insert Emissions into temp table for em.CZ <> 'NA' AND em.TS = '0'  ***************
SELECT DISTINCT s.Version
        ,em.PA
        , e.CET_ID
        , e.PrgID
        , e.TS
        , e.EU
        , e.CZ
        , IsNull(em.CO2,0) As CO2
        , IsNull(em.NOx,0) AS NOx
        , IsNull(em.PM10,0) AS PM10
INTO #tmp3
FROM    dbo.E3Settings AS s 
LEFT JOIN  E3EmissionsSourcevw em  ON s.[PA] = em.[PA] and s.[Version] = em.[Version] 
LEFT JOIN dbo.InputMeasurevw AS e ON em.Qtr = e.Qtr and  em.PA + CASE WHEN em.EU like 'Non_res:DEER%' THEN 'Non_res' ELSE  CASE WHEN em.EU like 'res:DEER%' THEN 'Res' ELSE  em.TS END END + CASE WHEN em.EU like 'Non_res:DEER%' THEN Replace(em.EU,'Non_Res:','') ELSE  CASE WHEN em.EU like 'res:DEER%' THEN Replace(em.EU,'res:','') ELSE  em.EU END END + em.CZ = e.PA + e.TS + e.EU + RTrim(e.CZ)
WHERE CET_ID Is Not Null
AND s.[Version] = @AVCVersion
--- When would TS (Target Sector?) be '0' rather than '' or null?
AND em.CZ <> 'NA' AND em.TS = '0'

BEGIN
    -- Insert into CE Emissions
    INSERT INTO dbo.#OutputEmissions (
    JobID,
    PA,
    PrgID,
    CET_ID,
    NetElecCO2,
    NetGasCO2,
    GrossElecCO2,
    GrossGasCO2,
    NetElecCO2Lifecycle,
    NetGasCO2Lifecycle,
    GrossElecCO2Lifecycle,
    GrossGasCO2Lifecycle,
    NetElecNOx,
    NetGasNOx,
    GrossElecNOx,
    GrossGasNOx,
    NetElecNOxLifecycle,
    NetGasNOxLifecycle,
    GrossElecNOxLifecycle,
    GrossGasNOxLifecycle,
    NetPM10,
    GrossPM10,
    NetPM10Lifecycle,
    GrossPM10Lifecycle
        )
        SELECT
        @JobID
        ,e.PA
        ,e.PrgID
        ,e.CET_ID
-------------------------------------------------------------------------------
--- NetElecCO2 ----------------------------------------------------------------
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.CO2 *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.CO2 *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,0
            )
        ) as NetElecCO2
-------------------------------------------------------------------------------
--- NetGasCO2 -----------------------------------------------------------------
        --- Why is this value 0 when Climate Zone = 'NA' and Target Sector = '0'?
        ,0 as NetGasCO2
-------------------------------------------------------------------------------
--- GrossElecCO2 --------------------------------------------------------------
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.CO2 *
                                --- The following term appears to be a
                                --- weighting factor which applies lifecycle
                                --- savings in two phases to the calculation of
                                --- first year savings. Should this instead
                                --- calculate savings only in the first year,
                                --- i.e., rul only or eul less rul?
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.CO2 *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as GrossElecCO2
-------------------------------------------------------------------------------
--- GrossGasCO2 ---------------------------------------------------------------
        --- Why is this value 0 when Climate Zone = 'NA' and Target Sector = '0'?
        ,0 as GrossGasCO2
-------------------------------------------------------------------------------
--- NetElecCO2Lifecycle -------------------------------------------------------
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                --- Unclear why the following instance of eul is
                                --- limited to the range (0,1) for lifecycle
                                --- savings (Note that the effect of this term, if
                                --- any, will be to reduce calculated savings):
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.CO2 *
                                --- This second instance of eul is cancelled by
                                --- the denominator:
                                eul *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    --- The following term does not apply IR
                                    --- and RR values, differing from other
                                    --- field calculations:
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                --- Unclear why the following instance of eul is
                                --- limited to the range (0,1) for lifecycle
                                --- savings (Note that the effect of this term, if
                                --- any, will be to reduce calculated savings):
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.CO2 *
                                --- Second instance of an EUL term in numerator:
                                eul *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as NetElecCO2Lifecycle
-------------------------------------------------------------------------------
--- NetGasCO2Lifecycle --------------------------------------------------------
        --- Why is this value 0 when Climate Zone = 'NA' and Target Sector = '0'?
        ,0 as NetGasCO2Lifecycle
-------------------------------------------------------------------------------
--- GrossElecCO2Lifecycle -----------------------------------------------------
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                --- Unclear why the following instance of eul is
                                --- limited to the range (0,1) for lifecycle
                                --- savings (Note that the effect of this term, if
                                --- any, will be to reduce calculated savings):
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.CO2 *
                                eul *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                --- Unclear why the following instance of eul is
                                --- limited to the range (0,1) for lifecycle
                                --- savings (Note that the effect of this term, if
                                --- any, will be to reduce calculated savings):
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.CO2 *
                                --- Second instance of an EUL term in numerator:
                                eul *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as GrossElecCO2Lifecycle
-------------------------------------------------------------------------------
--- GrossGasCO2Lifecycle ------------------------------------------------------
        --- Why is this value 0 when Climate Zone = 'NA' and Target Sector = '0'?
        ,0 as GrossGasCO2Lifecycle
-------------------------------------------------------------------------------
--- NetElecNOx ----------------------------------------------------------------
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.NOx *
                                --- The following term appears to be a
                                --- weighting factor which applies lifecycle
                                --- savings in two phases to the calculation of
                                --- first year savings. Should this instead
                                --- calculate savings only in the first year,
                                --- i.e., rul only or eul less rul?
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.NOx *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as NetElecNOx
-------------------------------------------------------------------------------
--- NetGasNOx -----------------------------------------------------------------
        --- Why is this value 0 when Climate Zone = 'NA' and Target Sector = '0'?
        ,0 as NetGasNOx
-------------------------------------------------------------------------------
--- GrossElecNOx --------------------------------------------------------------
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.NOx *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.NOx *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as GrossElecNOx
-------------------------------------------------------------------------------
--- GrossGasNOx ---------------------------------------------------------------
        --- Why is this value 0 when Climate Zone = 'NA' and Target Sector = '0'?
        ,0 as GrossGasNOx
-------------------------------------------------------------------------------
--- NetElecNOxLifecycle -------------------------------------------------------
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                --- Unclear why the following instance of eul is
                                --- limited to the range (0,1) for lifecycle
                                --- savings (Note that the effect of this term, if
                                --- any, will be to reduce calculated savings):
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.NOx *
                                --- This second instance of eul is cancelled by
                                --- the denominator:
                                eul *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.NOx *
                                --- Second instance of an EUL term in numerator:
                                eul *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as NetElecNOxLifecycle
-------------------------------------------------------------------------------
--- NetGasNOxLifecycle --------------------------------------------------------
        --- Why is this value 0 when Climate Zone = 'NA' and Target Sector = '0'?
        ,0 as NetGasNOxLifecycle
-------------------------------------------------------------------------------
--- GrossElecNOxLifecycle -----------------------------------------------------
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                --- Unclear why the following instance of eul is
                                --- limited to the range (0,1) for lifecycle
                                --- savings (Note that the effect of this term, if
                                --- any, will be to reduce calculated savings):
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.NOx *
                                --- This second instance of eul is cancelled by
                                --- the denominator:
                                eul *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                --- Unclear why the following instance of eul is
                                --- limited to the range (0,1) for lifecycle
                                --- savings (Note that the effect of this term, if
                                --- any, will be to reduce calculated savings):
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.NOx *
                                --- Second instance of an EUL term in numerator:
                                eul *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as GrossElecNOxLifecycle
-------------------------------------------------------------------------------
--- GrossGasNOxLifecycle ------------------------------------------------------
        --- Why is this value 0 when Climate Zone = 'NA' and Target Sector = '0'?
        ,0 as GrossGasNOxLifecycle
-------------------------------------------------------------------------------
--- NetPM10 -------------------------------------------------------------------
        --- This calculates PM10 savings accounting for electric savings only.
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.PM10 *
                                --- The following term appears to be a
                                --- weighting factor which applies lifecycle
                                --- savings in two phases to the calculation of
                                --- first year savings. Should this instead
                                --- calculate savings only in the first year,
                                --- i.e., RUL only or EUL less RUL?
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        -- The following eul value should match CASE statement above:
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.PM10 *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as NetPM10
-------------------------------------------------------------------------------
--- GrossPM10 -----------------------------------------------------------------
        --- This calculates PM10 savings accounting for electric savings only.
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.PM10 *
                                --- The following term appears to be a
                                --- weighting factor which applies lifecycle
                                --- savings in two phases to the calculation of
                                --- first year savings. Should this instead
                                --- calculate savings only in the first year,
                                --- i.e., rul only or eul less rul?
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.PM10 *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as GrossPM10
-------------------------------------------------------------------------------
--- NetPM10Lifecycle ----------------------------------------------------------
        --- This calculates PM10 savings accounting for electric savings only.
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                --- Unclear why the following instance of eul is
                                --- limited to the range (0,1) for lifecycle
                                --- savings (Note that the effect of this term, if
                                --- any, will be to reduce calculated savings):
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.PM10 *
                                --- This second instance of eul is cancelled by
                                --- the denominator:
                                eul *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                --- Unclear why the following instance of eul is
                                --- limited to the range (0,1) for lifecycle
                                --- savings (Note that the effect of this term, if
                                --- any, will be to reduce calculated savings):
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.PM10 *
                                --- Second instance of an EUL term in numerator:
                                eul *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as NetPM10Lifecycle
-------------------------------------------------------------------------------
--- GrossPM10Lifecycle --------------------------------------------------------
        --- This calculates PM10 savings accounting for electric savings only.
        ,Sum(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                --- Unclear why the following instance of eul is
                                --- limited to the range (0,1) for lifecycle
                                --- savings (Note that the effect of this term, if
                                --- any, will be to reduce calculated savings):
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.PM10 *
                                --- This second instance of eul is cancelled by
                                --- the denominator:
                                eul *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                --- Unclear why the following instance of eul is
                                --- limited to the range (0,1) for lifecycle
                                --- savings (Note that the effect of this term, if
                                --- any, will be to reduce calculated savings):
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.PM10 *
                                --- Second instance of an EUL term in numerator:
                                eul *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) as GrossPM10Lifecycle
-------------------------------------------------------------------------------
    FROM InputMeasurevw e
    LEFT JOIN Settingsvw s ON e.PA = s.PA
    LEFT JOIN #tmp3 em ON e.CET_ID = em.CET_ID
    LEFT JOIN E3CombustionTypevw eg ON e.CET_ID = eg.CET_ID
    WHERE e.CET_ID is not null
    AND s.[Version] = @AVCVersion
    GROUP BY e.PA
        ,e.PrgID
        ,e.CET_ID
    ORDER BY e.PA
        ,e.PrgID
        ,e.CET_ID
END


DROP Table #tmp3

--***********  Insert Emissions into temp table for em.CZ = 'NA' AND em.TS = '0'   ***************
SELECT DISTINCT s.Version
        ,em.PA
        , e.CET_ID
        , e.PrgID
        , e.TS
        , e.EU
        , e.CZ
        , IsNull(em.CO2,0) As CO2
        , IsNull(em.NOx,0) AS NOx
        , IsNull(em.PM10,0) AS PM10
INTO #tmp4
FROM    dbo.E3Settings AS s 
LEFT JOIN  E3EmissionsSourcevw em  ON s.[PA] = em.[PA] and s.[Version] = em.[Version]
LEFT JOIN dbo.InputMeasurevw AS e ON em.Qtr = e.Qtr and  em.PA + CASE WHEN em.EU like 'Non_res:DEER%' THEN 'Non_res' ELSE  CASE WHEN em.EU like 'res:DEER%' THEN 'Res' ELSE  em.TS END END + CASE WHEN em.EU like 'Non_res:DEER%' THEN Replace(em.EU,'Non_Res:','') ELSE  CASE WHEN em.EU like 'res:DEER%' THEN Replace(em.EU,'res:','') ELSE  em.EU END END + em.CZ = e.PA + e.TS + e.EU + RTrim(e.CZ)
WHERE CET_ID Is Not Null
AND s.[Version] = @AVCVersion
--- When would TS (Target Sector?) be '0' rather than '' or null?
AND em.CZ = 'NA' AND em.TS = '0'


-------------------------------------------------------------------------------
--- Final Iteration of #OutputEmissions ---------------------------------------
BEGIN
    -- Insert into CE Emissions
    INSERT INTO dbo.#OutputEmissions (
        JobID,
        PA,
        PrgID,
        CET_ID,
        NetElecCO2,
        NetGasCO2,
        GrossElecCO2,
        GrossGasCO2,
        NetElecCO2Lifecycle,
        NetGasCO2Lifecycle,
        GrossElecCO2Lifecycle,
        GrossGasCO2Lifecycle,
        NetElecNOx,
        NetGasNOx,
        GrossElecNOx,
        GrossGasNOx,
        NetElecNOxLifecycle,
        NetGasNOxLifecycle,
        GrossElecNOxLifecycle,
        GrossGasNOxLifecycle,
        NetPM10,
        GrossPM10,
        NetPM10Lifecycle,
        GrossPM10Lifecycle
    )
    SELECT
        @JobID
        ,e.PA
        ,e.PrgID
        ,e.CET_ID
-------------------------------------------------------------------------------
--- NetElecCO2 ----------------------------------------------------------------
        ,SUM(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.CO2 *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.CO2 *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) AS NetElecCO2
-------------------------------------------------------------------------------
--- NetGasCO2 -----------------------------------------------------------------
        --- Why is this value 0 when Climate Zone = 'NA' and Target Sector = '0'?
        ,0 AS NetGasCO2
-------------------------------------------------------------------------------
--- GrossElecCO2 --------------------------------------------------------------
        ,SUM(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.CO2 *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.CO2 *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) AS GrossElecCO2
-------------------------------------------------------------------------------
--- GrossGasCO2 ---------------------------------------------------------------
        --- Why is this value 0 when Climate Zone = 'NA' and Target Sector = '0'?
        ,0 AS GrossGasCO2
-------------------------------------------------------------------------------
--- NetElecCO2Lifecycle -------------------------------------------------------
        ,SUM(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.CO2 *
                                eul *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.CO2 *
                                eul *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) AS NetElecCO2Lifecycle
-------------------------------------------------------------------------------
--- NetGasCO2Lifecycle --------------------------------------------------------
        --- Why is this value 0 when Climate Zone = 'NA' and Target Sector = '0'?
        ,0 AS NetGasCO2Lifecycle
-------------------------------------------------------------------------------
--- GrossElecCO2Lifecycle -----------------------------------------------------
        ,SUM(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.CO2 *
                                eul *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.CO2 *
                                eul *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) AS GrossElecCO2Lifecycle
-------------------------------------------------------------------------------
--- GrossGasCO2Lifecycle ------------------------------------------------------
        --- Why is this value 0 when Climate Zone = 'NA' and Target Sector = '0'?
        ,0 AS GrossGasCO2Lifecycle
-------------------------------------------------------------------------------
--- NetElecNOx ----------------------------------------------------------------
        ,SUM(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.NOx *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.NOx *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) AS NetElecNOx
-------------------------------------------------------------------------------
--- NetGasNOx -----------------------------------------------------------------
        --- Why is this value 0 when Climate Zone = 'NA' and Target Sector = '0'?
        ,0 AS NetGasNOx
-------------------------------------------------------------------------------
--- GrossElecNOx --------------------------------------------------------------
        ,SUM(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.NOx *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.NOx *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) AS GrossElecNOx
-------------------------------------------------------------------------------
--- GrossGasNOx ---------------------------------------------------------------
        --- Why is this value 0 when Climate Zone = 'NA' and Target Sector = '0'?
        ,0 AS GrossGasNOx
-------------------------------------------------------------------------------
--- NetElecNOxLifecycle -------------------------------------------------------
        ,SUM(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.NOx *
                                eul *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.NOx *
                                eul *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) AS NetElecNOxLifecycle
-------------------------------------------------------------------------------
--- NetGasNOxLifecycle --------------------------------------------------------
        --- Why is this value 0 when Climate Zone = 'NA' and Target Sector = '0'?
        ,0 AS NetGasNOxLifecycle
-------------------------------------------------------------------------------
--- GrossElecNOxLifecycle -----------------------------------------------------
        ,SUM(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.NOx *
                                eul *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.NOx *
                                eul *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) AS GrossElecNOxLifecycle
-------------------------------------------------------------------------------
--- GrossGasNOxLifecycle ------------------------------------------------------
        --- Why is this value 0 when Climate Zone = 'NA' and Target Sector = '0'?
        ,0 AS GrossGasNOxLifecycle
-------------------------------------------------------------------------------
--- NetPM10 -------------------------------------------------------------------
        --- This calculates PM10 savings accounting for electric savings only.
        ,SUM(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.PM10 *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.PM10 *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) AS NetPM10
-------------------------------------------------------------------------------
--- GrossPM10 -----------------------------------------------------------------
        --- This calculates PM10 savings accounting for electric savings only.
        ,SUM(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.PM10 *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.PM10 *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
            0
        )
    ) AS GrossPM10
-------------------------------------------------------------------------------
--- NetPM10Lifecycle ----------------------------------------------------------
        --- This calculates PM10 savings accounting for electric savings only.
        ,SUM(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.PM10 *
                                eul *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                (
                                    e.NTGRkWh +
                                    Coalesce( e.MEBens, @MEBens )
                                ) *
                                em.PM10 *
                                eul *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) AS NetPM10Lifecycle
-------------------------------------------------------------------------------
--- GrossPM10Lifecycle --------------------------------------------------------
        --- This calculates PM10 savings accounting for electric savings only.
        ,SUM(
            IsNull(
                CASE
                    WHEN IsNull( rul, 0 ) > 0
                    THEN
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.PM10 *
                                eul *
                                (
                                    IRkWh *
                                    RRkWh *
                                    e.kwh1 *
                                    IsNull( rul, 0 ) +
                                    IRkWh *
                                    RRkWh *
                                    e.kwh2 *
                                    (
                                        e.eul -
                                        IsNull( e.rul, 0 )
                                    )
                                ) /
                                e.eul
                            ELSE 0
                        END
                    ELSE
                        CASE
                            WHEN e.eul > 0
                            THEN
                                CASE
                                    WHEN e.eul < 1
                                    THEN e.eul
                                    ELSE 1
                                END *
                                e.Qty *
                                em.PM10 *
                                eul *
                                IRkWh *
                                RRkWh *
                                e.kwh1
                            ELSE 0
                        END
                END,
                0
            )
        ) AS GrossPM10Lifecycle
-------------------------------------------------------------------------------
    FROM InputMeasurevw e
    LEFT JOIN Settingsvw s ON e.PA = s.PA
    LEFT JOIN #tmp4 em ON e.CET_ID = em.CET_ID
    LEFT JOIN E3CombustionTypevw eg ON e.CET_ID = eg.CET_ID
    WHERE e.CET_ID IS NOT NULL
    AND s.[Version] = @AVCVersion
    GROUP BY e.PA
        ,e.PrgID
        ,e.CET_ID
    ORDER BY e.PA
        ,e.PrgID
        ,e.CET_ID
END


INSERT INTO OutputEmissions
SELECT DISTINCT
      [JobID]
      ,[PA]
      ,[PrgID]
      ,[CET_ID]
      ,SUM([NetElecCO2]) [NetElecCO2]
      ,SUM([NetGasCO2]) [NetGasCO2]
      ,SUM([GrossElecCO2]) [GrossElecCO2]
      ,SUM([GrossGasCO2]) [GrossGasCO2]
      ,SUM([NetElecCO2Lifecycle]) [NetElecCO2Lifecycle]
      ,SUM([NetGasCO2Lifecycle]) [NetGasCO2Lifecycle]
      ,SUM([GrossElecCO2Lifecycle]) [GrossElecCO2Lifecycle]
      ,SUM([GrossGasCO2Lifecycle]) [GrossGasCO2Lifecycle]
      ,SUM([NetElecNOx]) [NetElecNOx]
      ,SUM([NetGasNOx]) [NetGasNOx]
      ,SUM([GrossElecNOx]) [GrossElecNOx]
      ,SUM([GrossGasNOx]) [GrossGasNOx]
      ,SUM([NetElecNOxLifecycle]) [NetElecNOxLifecycle]
      ,SUM([NetGasNOxLifecycle]) [NetGasNOxLifecycle]
      ,SUM([GrossElecNOxLifecycle]) [GrossElecNOxLifecycle]
      ,SUM([GrossGasNOxLifecycle]) [GrossGasNOxLifecycle]
      ,SUM([NetPM10]) [NetPM10]
      ,SUM([GrossPM10]) [GrossPM10]
      ,SUM([NetPM10Lifecycle]) [NetPM10Lifecycle]
      ,SUM([GrossPM10Lifecycle]) [GrossPM10Lifecycle]
  FROM [#OutputEmissions]
    GROUP BY JobID
        , PA
        , PrgID
        , CET_ID
    ORDER BY PA
        , PrgID
        , CET_ID

--PRINT 'Done!'






GO


