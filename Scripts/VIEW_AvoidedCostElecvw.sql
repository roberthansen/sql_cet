/*
###############################################################################
Name           : AvoidedCostElecvw
Date           : 2016-06-30
Author         : Wayne Hauck
Company        : Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose        : This view joins the input measures with the avoided costs used
               : by the cost effectiveness calculations.
Usage          : n/a
Called by      : n/a
Copyright      : Developed by Pinnacle Consulting Group (aka InTech Energy,
               : Inc.) access for California Public Utilities Commission
               : (CPUC). All Rights Reserved.
Change History : 2016-06-30 Wayne Hauck added comment header
               : 2021-04-26 Robert Hansen modified join and added fields for
               : fuel substitution
               : 2021-06-16 Robert Hansen commented out new fields for fuel
               : substitution for implementation at a later date
               : 2022-09-02 Robert Hansen modified join and added fields for
               : water energy nexus:
               :   + Gal1
               :   + Gal2
               :   + kWhWater1
               :   + kWhWater2
               :   + kWhTotalWater1
               :   + kWhTotalWater2
               : 2023-02-07  Robert Hansen removed extra water-energy fields not
               : used in CET calculations:
               :   + UnitGalWater1stBaseline aka UWSGal, Gal1
               :   + UnitGalWater2ndBaseline aka UWSGal_ER, Gal2
               :   + UnitkWhTotalWater1stBaseline aka UESkWh_TotalWater, kWhTotalWater1
               :   + UnitkWhTotalWater2ndBaseline aka UESkWh_TotalWater_ER, kWhTotalWater2
               : 2023-03-07  Robert Hansen removed extraneous join for avoided
               : water energy generation costs
               : 2024-04-23  Robert Hansen renamed the "PA" field to
               : "IOU_AC_Territory"
###############################################################################
*/

IF OBJECT_ID('dbo.AvoidedCostElecvw','V') IS NOT NULL
    DROP VIEW dbo.AvoidedCostElecvw
GO

CREATE VIEW [dbo].[AvoidedCostElecvw] AS
SELECT
    s.[Version]
    ,s.Ra
    ,s.Rq
    ,s.Rqf
    ,im.PA
    ,im.TS
    ,im.EU
    --,im.EUAL
    ,im.CZ
    ,ac1.Qtr
    ,ac1.Qac
    ,ac1.Gen
    ,ac1.TD
    --,ac2.Gen AS Gen_AL
    --,ac2.TD AS TD_AL
    ,im.CET_ID
    ,im.PrgID
    ,im.GP
    --,im.GPAL
    ,im.GS
    ,im.Qm
    ,im.kW1
    ,im.kWh1
    ,im.Thm1
    ,im.kW2
    ,im.kWh2
    ,im.Thm2
    --,im.kW1_AL
    --,im.kWh1_AL
    --,im.Thm1_AL
    --,im.kW2_AL
    --,im.kWh2_AL
    --,im.Thm2_AL
    ,im.kWhWater1
    ,im.kWhWater2
    ,im.eul
    ,im.eulq
    ,im.eulq1
    ,im.eulq2
    ,im.rul
    ,im.NTGRkw
    ,im.NTGRkWh
    ,im.NTGRThm
    ,im.Qty
    ,CASE
        WHEN ac1.DSType = 'kW'
        THEN im.kW1
        ELSE im.kWh1
    END AS DS1
    ,CASE
        WHEN ac1.DSType = 'kW'
        THEN im.kW2
        ELSE im.kWh2
    END AS DS2
    --,CASE
    --    WHEN ac2.DSType = 'kW'
    --    THEN im.kW1_AL
    --    ELSE im.kWh1_AL
    --END AS DS1_AL
    --,CASE
    --    WHEN ac2.DSType = 'kW'
    --    THEN im.kW2_AL
    --    ELSE im.kWh2_AL
    --END AS DS2_AL
FROM dbo.InputMeasurevw AS im
LEFT JOIN dbo.Settingsvw AS s
ON im.IOU_AC_Territory = s.PA
LEFT JOIN
    AvoidedCostSourceElecvw AS ac1
ON im.IOU_AC_Territory=ac1.IOU_AC_Territory AND im.TS=ac1.TS AND im.EU=ac1.EU AND RTRIM(im.CZ)=ac1.CZ AND s.[Version]=ac1.[Version]
--LEFT JOIN
--    AvoidedCostSourceElecvw AS ac2
--ON im.IOU_AC_Territory=ac2.IOU_AC_Territory AND im.TS=ac2.TS AND im.EUAL=ac2.EU AND RTRIM(im.CZ)=ac2.CZ AND s.[Version]=ac2.[Version] AND ac1.Qtr=ac2.Qtr
WHERE  ac1.Qac BETWEEN im.Qm AND im.Qm + CONVERT( INT, im.eulq )
GO
