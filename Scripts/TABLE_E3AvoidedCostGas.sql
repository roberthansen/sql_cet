/*
Name            : AvoidedCostElec (table)
Date            : c.2016
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
                : 2021-05-25  Robert Hansen removed MarketEffectBens and
                : MarketEffectCosts fields
                : 2021-06-16  Robert Hansen commented out new fields for fuel
                : substitution for implementation at a later date
                : 2022-08-30  Robert Hansen added the following new fields
                : related to water-energy nexus savings:
                :   + UWSGal
                :   + UWSGal_ER
                :   + UES_IOUWater
                :   + UES_IOUWater_ER
                :   + UES_TotalWater
                :   + UES_TotalWater_ER
                : 2023-02-07  Robert Hansen added a WaterUse field for tracking
                : water-energy nexus measures and removed extra water-energy
                : fields not used in CET calculations:
                :   + UnitGalWater1stBaseline aka UWSGal, Gal1
                :   + UnitGalWater2ndBaseline aka UWSGal_ER, Gal2
                :   + UnitkWhTotalWater1stBaseline aka UESkWh_TotalWater, kWhTotalWater1
                :   + UnitkWhTotalWater2ndBaseline aka UESkWh_TotalWater_ER, kWhTotalWater2
                : 2024-04-23  Robert Hansen renamed "PA" field to
                : "IOU_AC_Territory"
                : 2024-04-23  Robert Hansen reverted "IOU_AC_Territory" to
                : "PA"
                : 2025-04-11  Robert Hansen added new UnitTaxCredits field
*/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.InputMeasure') IS NOT NULL
    DROP TABLE dbo.InputMeasure
GO

CREATE TABLE "dbo"."InputMeasure"
(
    JobID int NOT NULL,
    CET_ID nvarchar(255) NOT NULL,
    PA nvarchar(24),
    PrgID nvarchar(100),
    ProgramName nvarchar(255),
    MeasureName nvarchar(255),
    MeasureID nvarchar(255),
    ElecTargetSector nvarchar(100),
    ElecEndUseShape nvarchar(100),
/* new end use shape field for additional electric load for fuel substitution
   measures: */
    --ElecAddEndUseShape nvarchar(100),
/* end new field */
    ClimateZone nvarchar(6),
    GasSector nvarchar(100),
    GasSavingsProfile nvarchar(100),
/* new end use shape field for additional natural gas load for fuel substitution
   measures: */
    --GasAddProfile nvarchar(100),
/* end new field */
    ElecRateSchedule nvarchar(100),
    GasRateSchedule nvarchar(100),
    CombustionType nvarchar(100),
    ClaimYearQuarter nvarchar(50),
    Qty float(53),
    UESkW float(53),
    UESkWh float(53),
    UESThm float(53),
    UESkW_ER float(53),
    UESkWh_ER float(53),
    UESThm_ER float(53),
/* new 'Unit Additional Load' (UAL) fields for fuel substitution measures: */
    --UALkW float(53),
    --UALkWh float(53),
    --UALThm float(53),
    --UALkW_ER float(53),
    --UALkWh_ER float(53),
    --UALThm_ER float(53),
/* end new fields */
/* new water-energy nexus fields: */
    UESkWh_IOUWater float(53),
    UESkWh_IOUWater_ER float(53),
    WaterUse nvarchar(255),
/* end new water-energy nexus fields */
    EUL float(53),
    RUL float(53),
    NTGRkW float(53),
    NTGRkWh float(53),
    NTGRThm float(53),
    NTGRCost float(53),
    IR float(53),
    IRkW float(53),
    IRkWh float(53),
    IRThm float(53),
    RRkW float(53),
    RRkWh float(53),
    RRThm float(53),
    UnitMeasureGrossCost float(53),
    UnitMeasureGrossCost_ER float(53),
    EndUserRebate float(53),
    IncentiveToOthers float(53),
    DILaborCost float(53),
    DIMaterialCost float(53),
/* new costs and benefits fields: */
    UnitGasInfraBens float(53),
    UnitRefrigCosts float(53),
    UnitRefrigBens float(53),
    UnitMiscCosts float(53),
    MiscCostsDesc nvarchar(255),
    UnitMiscBens float(53),
    MiscBensDesc nvarchar(255),
    UnitTaxCredits float(53),
/* end new costs and benefits fields */
    Sector nvarchar(255),
    EndUse nvarchar(255),
    BuildingType nvarchar(255),
    MeasureGroup nvarchar(255),
    SolutionCode nvarchar(255),
    Technology nvarchar(255),
    Channel nvarchar(255),
    IsCustom nvarchar(255),
    Location nvarchar(255),
    ProgramType nvarchar(255),
    UnitType nvarchar(255),
    Comments nvarchar(255),
    DataField nvarchar(255)
)
GO
CREATE INDEX PA_IDX ON dbo.InputMeasure(PA)
GO
CREATE INDEX IDX_PrgID ON dbo.InputMeasure(PrgID)
GO
CREATE INDEX IDX_CET_ID ON dbo.InputMeasure(CET_ID)
GO