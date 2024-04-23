/*
################################################################################
Name             :  InitializeTables (procedure)
Date             :  2016-06-30
Author           :  Wayne Hauck
Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose          :  This stored procedure initializes tables which prepares
                 :  views for running cost effectiveness.
Usage            :  n/a
Called by        :  n/a
Copyright �      :  Developed by Pinnacle Consulting Group (aka InTech Energy,
                 :  Inc.) for California Public Utilities Commission (CPUC).
                 :  All Rights Reserved.
Change History   :  2016-06-30  Wayne Hauck added comment header
                 :  2016-12-30  Wayne Hauck added Measure Inflation flex field
                 :  2021-04-18  Robert Hansen added new columns for additional
                 :              load for fuel substitution measures
                 :  2021-05-13  Robert Hansen updated additional load field
                 :              names according to email from DNV GL
                 :  2021-05-25  Robert Hansen removed MEBens and MECost fields
                 :  2021-06-16  Robert Hansen commented out new fields for fuel
                 :              substitution for implementation at a later date
                 :  2022-09-02  Robert Hansen added the following new fields related to
                 :              water-energy nexus savings:
                 :                + UnitGalWater1stBaseline aka UWSGal, Gal1
                 :                + UnitGalWater2ndBaseline aka UWSGal_ER, Gal2
                 :                + UnitkWhIOUWater1stBaseline aka
                 :                  UESkWh_IOUWater, kWhWater1
                 :                + UnitkWhIOUWater2ndBaseline aka
                 :                  UESkWh_IOUWater_ER, kWhWater2
                 :                + UnitkWhTotalWater1stBaseline aka
                 :                  UESkWh_TotalWater, kWhTotalWater1
                 :                + UnitkWhTotalWater2ndBaseline aka
                 :                  UESkWh_TotalWater_ER, kWhTotalWater2
                 :  2023-02-07  Robert Hansen added a WaterUse field for
                 :              tracking water-energy nexus measures and removed
                 :              extra water-energy fields not used in CET
                 :              calculations:
                 :                + UnitGalWater1stBaseline aka UWSGal, Gal1
                 :                + UnitGalWater2ndBaseline aka UWSGal_ER, Gal2
                 :                + UnitkWhTotalWater1stBaseline aka
                 :                  UESkWh_TotalWater, kWhTotalWater1
                 :                + UnitkWhTotalWater2ndBaseline aka
                 :                  UESkWh_TotalWater_ER, kWhTotalWater2
                 :  2024-04-23  Robert Hansen renamed "PA" field to
                 :              "IOU_AC_Territory"
################################################################################
*/

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('dbo.InitializeTables'))
   exec('CREATE PROCEDURE [dbo].[InitializeTables] AS BEGIN SET NOCOUNT ON; END')
GO

ALTER PROCEDURE [dbo].[InitializeTables]
@JobID INT = -1,
@SourceType NVARCHAR(25),
@SourceDatabase NVARCHAR(255),
@MeasureTable NVARCHAR(255),
@ProgramTable NVARCHAR(255),
--@Filter nvarchar(255) = '',
@FirstYear INT=2013,
@AVCVersion NVARCHAR(255),
@IncludeNonresourceCosts BIT = 0

AS

SET NOCOUNT ON

DECLARE @SourceMeasurevwSql NVARCHAR(MAX);
DECLARE @SourceProgramvwSql NVARCHAR(MAX);
DECLARE @MappingMeasurevwSql NVARCHAR(MAX);
DECLARE @MappingProgramvw NVARCHAR(MAX);
DECLARE @AvoidedCostElecvwSql NVARCHAR(MAX);
DECLARE @AvoidedCostGasvwSql NVARCHAR(MAX);
DECLARE @InputKeysvwSQL NVARCHAR(MAX);
DECLARE @InputFiltervwSql NVARCHAR(MAX);
DECLARE @InputMeasurevwSql NVARCHAR(MAX);
DECLARE @ISCombustType INT;
DECLARE @CombType NVARCHAR(255);
DECLARE @ISMeasInflation INT;
DECLARE @MeasInflation NVARCHAR(255);

---------Check for Combustion Type in Source data  --------
SET @ISCombustType = (SELECT COUNT(*) FROM sys.columns WHERE Name = N'CombustionType' AND Object_ID = Object_ID(N'SourceMeasurevw'))
IF @ISCombustType = 0
    BEGIN 
        SET @CombType = '''Residential Furnaces (<0.3):Uncontrolled'''
        PRINT 'CombustionType field is not present in source table.'
    END 
ELSE
    BEGIN 
        SET @CombType = 'CombustionType'
        PRINT 'CombustionType is present in source table.'
    END

---------Check for Measure Inflation in Source data  --------
SET @ISMeasInflation = (SELECT COUNT(*) FROM sys.columns WHERE Name = N'MeasInflation' AND Object_ID = Object_ID(N'SourceMeasurevw'))
IF @ISMeasInflation = 0
    BEGIN 
        SET @MeasInflation = '0'
        PRINT 'Measure Inflation (MeasInflation) field is not present in source table.'
    END 
ELSE
    BEGIN 
        SET @MeasInflation = 'ISNULL(MeasInflation,0)'
        PRINT 'Measure Inflation (MeasInflation) field is in source table.'
    END

---------Start Mapping Source Data  --------


IF @SourceType = 'Excel' 
BEGIN

    SET @MappingMeasurevwSql = 'ALTER VIEW [dbo].[MappingMeasurevw] AS
/*
################################################################################
Name : MappingMeasurevw
Date : 2016-06-30
Author : Wayne Hauck
Company : Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose : This view maps the source input to CET-compatible field names. This allows multiple input formats to be mapped to one format. It is code-generated in the InitializeTables saved procedure.
Usage : n/a
Called by : n/a
Copyright � : Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
Change History : 2016-06-30  Wayne Hauck added comment header
 : 2021-04-18 Robert Hansen added new columns for additional load for fuel substitution measures
 : 2021-05-17 Robert Hansen added new benefits and costs columns
 : 2021-05-25 Robert Hansen removed MEBens and MECost fields
 : 2022-08-30 Robert Hansen added new fields for water energy calculations
 : 2024-04-23 Robert Hansen renamed "PA" field to "IOU_AC_Territory"
################################################################################
*/

SELECT
' + CONVERT(VARCHAR,@JobID) + 'AS JobID,CET_ID,IOU_AC_Territory,PrgID,ProgramName,MeasureName,
MeasureID,MeasImpactType,
CASE WHEN ElecEndUseShape LIKE ''Non_res:DEER%'' THEN ''Non_res'' ELSE CASE WHEN ElecEndUseShape LIKE ''res:DEER%'' THEN ''Res'' ELSE ElecTargetSector END END AS ElecTargetSector,
CASE WHEN ElecEndUseShape LIKE ''Non_res:DEER%'' THEN Replace(ElecEndUseShape,''Non_res:'','''') ELSE CASE WHEN ElecEndUseShape LIKE ''res:DEER%'' THEN Replace(ElecEndUseShape,''res:'','''') ELSE ElecEndUseShape END END AS ElecEndUseShape,
/*CASE WHEN ElecEndUseShapeAL LIKE ''Non_res:DEER%'' THEN Replace(ElecEndUseShapeAL,''Non_res:'','''') ELSE CASE WHEN ElecEndUseShapeAL LIKE ''res:DEER%'' THEN Replace(ElecEndUseShapeAL,''res:'','''') ELSE  ElecEndUseShapeAL END END AS ElecEndUseShapeAL,*/
ClimateZone,GasSector,GasSavingsProfile,/*GasSavingsProfileAL,*/
'''' AS ElecRateSchedule,'''' AS GasRateSchedule,' + @CombType + ' AS CombType,
ClaimYearQuarter,Qty,UESkW,UESkWh,UESThm,UESkW_ER,UESkWh_ER,UESThm_ER,/*UALkW,
UALkWh,UALThm,UALkW_ER,UALkWh_ER,UALThm_ER,*/UESkWh_IOUWater,UESkWh_IOUWater_ER,
WaterUse,NTGRkW,NTGRkWh,NTGRThm,NTGRCostEUL,RUL,IRkWh IR,IRkW,IRkWh,IRThm,RRkWh,
RRkW,RRThm,IncentiveToOthers,EndUserRebate,DILaborCost,DIMaterialCost,
UnitMeasureGrossCost,UnitMeasureGrossCost_ER,' + @MeasInflation +
' AS MeasInflation,UnitGasInfraBens, UnitRefrigCosts,UnitRefrigBens,
UnitMiscCosts,MiscCostsDesc,UnitMiscBens,MiscBensDesc,Sector,EndUse,
BuildingType,MeasureGroup,SolutionCode,Technology,Channel,IsCustom,Location,
ProgramType,UnitType,Comments,DataField
FROM [SourceMeasurevw]
'

SET @MappingProgramvw = 'ALTER VIEW [dbo].[MappingProgramvw] AS
/*
################################################################################
Name : MappingProgramvw
Date : 2016-06-30
Author : Wayne Hauck
Company : Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose : This view maps the source input to CET-compatible field names. This allows multiple input formats to be mapped to one format. It is code-generated in the InitializeTables saved procedure.
Usage : n/a
Called by : n/a
Copyright � : Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
Change History : 2016-06-30  Wayne Hauck added comment header
 : 2024-04-23 Robert Hansen renamed "PA" field to "IOU_AC_Territory"
################################################################################
*/
SELECT
    ' + CONVERT(VARCHAR,@JobID) + ' AS JobID, 
    IOU_AC_Territory,
    PrgID,
    ProgramName,
    ClaimYearQuarter,
    AdminCostsOverheadAndGA,
    AdminCostsOther,
    MarketingOutreach,
    DIActivity,
    DIInstallation,
    DIHardwareAndMaterials,
    DIRebateAndInspection,
    EMV,
    UserInputIncentive,
    CostsRecoveredFromOtherSources,
    OnBillFinancing
FROM SourceProgramvw' 
END


IF @SourceType = 'CETDatabase' OR @SourceType = 'CETInput'
BEGIN

SET @MappingMeasurevwSql = 'ALTER VIEW [dbo].[MappingMeasurevw] AS
/*
################################################################################
Name : MappingMeasurevw
Date : 2016-06-30
Author : Wayne Hauck
Company : Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose : This view maps the source input to CET-compatible field names. This allows multiple input formats to be mapped to one format. It is code-generated in the InitializeTables saved procedure.
Usage : n/a
Called by : n/a
Copyright � : Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
Change History : 2016-06-30  Wayne Hauck added comment header
 : 2021-04-18 Robert Hansen added new columns for additional load for fuel substitution measures
 : 2021-05-17 Robert Hansen added new benefits and costs columns
 : 2021-05-25 Robert Hansen removed MEBens and MECost fields
 : 2022-08-30 Robert Hansen added new fields for water energy calculations
 : 2024-04-23 Robert Hansen renamed "PA" field to "IOU_AC_Territory"
################################################################################
*/

SELECT
' + CONVERT(VARCHAR,@JobID) + ' AS JobID,
CEInputID CET_ID,IOU_AC_Territory,PrgID,'''' AS ProgramName,MeasDescription MeasureName,
MeasureID,MeasImpactType,
CASE WHEN E3MeaElecEndUseShape LIKE ''Non_res:DEER%'' THEN ''Non_res'' ELSE CASE WHEN E3MeaElecEndUseShape LIKE ''res:DEER%'' THEN ''Res'' ELSE E3TargetSector END END AS ElecTargetSector,
CASE WHEN E3MeaElecEndUseShape LIKE ''Non_res:DEER%'' THEN Replace(E3MeaElecEndUseShape,''Non_res:'','''') ELSE CASE WHEN E3MeaElecEndUseShape LIKE ''res:DEER%'' THEN Replace(E3MeaElecEndUseShape,''res:'','''') ELSE E3MeaElecEndUseShape END END AS ElecEndUseShape,
/*CASE WHEN E3MeaElecAddEndUseShape LIKE ''Non_res:DEER%'' THEN Replace(E3MeaElecAddEndUseShape,''Non_res:'','''') ELSE CASE WHEN E3MeaElecAddEndUseShape LIKE ''res:DEER%'' THEN Replace(E3MeaElecAddEndUseShape,''res:'','''') ELSE E3MeaElecAddEndUseShape END END AS ElecAddEndUseShape,*/
E3ClimateZone ClimateZone,E3GasSector GasSector,
E3GasSavProfile GasSavingsProfile,/*E3GasAddProfile GasAdditionalLoadProfile,*/
'''' AS ElecRateSchedule,'''' AS GasRateSchedule,' + @CombType + ' AS CombType,
ClaimYearQuarter,NumUnits Qty,UnitkW1stBaseline UESkW,
UnitkWh1stBaseline UESkWh,UnitTherm1stBaseline UESThm,
UnitkW2ndBaseline UESkW_ER,UnitkWh2ndBaseline UESkWh_ER,
UnitTherm2ndBaseline UESThm_ER,/*UnitAddkW1stBaseline UALkW,
UnitAddkWh1stBaseline UALkWh,UnitAddTherm1stBaseline UALThm,
UnitAddkW2ndBaseline UALkW_ER,UnitAddkWh2ndBaseline UALkWh_ER,
UnitAddTherm2ndBaseline UALThm_ER,*/
UnitkWhIOUWater1stBaseline UESkWh_IOUWater,
UnitkWhIOUWater2ndBaseline UESkWh_IOUWater_ER,WaterUse,
EUL_Yrs EUL,RUL_Yrs RUL,NTGRkW,NTGRkWh,
NTGRTherm NTGRThm,NTGRCost,InstallationRatekWh IR,
InstallationRatekW IRkW,InstallationRatekWh IRkWh,
InstallationRateTherm IRThm,RealizationRatekWh RRkWh,
RealizationRatekW RRkW,RealizationRateTherm RRThm,
UnitIncentiveToOthers IncentiveToOthers,UnitEndUserRebate EndUserRebate,
UnitDirectInstallLab DILaborCost,UnitDirectInstallMat DIMaterialCost,
UnitMeaCost1stBaseline UnitMeasureGrossCost,
UnitMeaCost2ndBaseline UnitMeasureGrossCost_ER,
' + @MeasInflation + ' AS MeasInflation,UnitGasInfraBens,UnitRefrigCosts,
UnitRefrigBens,UnitMiscCosts,MiscCostsDesc,UnitMiscBens,MiscBensDesc,
Sector,
'''' AS EndUse,BldgType BuildingType,'''' AS MeasureGroup,
'''' AS SolutionCode,TechType Technology,DeliveryType Channel,
'''' AS IsCustom,'''' AS Location,'''' AS ProgramType,NormUnit UnitType,
Comments,'''' AS DataField
FROM [SourceMeasurevw]
'
END

IF @SourceType = 'CETDatabase'
BEGIN
    SET @MappingProgramvw = 'ALTER VIEW [dbo].[MappingProgramvw] AS
/*
################################################################################
Name : MappingProgramvw
Date : 2016-06-30
Author : Wayne Hauck
Company : Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose : This view maps the source input to CET-compatible field names. This allows multiple input formats to be mapped to one format. It is code-generated in the InitializeTables saved procedure.
Usage : n/a
Called by : n/a
Copyright � : Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
Change History : 2016-06-30  Wayne Hauck added comment header
 : 2021-04-18 Robert Hansen added new columns for additional load for fuel substitution measures
 : 2021-05-17 Robert Hansen added new benefits and costs columns
 : 2024-04-23 Robert Hansen renamed "PA" field to "IOU_AC_Territory"
################################################################################
*/
SELECT
    ' + CONVERT(VARCHAR,@JobID) + ' AS JobID, 
    IOU_AC_Territory,
    PrgID,
    '''' AS ProgramName,
    ClaimYearQuarter,
    AdminCostsOverheadAndGA,
    AdminCostsOther,
    MarketingOutreach,
    DIActivity,
    DIInstallation,
    DIHardwareAndMaterials,
    DIRebateAndInspection,
    EMV,
    UserInputIncentive,
    CostsRecoveredFromOtherSources,
    OnBillFinancing
FROM [dbo].SourceProgramvw'
END

IF @SourceType = 'CETInput'
BEGIN
    SET @MappingProgramvw = 'ALTER VIEW [dbo].[MappingProgramvw] AS
/*
################################################################################
Name : MappingProgramvw
Date : 2016-06-30
Author : Wayne Hauck
Company : Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose : This view maps the source input to CET-compatible field names. This allows multiple input formats to be mapped to one format. It is code-generated in the InitializeTables saved procedure.
Usage : n/a
Called by : n/a
Copyright � : Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
Change History : 2016-06-30  Wayne Hauck added comment header
 : 2021-04-18 Robert Hansen added new columns for additional load for fuel substitution measures
 : 2021-05-17 Robert Hansen added new benefits and costs columns
 : 2024-04-23 Robert Hansen renamed "PA" field to "IOU_AC_Territory"
################################################################################
*/
SELECT
    ' + CONVERT(VARCHAR,@JobID) + ' AS JobID, 
    IOU_AC_Territory,
    PrgID,
    '''' AS ProgramName,
    ClaimYearQuarter,
    AdminCostsOverheadAndGA,
    AdminCostsOther,
    MarketingOutreach,
    DIActivity,
    DIInstallation,
    DIHardwareAndMaterials,
    DIRebateAndInspection,
    EMV,
    UserInputIncentive,
    CostsRecoveredFromOtherSources,
    OnBillFinancing
FROM [dbo].SourceProgramvw'
END


IF @SourceType = 'EDFilledDatabase'
BEGIN

    SET @MappingMeasurevwSql = 'ALTER VIEW [dbo].[MappingMeasurevw] AS
/*
################################################################################
Name : MappingMeasurevw
Date : 2016-06-30
Author : Wayne Hauck
Company : Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose : This view maps the source input to CET-compatible field names. This allows multiple input formats to be mapped to one format. It is code-generated in the InitializeTables saved procedure.
Usage : n/a
Called by : n/a
Copyright � : Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
Change History : 2016-06-30  Wayne Hauck added comment header
 : 2021-04-18 Robert Hansen added new columns for additional load for fuel substitution measures
 : 2021-05-17 Robert Hansen added new benefits and costs columns
 : 2021-05-25 Robert Hansen removed MEBens and MECost fields
 : 2022-08-30 Robert Hansen added new fields for water energy calculations
 : 2024-04-23 Robert Hansen renamed "PA" field to "IOU_AC_Territory"
################################################################################
*/

SELECT
' + CONVERT(VARCHAR,@JobID) + ' as JobID,ClaimID CET_ID,IOU_AC_Territory,
ProgramID PrgID,ProgramName,Measurename,MeasureID,MeasImpactType,
CASE WHEN ElectricMeasureEndUseShape LIKE ''Non_res:DEER%'' THEN ''Non_res'' ELSE CASE WHEN ElectricMeasureEndUseShape LIKE ''res:DEER%'' THEN ''Res'' ELSE ElectricTargetSector END END AS ElecTargetSector,
CASE WHEN ElectricMeasureEndUseShape LIKE ''Non_res:DEER%'' THEN Replace(ElectricMeasureEndUseShape,''Non_res:'','''') ELSE CASE WHEN ElectricMeasureEndUseShape LIKE ''res:DEER%'' THEN Replace(ElectricMeasureEndUseShape,''res:'','''') ELSE ElectricMeasureEndUseShape END END AS ElecEndUseShape,
/*CASE WHEN ElectricMeasureAddEndUseShape LIKE ''Non_res:DEER%'' THEN Replace(ElectricMeasureAddEndUseShape,''Non_res:'','''') ELSE CASE WHEN ElectricMeasureAddEndUseShape LIKE ''res:DEER%'' THEN Replace(ElectricMeasureAddEndUseShape,''res:'','''') ELSE ElectricMeasureALEndUseShape END END AS ElecEndUseShape,*/
E3ClimateZone ClimateZone,GasSector,GasSavingsProfile,/*GasAddProfile,*/
'''' ElecRateSchedule,'''' GasRateSchedule,' + @CombType + ' CombType,
ClaimYearQuarter,Quantity Qty,UESkW,UESkWh,UESTherms UESThm,UESkW_ER,
UESkWh_ER,UESTherms_ER UESThm_ER,/*UALkW,UALkWh,UALTherms UALThm,UALkW_ER,
UALkWh_ER,UALTherms_ER UALThm_ER,*/UESkWh_IOUWater,UESkWh_IOUWater_ER,WaterUse,
NTGRkW,NTGRkWh,NTGRTherms NTGRThm,
NTGRCost,EUL,RUL,IRkWh IR,IRkW,IRkWh,IRTherms IRThm,RRkWh,RRkW,
RRTherms RRThm,IncentiveToOthers,EndUserRebate,DirectInstallLaborCost DILaborCost,
DirectInstallMaterialCost DIMaterialCost,UnitMeasureGrossCost,
UnitMeasureGrossCost_ER,' + @MeasInflation + ' AS MeasInflation,
UnitGasInfraBens,UnitRefrigCosts,UnitRefrigBens,UnitMiscCosts,MiscCostsDesc,
UnitMiscBens,MiscBensDesc,'''' AS Sector,'''' AS EndUse,'''' AS BuildingType,
'''' AS MeasureGroup,'''' AS SolutionCode,'''' AS Technology,'''' AS Channel,
'''' AS IsCustom,'''' AS Location,'''' AS ProgramType,'''' AS UnitType,
'''' AS Comments,'''' AS DataField
FROM [dbo].[SourceMeasurevw]
'

    SET @MappingProgramvw = 'ALTER VIEW [dbo].[MappingProgramvw] AS
/*
################################################################################
Name : MappingProgramvw
Date : 2016-06-30
Author : Wayne Hauck
Company : Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose : This view maps the source input to CET-compatible field names. This allows multiple input formats to be mapped to one format. It is code-generated in the InitializeTables saved procedure.
Usage : n/a
Called by : n/a
Copyright � : Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
Change History : 2016-06-30  Wayne Hauck added comment header
 : 2021-04-18 Robert Hansen added new columns for additional load for fuel substitution measures
 : 2021-05-17 Robert Hansen added new benefits and costs columns
 : 2024-04-23 Robert Hansen renamed "PA" field to "IOU_AC_Territory"
################################################################################
*/
SELECT
    ' + CONVERT(VARCHAR,@JobID) + ' AS JobID,
    IOU_AC_Territory,
    PrgID,
    '''' AS ProgramName,
    ClaimYearQuarter,
    AdminCostsOverheadAndGA,
    AdminCostsOther,
    MarketingOutreach,
    DIActivity,
    DIInstallation,
    DIHardwareAndMaterials,
    DIRebateAndInspection,
    EMV,
    IncentRebatesUserInputIncentive UserInputIncentive,
    CostsRecoveredFromOtherSources,
    OnBillFinancing
FROM [dbo].SourceProgramvw'
END


IF @SourceType = 'CEDARS' OR @SourceType = 'CEDARSDatabase' OR @SourceType = 'CEDARSExcel'
BEGIN
    SET @MappingMeasurevwSql = 'ALTER VIEW [dbo].[MappingMeasurevw] AS
/*
################################################################################
Name : MappingMeasurevw
Date : 2016-06-30
Author : Wayne Hauck
Company : Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose : This view maps the source input to CET-compatible field names. This allows multiple input formats to be mapped to one format.
Usage : n/a
Called by : n/a
Copyright � : Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
Change History : 2016-06-30  Wayne Hauck added comment header
 : 2021-04-18 Robert Hansen added new columns for additional load for fuel substitution measures
 : 2021-05-17 Robert Hansen added new benefits and costs columns
 : 2021-05-25 Robert Hansen removed MEBens and MECost fields
 : 2022-08-30 Robert Hansen added new fields for water energy calculations
 : 2024-04-23 Robert Hansen renamed "PA" field to "IOU_AC_Territory"
################################################################################
*/

SELECT
' + CONVERT(VARCHAR,@JobID) + ' AS JobID,CEInputID CET_ID,IOU_AC_Territory,PrgID,
'''' AS ProgramName,MeasDescription Measurename,MeasureID,MeasImpactType,
CASE WHEN E3MeaElecEndUseShape LIKE ''Non_res:DEER%'' THEN ''Non_res'' ELSE CASE WHEN E3MeaElecEndUseShape LIKE ''res:DEER%'' THEN ''Res'' ELSE E3TargetSector END END AS ElecTargetSector,
CASE WHEN E3MeaElecEndUseShape LIKE ''Non_res:DEER%'' THEN Replace(E3MeaElecEndUseShape,''Non_res:'','''') ELSE CASE WHEN E3MeaElecEndUseShape LIKE ''res:DEER%'' THEN Replace(E3MeaElecEndUseShape,''res:'','''') ELSE E3MeaElecEndUseShape END END AS ElecEndUseShape,
/*CASE WHEN E3MeaElecAddEndUseShape LIKE ''Non_res:DEER%'' THEN Replace(E3MeaElecAddEndUseShape,''Non_res:'','''') ELSE CASE WHEN E3MeaElecAddEndUseShape LIKE ''res:DEER%'' THEN Replace(E3MeaElecAddEndUseShape,''res:'','''') ELSE E3MeaElecAddEndUseShape END END AS ElecAddEndUseShape,*/
E3ClimateZone ClimateZone,E3GasSector GasSector,E3GasSavProfile GasSavingsProfile,
/*E3GasAddProfile GasAdditionalLoadProfile,*/RateScheduleElec ElecRateSchedule,
RateScheduleGas GasRateSchedule,' + @CombType + ' AS CombType,ClaimYearQuarter,
NumUnits Qty,UnitkW1stBaseline UESkW,UnitkWh1stBaseline UESkWh,
UnitTherm1stBaseline UESThm,UnitkW2ndBaseline UESkW_ER,
UnitkWh2ndBaseline UESkWh_ER,UnitTherm2ndBaseline UESThm_ER,
/*UnitAddkW1stBaseline UALkW,UnitAddkWh1stBaseline UALkWh,
UnitAddTherm1stBaseline UALThm,UnitAddkW2ndBaseline UALkW_ER,
UnitAddkWh2ndBaseline UALkWh_ER,UnitAddTherm2ndBaseline UALThm_ER,*/
UnitkWhIOUWater1stBaseline UESkWh_IOUWater,
UnitkWhIOUWater2ndBaseline UESkWh_IOUWater_ER,WaterUse,
NTGRkW,NTGRkWh,NTGRTherm NTGRThm,NTGRCost,EUL_Yrs EUL,RUL_Yrs RUL,
InstallationRatekWh IR,InstallationRatekW IRkW,
InstallationRatekWh IRkWh,InstallationRateTherm IRThm,
RealizationRatekWh RRkWh,RealizationRatekW RRkW,
RealizationRateTherm RRThm,UnitIncentiveToOthers IncentiveToOthers,
UnitEndUserRebate EndUserRebate,UnitDirectInstallLab DILaborCost,
UnitDirectInstallMat DIMaterialCost,
UnitMeaCost1stBaseline UnitMeasureGrossCost,
UnitMeaCost2ndBaseline UnitMeasureGrossCost_ER,
ISNULL(MeasInflation,0) AS MeasInflation,UnitGasInfraBens,UnitRefrigCosts,
UnitRefrigBens,UnitMiscCosts,MiscCostsDesc,UnitMiscBens,MiscBensDesc,Sector,
'''' AS EndUse,'''' AS BuildingType,'''' AS MeasureGroup,'''' AS SolutionCode,
'''' AS Technology,'''' AS Channel,'''' AS IsCustom,'''' AS Location,
'''' AS ProgramType,'''' AS UnitType,'''' AS Comments,'''' AS DataField
FROM [dbo].[SourceMeasurevw]
'

SET @MappingProgramvw = 'ALTER VIEW [dbo].[MappingProgramvw] AS
/*
################################################################################
Name : MappingProgramvw
Date : 2016-06-30
Author : Wayne Hauck
Company : Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose : This view maps the source input to CET-compatible field names. This allows multiple input formats to be mapped to one format. It is code-generated in the InitializeTables saved procedure.
Usage : n/a
Called by : n/a
Copyright � : Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
Change History : 2016-06-30  Wayne Hauck added comment header
 : 2021-04-18 Robert Hansen added new columns for additional load for fuel substitution measures
 : 2021-05-17 Robert Hansen added new benefits and costs columns
 : 2024-04-23 Robert Hansen renamed "PA" field to "IOU_AC_Territory"
################################################################################
*/
SELECT
    ' + CONVERT(VARCHAR,@JobID) + ' AS JobID, 
    IOU_AC_Territory,
    PrgID,
    '''' AS ProgramName,
    ClaimYearQuarter,
    AdminCostsOverheadAndGA,
    AdminCostsOther,
    MarketingOutreach,
    DIActivity,
    DIInstallation,
    DIHardwareAndMaterials,
    DIRebateAndInspection,
    EMV,
    UserInputIncentive,
    CostsRecoveredFromOtherSources, 
    OnBillFinancing
FROM [dbo].SourceProgramvw'
END

--**************************************************************************************
-- Script InputMeasurevw View because the calculated field 'Qm' is dependent on First Year.
SET @InputMeasurevwSql = 'ALTER VIEW [dbo].[InputMeasurevw] AS
/*
#################################################################################################
Name : InputMeasurevw
Date : 2016-06-30
Author : Wayne Hauck
Company : Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose : This view 1) sets the core variables for cost effectiveness calculations, 2) handles nulls, 3) calculates quarters based on first year of implementation, and 4) calculates calculated fields.
Usage : n/a
Called by : n/a
Copyright � : Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
Change History : 2016-06-30 Wayne Hauck added comment header with encryption
 : 2021-04-18 Robert Hansen added new columns for additional load for fuel substitution measures
 : 2021-05-17 Robert Hansen added new benefits and costs columns
 : 2021-05-25 Robert Hansen removed MEBens and MECost fields
 : 2022-08-30 Robert Hansen new fields for water energy calculations
 : 2024-04-23 Robert Hansen renamed "PA" field to "IOU_AC_Territory"
################################################################################
*/

SELECT
' + CONVERT(VARCHAR,@JobID) + ' AS JobID,
CET_ID,IOU_AC_Territory,PrgID,ProgramName,MeasureName,MeasureID,MeasImpactType,ISNULL(ElecTargetSector,'''') TS,
ISNULL(ElecEndUseShape,'''') EU,/*ISNULL(ElecAddEndUseShape,'''') EUAL,*/
ISNULL(ClimateZone,'''') CZ,ISNULL(GasSector,'''') GS,ISNULL(GasSavingsProfile,'''') GP,
/*ISNULL(GasAdditionalLoadProfile,'''') GPAL,*/ISNULL(ElecRateSchedule,'''') ElecRateSchedule,
ISNULL(GasRateSchedule,'''') GasRateSchedule,' + @AVCVersion + ' AVCVersion,
CombType,ClaimYearQuarter Qtr,
(CONVERT(INT,SUBSTRING(ClaimYearQuarter,1,4)-' + CONVERT(VARCHAR,@FirstYear) + ')*4)+CONVERT(INT,SUBSTRING(ClaimYearQuarter,6,1))-1 Qm,
(CONVERT(INT,SUBSTRING(ClaimYearQuarter,1,4)-' + CONVERT(VARCHAR,@FirstYear) + ')) Qy,
ISNULL(Qty,0) Qty,ISNULL(UESkW,0) kW1,ISNULL(UESkWh,0) kWh1,ISNULL(UESThm,0) Thm1,
ISNULL(UESkW_ER,0) kW2,ISNULL(UESkWh_ER,0) kWh2,ISNULL(UESThm_ER,0) Thm2,
/*ISNULL(UALkW,0) kW1_AL,ISNULL(UALkWh,0) kWh1_AL,ISNULL(UALThm,0) Thm1_AL,
ISNULL(UALkW_ER,0) kW2_AL,ISNULL(UALkWh_ER,0) kWh2_AL,ISNULL(UALThm_ER,0) Thm2_AL,*/
ISNULL(UESkWh_IOUWater,0) kWhWater1,ISNULL(UESkWh_IOUWater_ER,0) kWhWater2,WaterUse,
Coalesce(NTGRkW,NTGRkWh,1) NTGRkW,ISNULL(NTGRkWh,1) NTGRkWh,
Coalesce(NTGRThm,NTGRkWh,1) NTGRThm,Coalesce(NTGRCost,NTGRkWh,1) NTGRCost,
ISNULL(IRkWh,1) IR,ISNULL(IRkW,1) IRkW,ISNULL(IRkWh,1) IRkWh,ISNULL(IRThm,1) IRThm,
ISNULL(RRkWh,1) RR,ISNULL(RRkWh,1) RRkWh,ISNULL(RRkW,1) RRkW,ISNULL(RRThm,1) RRThm,
ISNULL(IncentiveToOthers,0) IncentiveToOthers,ISNULL(EndUserRebate,0) EndUserRebate,
ISNULL(DILaborCost,0) DILaborCost,ISNULL(DIMaterialCost,0) DIMaterialCost,
ISNULL(UnitMeasureGrossCost,0) UnitMeasureGrossCost,
ISNULL(UnitMeasureGrossCost_ER,0) UnitMeasureGrossCost_ER,ISNULL(EUL,0)*4 eulq,
CASE WHEN ISNULL(RUL,0)>=ISNULL(EUL,0) THEN ISNULL(RUL,0) WHEN ISNULL(RUL,0)>0 THEN RUL ELSE ISNULL(EUL,0) END*4 eulq1,
CASE WHEN ISNULL(CASE WHEN RUL>=EUL THEN 0 ELSE RUL END,0)>0 THEN ISNULL(EUL,0)*4 ELSE 0 END eulq2,
CASE WHEN ISNULL(RUL,0) >= ISNULL(EUL,0) THEN ISNULL(RUL,0) WHEN ISNULL(RUL,0)>0 THEN RUL ELSE ISNULL(EUL,0) END eul1,
CASE WHEN ISNULL( CASE WHEN RUL >= EUL THEN 0 ELSE RUL END,0)>0 THEN ISNULL(EUL,0) ELSE 0 END eul2,
ISNULL( CASE WHEN RUL >= EUL THEN 0 ELSE RUL END, 0 )*4 rulq,
CASE WHEN ISNULL(RUL,0) >= ISNULL(EUL,0) THEN ISNULL(RUL,0) ELSE ISNULL(EUL,0) END EUL,
ISNULL( CASE WHEN RUL >= EUL THEN 0 ELSE RUL END,0) RUL,
IOU_AC_Territory + ElecTargetSector + ElecEndUseShape + ClimateZone ACElecKey,
IOU_AC_Territory + GasSector + GasSavingsProfile ACGasKey,
ISNULL(UnitMeasureGrossCost_ER,0) MeasIncrCost,
ISNULL(MeasInflation,0) MeasInflation,UnitGasInfraBens,UnitRefrigCosts,
UnitRefrigBens,UnitMiscCosts,MiscCostsDesc,UnitMiscBens,MiscBensDesc,
Sector,EndUse,BuildingType,MeasureGroup,SolutionCode,Technology,Channel,IsCustom,
Location,ProgramType,UnitType,Comments,DataField
FROM MappingMeasurevw
'

IF @IncludeNonresourceCosts = 1
BEGIN

SET @InputMeasurevwSql = @InputMeasurevwSql +
'UNION SELECT 
JobID,CET_ID,IOU_AC_Territory,PrgID,ProgramName,MeasureName,MeasureID,'''' MeasImpactType,TS,EU,/*EUAL,*/CZ,GS,GP,
/*GPAL,*/ElecRateSchedule,GasRateSchedule,' + @AVCVersion + ' AVCVersion,
CombType,Qtr,Qm,Qy,Qty,kW1,kWh1,Thm1,kW2,kWh2,Thm2,/*kW1_AL,kWh1_AL,Thm1_AL,
kW2_AL,kWh2_AL,Thm2_AL,*/
kWhWater1,kWhWater2,WaterUse,
NTGRkW,NTGRkWh,NTGRThm,NTGRCost,IR,IRkW,IRkWh,IRThm,
RR,RRkWh,RRkW,RRThm,IncentiveToOthers,EndUserRebate,DILaborCost,DIMaterialCost,
UnitMeasureGrossCost,UnitMeasureGrossCost_ER,eulq,eulq1,eulq2,eul1,eul2,rulq,
EUL,RUL,ACElecKey,ACGasKey,MeasIncrCost,0 MeasInflation,UnitGasInfraBens,UnitRefrigCosts,
UnitRefrigBens,UnitMiscCosts,MiscCostsDesc,UnitMiscBens,MiscBensDesc,
Sector,EndUse,BuildingType,MeasureGroup,SolutionCode,Technology,Channel,IsCustom,Location,
ProgramType,UnitType,Comments,DataField
FROM [InputMeasureNonResourcevw] 
'
 
END

BEGIN TRY

    EXEC  sp_executesql @MappingMeasurevwSql
    EXEC  sp_executesql @MappingProgramvw
    EXEC  sp_executesql @InputMeasurevwSql

---------End Mapping Data  --------


DELETE FROM OutputCE

DELETE FROM OutputEmissions

DELETE FROM OutputSavings

DELETE FROM OutputCost

----End Initialize Tables

END TRY

BEGIN CATCH

    DECLARE @ErrorMessage NVARCHAR(2000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
    DECLARE @ErrorProcedure NVARCHAR(2000);
    DECLARE @ErrorText NVARCHAR(4000);

    SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE(),
        @ErrorProcedure = ERROR_PROCEDURE(),
        @ErrorText = @ErrorProcedure + ': ' + @ErrorMessage;
        UPDATE [dbo].[CETJobs]
    SET [StatusDetail] =  @ErrorProcedure + ': ' + @ErrorMessage
    WHERE [ID] = @JobID
    
    RAISERROR (@ErrorText, 
               @ErrorSeverity,
               @ErrorState
    );    
END CATCH

GO