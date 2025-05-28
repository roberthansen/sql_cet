/*
##############################################################################
Name           : AvoidedCostGasvw
Date           : 2016-06-30
Author         : Wayne Hauck
Company        : Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose        : This view joins the input measures with the avoided costs used
               : by the cost effectiveness calculations.
Usage          : n/a
Called by      : n/a
Copyright      : Developed by Pinnacle Consulting Group (aka InTech Energy,
               : Inc.) for California Public Utilities Commission (CPUC). All
               : Rights Reserved.
Change History : 2016-06-30  Wayne Hauck added comment header
               : 2021-04-26  Robert Hansen modified join and added fields for
               : fuel substitution
               : 2024-04-23  Robert Hansen renamed the "PA" field to
               : "IOU_AC_Territory"
               : 2024-06-20  Robert Hansen reverted "IOU_AC_Territory" to "PA"
               : 2025-05-21  Robert Hansen added new fields for the Societal
               :             Cost Test: Ra_SCT, Rq_SCT, Rq_SCT, Rqf_SCT,
               :             Cost_SB and Cost_SH
##############################################################################
*/

IF OBJECT_ID('dbo.AvoidedCostGasvw','V') IS NOT NULL
    DROP VIEW dbo.AvoidedCostGasvw
GO

CREATE VIEW [dbo].[AvoidedCostGasvw]
AS
SELECT
    s.[Version]
    ,s.Ra
    ,s.Rq
    ,s.Rqf
    ,s.Ra_SCT
    ,s.Rq_SCT
    ,s.Rqf_SCT
    ,ac1.PA
    ,ac1.Qtr
    ,ac1.Qac
    ,ac1.Total As Cost
    --,ac2.Total As Cost_AL
    ,ac1.Total_SB AS Cost_SB
    ,ac1.Total_SH AS Cost_SH
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
    ,im.eul
    ,im.eulq
    ,im.eulq1
    ,im.eulq2
    ,im.rul
    ,im.NTGRkw
    ,im.NTGRkWh
    ,im.NTGRThm
    ,im.Qty
    ,ac1.ComboField
    --,ac2.ComboField AS ComboField_AL
FROM
dbo.InputMeasurevw AS im
LEFT JOIN dbo.Settingsvw AS s
ON im.PA=s.PA
LEFT JOIN AvoidedCostSourceGasvw AS ac1
ON im.PA=ac1.PA AND im.GS=ac1.GS AND im.GP=ac1.GP AND s.[Version] = ac1.[Version]
--LEFT JOIN AvoidedCostSourceGasvw AS ac2
--ON im.PA=ac2.PA AND im.GS=ac2.GS AND im.GP=ac2.GP AND s.[Version] = ac2.[Version] AND ac1.Qtr=ac2.Qtr
WHERE  ac1.Qac BETWEEN im.Qm AND im.Qm + CONVERT( INT, im.eulq )
GO
