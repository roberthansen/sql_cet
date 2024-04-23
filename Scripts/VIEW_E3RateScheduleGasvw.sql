/*
#################################################################################################
Name             :  E3RateScheduleGasvw
Date             :  06/30/2016
Author           :  Wayne Hauck
Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose          :  This view associates gas rates for each input measure row according to the specified rate schedule
Usage            :  n/a
Called by        :  n/a
Copyright        :  Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
Change History   :  06/30/2016  Wayne Hauck added comment header
                 :  2021-09-03  Robert Hansen modified table join operations to resolve errors
                 :              when input gas schedule is null
                 :  2024-04-23  Robert Hansen renamed the "PA" field to
                 :              "IOU_AC_Territory"
#################################################################################################
*/

IF OBJECT_ID('dbo.E3RateScheduleGasvw','V') IS NOT NULL
    DROP VIEW dbo.E3RateScheduleGasvw
GO

CREATE VIEW [dbo].[E3RateScheduleGasvw]
AS
    SELECT
        s.Version,
        s.Ra,
        s.Rq,
        s.Rqf,
        s.Raf,
        e.IOU_AC_Territory,
        e.TS,
        e.EU,
        e.CZ,
        r.Year,
        r.Qy,
        r.Schedule,
        r.RateG,
        e.CET_ID,
        e.PrgID,
        e.Qm,
        e.Qy AS Yr1,
        e.kW1,
        e.kWh1,
        e.Thm1,
        e.kW2,
        e.kWh2,
        e.Thm2,
        e.EUL,
        e.eul1,
        e.eul2,
        e.eulq,
        e.eulq1,
        e.eulq2,
        e.RUL,
        e.NTGRkW,
        e.NTGRkWh,
        e.NTGRThm,
        e.Qty
    FROM
        InputMeasurevw AS e
        LEFT JOIN Settingsvw AS s ON e.IOU_AC_Territory=s.IOU_AC_Territory
        LEFT JOIN E3RateScheduleGasMapping AS m ON  s.Version=m.Version AND s.IOU_AC_Territory=m.IOU_AC_Territory AND e.GS=m.GasSector
        LEFT JOIN E3RateScheduleSourceGasvw AS r ON s.Version=r.Version AND s.IOU_AC_Territory=r.IOU_AC_Territory AND m.GasRateSchedule=r.Schedule
    WHERE r.Schedule IS NOT NULL
GO
