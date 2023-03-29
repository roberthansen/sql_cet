/*
##############################################################################
Name           : AvoidedCostGasvw
Date           : 06/30/2016
Author         : Wayne Hauck
Company        : Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose        : This view joins the input measures with the avoided costs used by the cost effectiveness calculations.
Usage          : n/a
Called by      : n/a
Copyright ©    : Developed by Pinnacle Consulting Group (aka InTech Energy, Inc.) for California Public Utilities Commission (CPUC). All Rights Reserved.
Change History : 06/30/2016  Wayne Hauck added comment header
                 04/26/2021  Robert Hansen modified join and added fields for
                 fuel substitution


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
    ,ac1.PA
    ,ac1.Qtr
    ,ac1.Qac
    ,ac1.Total As Cost
    --,ac2.Total As Cost_AL
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
