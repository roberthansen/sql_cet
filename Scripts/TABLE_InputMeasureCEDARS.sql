/*
Name            : ImpactMeasureCEDARS (table)
Date            : c.2016-06-30
Author          : Wayne Huack
Company         : Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose         : Creates one of tables that stores measures for use in the CET
Usage           : Automated interfaces populate this table and trigger the
                : RunCET procedure
Copyright       : Developed by Pinnacle Consulting Group (aka Intech Energy,
                : Inc.) for the California Public Utilities Commission (CPUC)
                : All Rights Reserved
Change History  : 2021-04-18  Robert Hansen added columns for additional load
                : for use with fuel substitution measures
                : 2021-05-13  Robert Hansen renamed additional load columns per
                : email from DNV GL
                : 2021-05-17  Robert Hansen added the following new cost and 
                : benefit fields:
                :   + UnitGasInfraBens - per-unit benefits due to offsetting
                :     gas infrastructure costs
                :   + UnitRefrigCosts - per-unit costs due to increased or
                :     higher GWP refrigerant use
                :   + UnitRefrigBens - per-unit benefits due to less or lower
                :     GWP refrigerant use
                :   + UnitMiscCosts - per-unit miscellaneous costs (for future
                :     use)
                :   + MiscCostsDesc - description of miscellaneous costs (for
                :     future use)
                :   + UnitMiscBens - per-unit miscellaneous benefits (for
                :     future use)
                :   + MiscBensDesc - description of miscellaneous benefits (for
                :     future use)
                : 2021-05-25  Robert Hansen removed MarketEffectsBenefits and
                : MarketEffectsCosts fields
                : 2021-06-16  Robert Hansen commented out new fields for fuel
                : substitution for implementation at a later date
                : 2022-09-02  Robert Hansen added the following new fields related to
                : water-energy nexus savings:
                :   + UnitGalWater1stBaseline
                :   + UnitGalWater2ndBaseline
                :   + UnitkWhIOUWater1stBaseline
                :   + UnitkWhIOUWater2ndBaseline
                :   + UnitkWhTotalWater1stBaseline
                :   + UnitkWhTotalWater2ndBaseline
                : 2023-02-07  Robert Hansen added a WaterUse field for tracking
                : water-energy nexus measures and removed extra water-energy
                : fields not used in CET calculations:
                :    + UnitGalWater1stBaseline aka UWSGal, Gal1
                :    + UnitGalWater2ndBaseline aka UWSGal_ER, Gal2
                :    + UnitkWhTotalWater1stBaseline aka UESkWh_TotalWater, kWhTotalWater1
                :    + UnitkWhTotalWater2ndBaseline aka UESkWh_TotalWater_ER, kWhTotalWater2
                : 2024-04-23  Robert Hansen renamed the "PA" field to
                : "IOU_AC_Territory"
                : 2024-04-23  Robert Hansen reverted "IOU_AC_Territory" to
                : "PA"
*/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.InputMeasureCEDARS') IS NOT NULL
    DROP TABLE dbo.InputMeasureCEDARS
GO

CREATE TABLE "dbo"."InputMeasureCEDARS"
(
    CEInputID nvarchar(255) PRIMARY KEY NOT NULL,
    JobID int,
    PA nvarchar(50),
    PrgID nvarchar(255),
    ClaimYearQuarter nvarchar(6),
    MeasDescription nvarchar(255),
    MeasImpactType nvarchar(50),
    MeasCode nvarchar(255),
    MeasureID nvarchar(255),
    E3TargetSector nvarchar(255),
    E3MeaElecEndUseShape nvarchar(255),
/* new end use shape field for additional electric load for fuel substitution
   measures: */
    --E3MeaElecAddEndUseShape nvarchar(100),
/* end new end use shape field for additional electric load */
    E3ClimateZone nvarchar(255),
    E3GasSavProfile nvarchar(255),
/* new end use shape field for additional natural gas load for fuel substitution
   measures: */
    --E3GasAddProfile nvarchar(100),
/* end new end use shape field for additional natural gas load */
    E3GasSector nvarchar(255),
    NumUnits float(53),
    EUL_ID nvarchar(100),
    EUL_Yrs float(53),
    RUL_ID nvarchar(100),
    RUL_Yrs float(53),
    NTG_ID nvarchar(50),
    NTGRkW float(53),
    NTGRkWh float(53),
    NTGRTherm float(53),
    NTGRCost float(53),
    InstallationRatekW float(53),
    InstallationRatekWh float(53),
    InstallationRateTherm float(53),
    MeasInflation float(53),
    RealizationRatekW float(53),
    RealizationRatekWh float(53),
    RealizationRateTherm float(53),
    UnitkW1stBaseline float(53),
    UnitkW2ndBaseline float(53),
    UnitkWh1stBaseline float(53),
    UnitkWh2ndBaseline float(53),
    UnitTherm1stBaseline float(53),
    UnitTherm2ndBaseline float(53),
/* new 'Unit Additional Load' (UAL) fields for fuel substitution measures: */
    --UnitAddkW1stBaseline float(53),
    --UnitAddkWh1stBaseline float(53),
    --UnitAddTherm1stBaseline float(53),
    --UnitAddkW2ndBaseline float(53),
    --UnitAddkWh2ndBaseline float(53),
    --UnitAddTherm2ndBaseline float(53),
/* end new 'Unit Additional Load' (UAL) fields */
/* new water-energy nexus fields: */
    UnitkWhIOUWater1stBaseline float(53),
    UnitkWhIOUWater2ndBaseline float(53),
    WaterUse nvarchar(255),
/* end new water-energy nexus fields */
    UnitMeaCost1stBaseline float(53),
    UnitMeaCost2ndBaseline float(53),
    UnitDirectInstallLab float(53),
    UnitDirectInstallMat float(53),
    UnitEndUserRebate float(53),
    UnitIncentiveToOthers float(53),
/* new costs and benefits fields: */
    UnitGasInfraBens float(53),
    UnitRefrigCosts float(53),
    UnitRefrigBens float(53),
    UnitMiscCosts float(53),
    MiscCostsDesc nvarchar(255),
    UnitMiscBens float(53),
    MiscBensDesc nvarchar(255),
/* end new costs and benefits fields */
    Sector nvarchar(50),
    UseCategory nvarchar(50),
    UseSubCategory nvarchar(50),
    Residential_Flag tinyint,
    Upstream_Flag tinyint,
    GSIA_ID nvarchar(50),
    BldgType nvarchar(255),
    DeliveryType nvarchar(50),
    MeasAppType nvarchar(255),
    NormUnit nvarchar(255),
    PreDesc nvarchar(255),
    RateScheduleGas nvarchar(255),
    CombustionType nvarchar(255),
    SourceDesc nvarchar(255),
    StdDesc nvarchar(255),
    RateScheduleElec nvarchar(255),
    TechGroup nvarchar(50),
    TechType nvarchar(50),
    Version nvarchar(50),
    Comments nvarchar(255),
)
GO
CREATE INDEX IDX_CEInputID ON dbo.InputMeasureCEDARS(CEInputID)
GO
CREATE INDEX IDX_PrgID ON dbo.InputMeasureCEDARS(PrgID)
GO
CREATE INDEX IDX_PA ON dbo.InputMeasureCEDARS(PA)
GO