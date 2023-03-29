/*
Name            : SavedInputCEDARS (table)
Date            : c.2016-30-2016
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
                : 2022-09-02  Robert Hansen added the following new fields
				        : related to water-energy nexus savings:
                :   + UnitGalWater1stBaseline
                :   + UnitGalWater2ndBaseline
                :   + UnitkWhIOUWater1stBaseline
                :   + UnitkWhIOUWater2ndBaseline
                :   + UnitkWhTotalWater1stBaseline
                :   + UnitkWhTotalWater2ndBaseline
                :  2023-02-07  Robert Hansen added a WaterUse field for tracking
                :  water-energy nexus measures and removed extra water-energy
                :  fields not used in CET calculations:
                :    + UnitGalWater1stBaseline aka UWSGal, Gal1
                :    + UnitGalWater2ndBaseline aka UWSGal_ER, Gal2
                :    + UnitkWhTotalWater1stBaseline aka UESkWh_TotalWater, kWhTotalWater1
                :    + UnitkWhTotalWater2ndBaseline aka UESkWh_TotalWater_ER, kWhTotalWater2
*/

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.SavedInputCEDARS') IS NOT NULL
    DROP TABLE dbo.SavedInputCEDARS
GO


CREATE TABLE dbo.SavedInputCEDARS(
    ID INT IDENTITY(1,1) NOT NULL,
    JobID INT NOT NULL,
    CEInputID NVARCHAR(255) NOT NULL,
    PA NVARCHAR(50) NULL,
    PrgID NVARCHAR(255) NULL,
    ClaimYearQuarter NVARCHAR(6) NULL,
    MeasDescription NVARCHAR(255) NULL,
    MeasImpactType NVARCHAR(50) NULL,
    MeasCode NVARCHAR(255) NULL,
    MeasureID NVARCHAR(255) NULL,
    E3TargetSector NVARCHAR(255) NULL,
    E3MeaElecEndUseShape NVARCHAR(255) NULL,
    --E3MeaElecAddEndUseShape NVARCHAR(255) NULL,
    E3ClimateZone NVARCHAR(255) NULL,
    E3GasSavProfile NVARCHAR(255) NULL,
    E3GasSector NVARCHAR(255) NULL,
    --E3GasAddProfile NVARCHAR(255) NULL,
    NumUnits FLOAT NULL,
    EUL_ID NVARCHAR(100) NULL,
    EUL_Yrs FLOAT NULL,
    RUL_ID NVARCHAR(100) NULL,
    RUL_Yrs FLOAT NULL,
    NTG_ID NVARCHAR(50) NULL,
    NTGRkW FLOAT NULL,
    NTGRkWh FLOAT NULL,
    NTGRTherm FLOAT NULL,
    NTGRCost FLOAT NULL,
    InstallationRatekW FLOAT NULL,
    InstallationRatekWh FLOAT NULL,
    InstallationRateTherm FLOAT NULL,
    MeasInflation FLOAT NULL,
    RealizationRatekW FLOAT NULL,
    RealizationRatekWh FLOAT NULL,
    RealizationRateTherm FLOAT NULL,
    UnitkW1stBaseline FLOAT NULL,
    UnitkW2ndBaseline FLOAT NULL,
    UnitkWh1stBaseline FLOAT NULL,
    UnitkWh2ndBaseline FLOAT NULL,
    UnitTherm1stBaseline FLOAT NULL,
    UnitTherm2ndBaseline FLOAT NULL,
    --UnitAddkW1stBaseline FLOAT NULL,
    --UnitAddkW2ndBaseline FLOAT NULL,
    --UnitAddkWh1stBaseline FLOAT NULL,
    --UnitAddkWh2ndBaseline FLOAT NULL,
    --UnitAddTherm1stBaseline FLOAT NULL,
    --UnitAddTherm2ndBaseline FLOAT NULL,
/* new water-energy nexus fields: */
    UnitkWhIOUWater1stBaseline FLOAT NULL,
    UnitkWhIOUWater2ndBaseline FLOAT NULL,
    WaterUse NVARCHAR(255) NULL,
/* end new water-energy nexus fields */
    UnitMeaCost1stBaseline FLOAT NULL,
    UnitMeaCost2ndBaseline FLOAT NULL,
    UnitDirectInstallLab FLOAT NULL,
    UnitDirectInstallMat FLOAT NULL,
    UnitEndUserRebate FLOAT NULL,
    UnitIncentiveToOthers FLOAT NULL,
    UnitGasInfraBens FLOAT,
    UnitRefrigCosts FLOAT,
    UnitRefrigBens FLOAT,
    UnitMiscCosts FLOAT,
    MiscCostsDesc NVARCHAR(255),
    UnitMiscBens FLOAT,
    MiscBensDesc NVARCHAR(255),
    Sector NVARCHAR(50) NULL,
    UseCategory NVARCHAR(50) NULL,
    UseSubCategory NVARCHAR(50) NULL,
    Residential_Flag bit NULL,
    Upstream_Flag bit NULL,
    GSIA_ID NVARCHAR(50) NULL,
    BldgType NVARCHAR(255) NULL,
    DeliveryType NVARCHAR(50) NULL,
    MeasAppType NVARCHAR(255) NULL,
    NormUnit NVARCHAR(255) NULL,
    PreDesc NVARCHAR(255) NULL,
    RateScheduleGas NVARCHAR(255) NULL,
    CombustionType NVARCHAR(255) NULL,
    SourceDesc NVARCHAR(255) NULL,
    StdDesc NVARCHAR(255) NULL,
    RateScheduleElec NVARCHAR(255) NULL,
    TechGroup NVARCHAR(50) NULL,
    TechType NVARCHAR(50) NULL,
    [Version] NVARCHAR(50) NULL,
    Comments NVARCHAR(255) NULL
) ON [PRIMARY]
GO

CREATE CLUSTERED INDEX IX_JobID_CETID ON dbo.SavedInputCEDARS(JobID,CEInputID) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX IX_CEInputID ON dbo.SavedInputCEDARS(CEInputID) WITH (STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX IX_JobID ON dbo.SavedInputCEDARS(JobID) WITH (STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX IX_PA ON dbo.SavedInputCEDARS(PA) WITH (STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX IX_PrgID ON dbo.SavedInputCEDARS(PrgID) WITH (STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO