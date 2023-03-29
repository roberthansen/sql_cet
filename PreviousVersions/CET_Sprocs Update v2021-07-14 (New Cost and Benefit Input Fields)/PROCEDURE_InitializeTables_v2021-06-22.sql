/*
################################################################################
Name             :  InitializeTables (procedure)
Date             :  06/30/2016
Author           :  Wayne Hauck
Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose          :  This stored procedure initializes tables which prepares
                    views for running cost effectiveness.
Usage            :  n/a
Called by        :  n/a
Copyright ©      :  Developed by Pinnacle Consulting Group (aka InTech Energy,
                    Inc.) for California Public Utilities Commission (CPUC).
                    All Rights Reserved.
Change History   :  06/30/2016  Wayne Hauck added comment header
                 :  12/30/2016  Wayne Hauck added Measure Inflation flex field
                 :  04/18/2021  Robert Hansen added new columns for additional
                                load for fuel substitution measures
				 :  05/13/2021  Robert Hansen updated additional load field
								names according to email from DNV GL
				 :  05/25/2021  Robert Hansen removed MEBens and MECost fields
				 :  2021-06-16  Robert Hansen commented out new fields for fuel
				    substitution for implementation at a later date
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
Date : 06/30/2016
Author : Wayne Hauck
Company : Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose : This view maps the source input to CET-compatible field names. This allows multiple input formats to be mapped to one format. It is code-generated in the InitializeTables saved procedure.
Usage : n/a
Called by : n/a
Copyright © : Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
Change History : 06/30/2016  Wayne Hauck added comment header
 : 04/18/2021 Robert Hansen added new columns for additional load for fuel substitution measures
 : 05/17/2021 Robert Hansen added new benefits and costs columns
 : 05/25/2021 Robert Hansen removed MEBens and MECost fields
################################################################################
*/

SELECT
' + CONVERT(VARCHAR,@JobID) + 'AS JobID,CET_ID,PA,PrgID,ProgramName,MeasureName,
MeasureID,MeasImpactType,
CASE WHEN ElecEndUseShape LIKE ''Non_res:DEER%'' THEN ''Non_res'' ELSE CASE WHEN ElecEndUseShape LIKE ''res:DEER%'' THEN ''Res'' ELSE ElecTargetSector END END AS ElecTargetSector,
CASE WHEN ElecEndUseShape LIKE ''Non_res:DEER%'' THEN Replace(ElecEndUseShape,''Non_res:'','''') ELSE CASE WHEN ElecEndUseShape LIKE ''res:DEER%'' THEN Replace(ElecEndUseShape,''res:'','''') ELSE ElecEndUseShape END END AS ElecEndUseShape,
/*CASE WHEN ElecEndUseShapeAL LIKE ''Non_res:DEER%'' THEN Replace(ElecEndUseShapeAL,''Non_res:'','''') ELSE CASE WHEN ElecEndUseShapeAL LIKE ''res:DEER%'' THEN Replace(ElecEndUseShapeAL,''res:'','''') ELSE  ElecEndUseShapeAL END END AS ElecEndUseShapeAL,*/
ClimateZone,GasSector,GasSavingsProfile,/*GasSavingsProfileAL,*/
'''' AS ElecRateSchedule,'''' AS GasRateSchedule,' + @CombType + ' AS CombType,
ClaimYearQuarter,Qty,UESkW,UESkWh,UESThm,UESkW_ER,UESkWh_ER,UESThm_ER,/*UALkW,
UALkWh,UALThm,UALkW_ER,UALkWh_ER,UALThm_ER,*/NTGRkW,NTGRkWh,NTGRThm,NTGRCostEUL,
RUL,IRkWh AS IR,IRkW,IRkWh,IRThm,RRkWh,RRkW,RRThm,IncentiveToOthers,
EndUserRebate,DILaborCost,DIMaterialCost,UnitMeasureGrossCost,
UnitMeasureGrossCost_ER,' + @MeasInflation + ' AS MeasInflation,
UnitGasInfraBens, UnitRefrigCosts,UnitRefrigBens,UnitMiscCosts,MiscCostsDesc,
UnitMiscBens,MiscBensDesc,Sector,EndUse,BuildingType,MeasureGroup,SolutionCode,
Technology,Channel,IsCustom,Location,ProgramType,UnitType,Comments,DataField
FROM [SourceMeasurevw]
'

SET @MappingProgramvw = 'ALTER VIEW [dbo].[MappingProgramvw] AS
/*
################################################################################
Name : MappingProgramvw
Date : 06/30/2016
Author : Wayne Hauck
Company : Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose : This view maps the source input to CET-compatible field names. This allows multiple input formats to be mapped to one format. It is code-generated in the InitializeTables saved procedure.
Usage : n/a
Called by : n/a
Copyright © : Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
Change History : 06/30/2016  Wayne Hauck added comment header
################################################################################
*/
SELECT
    ' + CONVERT(VARCHAR,@JobID) + ' AS JobID, 
    PA,
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
Date : 06/30/2016
Author : Wayne Hauck
Company : Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose : This view maps the source input to CET-compatible field names. This allows multiple input formats to be mapped to one format. It is code-generated in the InitializeTables saved procedure.
Usage : n/a
Called by : n/a
Copyright © : Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
Change History : 06/30/2016  Wayne Hauck added comment header
 : 04/18/2021 Robert Hansen added new columns for additional load for fuel substitution measures
 : 05/17/2021 Robert Hansen added new benefits and costs columns
 : 05/25/2021 Robert Hansen removed MEBens and MECost fields
################################################################################
*/

SELECT
' + CONVERT(VARCHAR,@JobID) + ' AS JobID,
CEInputID AS CET_ID,PA,PrgID,'''' AS ProgramName,MeasDescription AS MeasureName,
MeasureID,MeasImpactType,
CASE WHEN E3MeaElecEndUseShape LIKE ''Non_res:DEER%'' THEN ''Non_res'' ELSE CASE WHEN E3MeaElecEndUseShape LIKE ''res:DEER%'' THEN ''Res'' ELSE E3TargetSector END END AS ElecTargetSector,
CASE WHEN E3MeaElecEndUseShape LIKE ''Non_res:DEER%'' THEN Replace(E3MeaElecEndUseShape,''Non_res:'','''') ELSE CASE WHEN E3MeaElecEndUseShape LIKE ''res:DEER%'' THEN Replace(E3MeaElecEndUseShape,''res:'','''') ELSE E3MeaElecEndUseShape END END AS ElecEndUseShape,
/*CASE WHEN E3MeaElecAddEndUseShape LIKE ''Non_res:DEER%'' THEN Replace(E3MeaElecAddEndUseShape,''Non_res:'','''') ELSE CASE WHEN E3MeaElecAddEndUseShape LIKE ''res:DEER%'' THEN Replace(E3MeaElecAddEndUseShape,''res:'','''') ELSE E3MeaElecAddEndUseShape END END AS ElecAddEndUseShape,*/
E3ClimateZone AS ClimateZone,E3GasSector AS GasSector,
E3GasSavProfile AS GasSavingsProfile,/*E3GasAddProfile AS GasAdditionalLoadProfile,*/
'''' AS ElecRateSchedule,'''' AS GasRateSchedule,' + @CombType + ' AS CombType,
ClaimYearQuarter,NumUnits AS Qty,UnitkW1stBaseline AS UESkW,
UnitkWh1stBaseline AS UESkWh,UnitTherm1stBaseline AS UESThm,
UnitkW2ndBaseline AS UESkW_ER,UnitkWh2ndBaseline AS UESkWh_ER,
UnitTherm2ndBaseline AS UESThm_ER,/*UnitAddkW1stBaseline AS UALkW,
UnitAddkWh1stBaseline AS UALkWh,UnitAddTherm1stBaseline AS UALThm,
UnitAddkW2ndBaseline AS UALkW_ER,UnitAddkWh2ndBaseline AS UALkWh_ER,
UnitAddTherm2ndBaseline AS UALThm_ER,*/EUL_Yrs AS EUL,RUL_Yrs AS RUL,NTGRkW,NTGRkWh,
NTGRTherm AS NTGRThm,NTGRCost,InstallationRatekWh AS IR,
InstallationRatekW AS IRkW,InstallationRatekWh AS IRkWh,
InstallationRateTherm AS IRThm,RealizationRatekWh AS RRkWh,
RealizationRatekW AS RRkW,RealizationRateTherm AS RRThm,
UnitIncentiveToOthers AS IncentiveToOthers,UnitEndUserRebate AS EndUserRebate,
UnitDirectInstallLab AS DILaborCost,UnitDirectInstallMat AS DIMaterialCost,
UnitMeaCost1stBaseline AS UnitMeasureGrossCost,
UnitMeaCost2ndBaseline AS UnitMeasureGrossCost_ER,
' + @MeasInflation + ' AS MeasInflation,UnitGasInfraBens,UnitRefrigCosts,
UnitRefrigBens,UnitMiscCosts,MiscCostsDesc,UnitMiscBens,MiscBensDesc,Sector,
'''' AS EndUse,BldgType AS BuildingType,'''' AS MeasureGroup,
'''' AS SolutionCode,TechType AS Technology,DeliveryType AS Channel,
'''' AS IsCustom,'''' AS Location,'''' AS ProgramType,NormUnit AS UnitType,
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
Date : 06/30/2016
Author : Wayne Hauck
Company : Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose : This view maps the source input to CET-compatible field names. This allows multiple input formats to be mapped to one format. It is code-generated in the InitializeTables saved procedure.
Usage : n/a
Called by : n/a
Copyright © : Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
Change History : 06/30/2016  Wayne Hauck added comment header
 : 04/18/2021 Robert Hansen added new columns for additional load for fuel substitution measures
 : 05/17/2021 Robert Hansen added new benefits and costs columns
################################################################################
*/
SELECT
    ' + CONVERT(VARCHAR,@JobID) + ' AS JobID, 
    PA,
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
Date : 06/30/2016
Author : Wayne Hauck
Company : Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose : This view maps the source input to CET-compatible field names. This allows multiple input formats to be mapped to one format. It is code-generated in the InitializeTables saved procedure.
Usage : n/a
Called by : n/a
Copyright © : Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
Change History : 06/30/2016  Wayne Hauck added comment header
 : 04/18/2021 Robert Hansen added new columns for additional load for fuel substitution measures
 : 05/17/2021 Robert Hansen added new benefits and costs columns
################################################################################
*/
SELECT
    ' + CONVERT(VARCHAR,@JobID) + ' AS JobID, 
    PA,
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
Date : 06/30/2016
Author : Wayne Hauck
Company : Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose : This view maps the source input to CET-compatible field names. This allows multiple input formats to be mapped to one format. It is code-generated in the InitializeTables saved procedure.
Usage : n/a
Called by : n/a
Copyright © : Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
Change History : 06/30/2016  Wayne Hauck added comment header
 : 04/18/2021 Robert Hansen added new columns for additional load for fuel substitution measures
 : 05/17/2021 Robert Hansen added new benefits and costs columns
 : 05/25/2021 Robert Hansen removed MEBens and MECost fields
################################################################################
*/

SELECT
' + CONVERT(VARCHAR,@JobID) + ' as JobID,ClaimID CET_ID,PA,ProgramID PrgID,
ProgramName,Measurename,MeasureID,MeasImpactType,
CASE WHEN ElectricMeasureEndUseShape LIKE ''Non_res:DEER%'' THEN ''Non_res'' ELSE CASE WHEN ElectricMeasureEndUseShape LIKE ''res:DEER%'' THEN ''Res'' ELSE ElectricTargetSector END END AS ElecTargetSector,
CASE WHEN ElectricMeasureEndUseShape LIKE ''Non_res:DEER%'' THEN Replace(ElectricMeasureEndUseShape,''Non_res:'','''') ELSE CASE WHEN ElectricMeasureEndUseShape LIKE ''res:DEER%'' THEN Replace(ElectricMeasureEndUseShape,''res:'','''') ELSE ElectricMeasureEndUseShape END END AS ElecEndUseShape,
/*CASE WHEN ElectricMeasureAddEndUseShape LIKE ''Non_res:DEER%'' THEN Replace(ElectricMeasureAddEndUseShape,''Non_res:'','''') ELSE CASE WHEN ElectricMeasureAddEndUseShape LIKE ''res:DEER%'' THEN Replace(ElectricMeasureAddEndUseShape,''res:'','''') ELSE ElectricMeasureALEndUseShape END END AS ElecEndUseShape,*/
E3ClimateZone AS ClimateZone,GasSector,GasSavingsProfile,/*GasAddProfile,*/
'''' AS ElecRateSchedule,'''' AS GasRateSchedule,' + @CombType + ' AS CombType,
ClaimYearQuarter,Quantity AS Qty,UESkW,UESkWh,UESTherms AS UESThm,UESkW_ER,
UESkWh_ER,UESTherms_ER AS UESThm_ER,/*UALkW,UALkWh,UALTherms AS UALThm,UALkW_ER,
UALkWh_ER,UALTherms_ER AS UALThm_ER,*/NTGRkW,NTGRkWh,NTGRTherms AS NTGRThm,
NTGRCost,EUL,RUL,IRkWh AS IR,IRkW,IRkWh,IRTherms AS IRThm,RRkWh,RRkW,
RRTherms RRThm,IncentiveToOthers,EndUserRebate,DirectInstallLaborCost AS DILaborCost,
DirectInstallMaterialCost AS DIMaterialCost,UnitMeasureGrossCost,
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
Date : 06/30/2016
Author : Wayne Hauck
Company : Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose : This view maps the source input to CET-compatible field names. This allows multiple input formats to be mapped to one format. It is code-generated in the InitializeTables saved procedure.
Usage : n/a
Called by : n/a
Copyright © : Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
Change History : 06/30/2016  Wayne Hauck added comment header
 : 04/18/2021 Robert Hansen added new columns for additional load for fuel substitution measures
 : 05/17/2021 Robert Hansen added new benefits and costs columns
################################################################################
*/
SELECT
    ' + CONVERT(VARCHAR,@JobID) + ' AS JobID,
	PA,
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
	IncentRebatesUserInputIncentive AS UserInputIncentive,
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
Date : 06/30/2016
Author : Wayne Hauck
Company : Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose : This view maps the source input to CET-compatible field names. This allows multiple input formats to be mapped to one format.
Usage : n/a
Called by : n/a
Copyright © : Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
Change History : 06/30/2016  Wayne Hauck added comment header
 : 04/18/2021 Robert Hansen added new columns for additional load for fuel substitution measures
 : 05/17/2021 Robert Hansen added new benefits and costs columns
 : 05/25/2021 Robert Hansen removed MEBens and MECost fields
################################################################################
*/

SELECT
' + CONVERT(VARCHAR,@JobID) + ' AS JobID,CEInputID AS CET_ID,PA,PrgID,
'''' AS ProgramName,MeasDescription AS Measurename,MeasureID,MeasImpactType,
CASE WHEN E3MeaElecEndUseShape LIKE ''Non_res:DEER%'' THEN ''Non_res'' ELSE CASE WHEN E3MeaElecEndUseShape LIKE ''res:DEER%'' THEN ''Res'' ELSE E3TargetSector END END AS ElecTargetSector,
CASE WHEN E3MeaElecEndUseShape LIKE ''Non_res:DEER%'' THEN Replace(E3MeaElecEndUseShape,''Non_res:'','''') ELSE CASE WHEN E3MeaElecEndUseShape LIKE ''res:DEER%'' THEN Replace(E3MeaElecEndUseShape,''res:'','''') ELSE E3MeaElecEndUseShape END END AS ElecEndUseShape,
/*CASE WHEN E3MeaElecAddEndUseShape LIKE ''Non_res:DEER%'' THEN Replace(E3MeaElecAddEndUseShape,''Non_res:'','''') ELSE CASE WHEN E3MeaElecAddEndUseShape LIKE ''res:DEER%'' THEN Replace(E3MeaElecAddEndUseShape,''res:'','''') ELSE E3MeaElecAddEndUseShape END END AS ElecAddEndUseShape,*/
E3ClimateZone ClimateZone,E3GasSector GasSector,E3GasSavProfile GasSavingsProfile,
/*E3GasAddProfile GasAdditionalLoadProfile,*/RateScheduleElec ElecRateSchedule,
RateScheduleGas GasRateSchedule,' + @CombType + ' AS CombType,ClaimYearQuarter,
NumUnits AS Qty,UnitkW1stBaseline AS UESkW,UnitkWh1stBaseline AS UESkWh,
UnitTherm1stBaseline AS UESThm,UnitkW2ndBaseline AS UESkW_ER,
UnitkWh2ndBaseline AS UESkWh_ER,UnitTherm2ndBaseline AS UESThm_ER,
/*UnitAddkW1stBaseline AS UALkW,UnitAddkWh1stBaseline AS UALkWh,
UnitAddTherm1stBaseline AS UALThm,UnitAddkW2ndBaseline AS UALkW_ER,
UnitAddkWh2ndBaseline AS UALkWh_ER,UnitAddTherm2ndBaseline AS UALThm_ER,*/
NTGRkW,NTGRkWh,NTGRTherm NTGRThm,NTGRCost,EUL_Yrs AS EUL,RUL_Yrs AS RUL,
InstallationRatekWh AS IR,InstallationRatekW AS IRkW,
InstallationRatekWh AS IRkWh,InstallationRateTherm AS IRThm,
RealizationRatekWh AS RRkWh,RealizationRatekW AS RRkW,
RealizationRateTherm AS RRThm,UnitIncentiveToOthers AS IncentiveToOthers,
UnitEndUserRebate AS EndUserRebate,UnitDirectInstallLab AS DILaborCost,
UnitDirectInstallMat AS DIMaterialCost,
UnitMeaCost1stBaseline AS UnitMeasureGrossCost,
UnitMeaCost2ndBaseline AS UnitMeasureGrossCost_ER,
IsNull(MeasInflation,0) AS MeasInflation,UnitGasInfraBens,UnitRefrigCosts,
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
Date : 06/30/2016
Author : Wayne Hauck
Company : Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose : This view maps the source input to CET-compatible field names. This allows multiple input formats to be mapped to one format. It is code-generated in the InitializeTables saved procedure.
Usage : n/a
Called by : n/a
Copyright © : Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
Change History : 06/30/2016  Wayne Hauck added comment header
 : 04/18/2021 Robert Hansen added new columns for additional load for fuel substitution measures
 : 05/17/2021 Robert Hansen added new benefits and costs columns
################################################################################
*/
SELECT
    ' + CONVERT(VARCHAR,@JobID) + ' AS JobID, 
    PA,
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
Date : 06/30/2016
Author : Wayne Hauck
Company : Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose : This view 1) sets the core variables for cost effectiveness calculations, 2) handles nulls, 3) calculates quarters based on first year of implementation, and 4) calculates calculated fields.
Usage : n/a
Called by : n/a
Copyright © : Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
Change History : 06/30/2016 Wayne Hauck added comment header with encryption
 : 04/18/2021 Robert Hansen added new columns for additional load for fuel substitution measures
 : 05/17/2021 Robert Hansen added new benefits and costs columns
 : 05/25/2021 Robert Hansen removed MEBens and MECost fields
################################################################################
*/

SELECT
' + CONVERT(VARCHAR,@JobID) + ' AS JobID,
CET_ID,PA,PrgID,ProgramName,MeasureName,MeasureID,MeasImpactType,IsNull(ElecTargetSector,'''') AS TS,
IsNull(ElecEndUseShape,'''') AS EU,/*IsNull(ElecAddEndUseShape,'''') AS EUAL,*/
IsNull(ClimateZone,'''') AS CZ,IsNull(GasSector,'''') AS GS,IsNull(GasSavingsProfile,'''') AS GP,
/*IsNull(GasAdditionalLoadProfile,'''') AS GPAL,*/IsNull(ElecRateSchedule,'''') AS ElecRateSchedule,
IsNull(GasRateSchedule,'''') AS GasRateSchedule,' + @AVCVersion + ' AS AVCVersion,
CombType,ClaimYearQuarter AS Qtr,
(CONVERT(INT,SUBSTRING(ClaimYearQuarter,1,4)-' + CONVERT(VARCHAR,@FirstYear) + ')*4)+CONVERT(INT,SUBSTRING(ClaimYearQuarter,6,1))-1 AS Qm,
(CONVERT(INT,SUBSTRING(ClaimYearQuarter,1,4)-' + CONVERT(VARCHAR,@FirstYear) + ')) AS Qy,
IsNull(Qty,0) AS Qty,IsNull(UESkW,0) AS kW1,IsNull(UESkWh,0) AS kWh1,IsNull(UESThm,0) AS Thm1,
IsNull(UESkW_ER,0) AS kW2,IsNull(UESkWh_ER,0) AS kWh2,IsNull(UESThm_ER,0) AS Thm2,
/*IsNull(UALkW,0) AS kW1_AL,IsNull(UALkWh,0) AS kWh1_AL,IsNull(UALThm,0) AS Thm1_AL,
IsNull(UALkW_ER,0) AS kW2_AL,IsNull(UALkWh_ER,0) AS kWh2_AL,IsNull(UALThm_ER,0) AS Thm2_AL,*/
Coalesce(NTGRkW,NTGRkWh,1) AS NTGRkW,IsNull(NTGRkWh,1) AS NTGRkWh,
Coalesce(NTGRThm,NTGRkWh,1) AS NTGRThm,Coalesce(NTGRCost,NTGRkWh,1) AS NTGRCost,
IsNull(IRkWh,1) AS IR,IsNull(IRkW,1) AS IRkW,IsNull(IRkWh,1) AS IRkWh,IsNull(IRThm,1) AS IRThm,
IsNull(RRkWh,1) AS RR,IsNull(RRkWh,1) AS RRkWh,IsNull(RRkW,1) AS RRkW,IsNull(RRThm,1) AS RRThm,
IsNull(IncentiveToOthers,0) AS IncentiveToOthers,IsNull(EndUserRebate,0) AS EndUserRebate,
IsNull(DILaborCost,0) AS DILaborCost,IsNull(DIMaterialCost,0) AS DIMaterialCost,
IsNull(UnitMeasureGrossCost,0) AS UnitMeasureGrossCost,
IsNull(UnitMeasureGrossCost_ER,0) AS UnitMeasureGrossCost_ER,IsNull(EUL,0)*4 eulq,
CASE WHEN IsNull(RUL,0)>=IsNull(EUL,0) THEN IsNull(RUL,0) WHEN IsNull(RUL,0)>0 THEN RUL ELSE IsNull(EUL,0) END*4 AS eulq1,
CASE WHEN IsNull(CASE WHEN RUL>=EUL THEN 0 ELSE RUL END,0)>0 THEN IsNull(EUL,0)*4 ELSE 0 END AS eulq2,
CASE WHEN IsNull(RUL,0) >= IsNull(EUL,0) THEN IsNull(RUL,0) WHEN IsNull(RUL,0)>0 THEN RUL ELSE IsNull(EUL,0) END AS eul1,
CASE WHEN IsNull( CASE WHEN RUL >= EUL THEN 0 ELSE RUL END,0)>0 THEN IsNull(EUL,0) ELSE 0 END AS eul2,
IsNull( CASE WHEN RUL >= EUL THEN 0 ELSE RUL END, 0 )*4 AS rulq,
CASE WHEN IsNull(RUL,0) >= IsNull(EUL,0) THEN IsNull(RUL,0) ELSE IsNull(EUL,0) END AS EUL,
IsNull( CASE WHEN RUL >= EUL THEN 0 ELSE RUL END,0) AS RUL,
PA + ElecTargetSector + ElecEndUseShape + ClimateZone AS ACElecKey,
PA + GasSector + GasSavingsProfile AS ACGasKey,
IsNull(UnitMeasureGrossCost_ER,0) AS MeasIncrCost,
IsNull(MeasInflation,0) AS MeasInflation,UnitGasInfraBens,UnitRefrigCosts,
UnitRefrigBens,UnitMiscCosts,MiscCostsDesc,UnitMiscBens,MiscBensDesc,Sector,
EndUse,BuildingType,MeasureGroup,SolutionCode,Technology,Channel,IsCustom,
Location,ProgramType,UnitType,Comments,DataField
FROM MappingMeasurevw
'

IF @IncludeNonresourceCosts = 1
BEGIN

SET @InputMeasurevwSql = @InputMeasurevwSql +
'UNION SELECT 
JobID,CET_ID,PA,PrgID,ProgramName,MeasureName,MeasureID,'''' AS MeasImpactType,TS,EU,/*EUAL,*/CZ,GS,GP,
/*GPAL,*/ElecRateSchedule,GasRateSchedule,' + @AVCVersion + ' AS AVCVersion,
CombType,Qtr,Qm,Qy,Qty,kW1,kWh1,Thm1,kW2,kWh2,Thm2,/*kW1_AL,kWh1_AL,Thm1_AL,
kW2_AL,kWh2_AL,Thm2_AL,*/NTGRkW,NTGRkWh,NTGRThm,NTGRCost,IR,IRkW,IRkWh,IRThm,
RR,RRkWh,RRkW,RRThm,IncentiveToOthers,EndUserRebate,DILaborCost,DIMaterialCost,
UnitMeasureGrossCost,UnitMeasureGrossCost_ER,eulq,eulq1,eulq2,eul1,eul2,rulq,
EUL,RUL,ACElecKey,ACGasKey,MeasIncrCost,0 AS MeasInflation,UnitGasInfraBens,UnitRefrigCosts,
UnitRefrigBens,UnitMiscCosts,MiscCostsDesc,UnitMiscBens,MiscBensDesc,Sector,EndUse,
BuildingType,MeasureGroup,SolutionCode,Technology,Channel,IsCustom,Location,
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