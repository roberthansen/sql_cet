USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[InitializeTables]    Script Date: 12/16/2019 1:56:59 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO







--#################################################################################################
-- Name             :  InitializeTables
-- Date             :  06/30/2016
-- Author           :  Wayne Hauck
-- Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
-- Purpose          :  This stored procedure initializes tables which prepares views for running cost effectiveness.
-- Usage            :  n/a
-- Called by        :  n/a
-- Copyright ©      :  Developed by Pinnacle Consulting Group (aka InTech Energy, Inc.) for California Public Utilities Commission (CPUC). All Rights Reserved.
-- Change History   :  06/30/2016  Wayne Hauck added comment header
-- Change History   :  12/30/2016  Wayne Hauck added Measure Inflation flex field
--                     
--#################################################################################################

CREATE PROCEDURE [dbo].[InitializeTables]
@jobId INT = -1,
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
DECLARE @ISCombustType int;
DECLARE @CombType nvarchar(255);
DECLARE @ISMeasInflation int;
DECLARE @MeasInflation nvarchar(255);

---------Check for Combustion Type in Source data  --------
SET @ISCombustType = (SELECT count(*) FROM sys.columns WHERE Name = N'CombustionType' and Object_ID = Object_ID(N'SourceMeasurevw'))
IF @ISCombustType = 0
BEGIN 
	SET @CombType = ',''Residential Furnaces (<0.3):Uncontrolled'' CombustionType'
	PRINT 'CombustionType field is not present in source table.'
END 
ELSE
BEGIN 
	SET @CombType = ',CombustionType'
	PRINT 'CombustionType is present in source table.'
END

---------Check for Measure Inflation in Source data  --------
SET @ISMeasInflation = (SELECT count(*) FROM sys.columns WHERE Name = N'MeasInflation' and Object_ID = Object_ID(N'SourceMeasurevw'))
IF @ISMeasInflation = 0
BEGIN 
	SET @MeasInflation = ',0 MeasInflation'
	PRINT 'Measure Inlation (MeasInflation) field is not present in source table.'
END 
ELSE
BEGIN 
	SET @MeasInflation = ',IsNull(MeasInflation,0) MeasInflation'
	PRINT 'Measure Inlation (MeasInflation) field is in source table.'
END

---------Start Mapping Source Data  --------


IF @SourceType = 'Excel' 
BEGIN

	SET @MappingMeasurevwSql = 'ALTER VIEW [dbo].[MappingMeasurevw]
								AS

--#################################################################################################
-- Name             :  MappingMeasurevw
-- Date             :  06/30/2016
-- Author           :  Wayne Hauck
-- Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
-- Purpose          :  This view maps the source input to CET-compatible field names. This allows multiple input formats to be mapped to one format.
-- Usage            :  n/a
-- Called by        :  n/a
-- Copyright ©      :  Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
-- Change History   :  06/30/2016  Wayne Hauck added comment header
--                     
--#################################################################################################

								SELECT ' + Convert(varchar,@jobId) + ' JobID 
									  ,CET_ID
									  ,PA
									  ,PrgID
									  ,ProgramName
									  ,MeasureName
									  ,MeasureID
 									  , CASE WHEN ElecEndUseShape like ''Non_res:DEER%'' THEN ''Non_res'' ELSE  CASE WHEN ElecEndUseShape like ''res:DEER%'' THEN ''Res'' ELSE  ElecTargetSector END END AS ElecTargetSector
									  , CASE WHEN ElecEndUseShape like ''Non_res:DEER%'' THEN Replace(ElecEndUseShape,''Non_Res:'','''') ELSE  CASE WHEN ElecEndUseShape like ''res:DEER%'' THEN Replace(ElecEndUseShape,''res:'','''') ELSE  ElecEndUseShape END END AS ElecEndUseShape
									  ,ClimateZone
									  ,GasSector
									  ,GasSavingsProfile
									  ,'''' ElecRateSchedule
									  ,'''' GasRateSchedule
									  ' + @CombType + '
									  ,ClaimYearQuarter
									  ,Qty
									  ,UESkW
									  ,UESkWh
									  ,UESThm
									  ,UESkW_ER
									  ,UESkWh_ER
									  ,UESThm_ER
									  ,NTGRkW
									  ,NTGRkWh
									  ,NTGRThm
									  ,NTGRCost
									  ,EUL
									  ,RUL
									  ,IRkWh IR
									  ,IRkW
									  ,IRkWh
									  ,IRThm
									  ,RRkWh
									  ,RRkW
									  ,RRThm
									  ,IncentiveToOthers
									  ,EndUserRebate
									  ,DILaborCost
									  ,DIMaterialCost
									  ,UnitMeasureGrossCost
									  ,UnitMeasureGrossCost_ER
									  ' + @MeasInflation + '
									  ,MarketEffectBens MEBens
									  ,MarketEffectCost MECost
									  ,Sector
									  ,EndUse
									  ,BuildingType
									  ,MeasureGroup
									  ,SolutionCode
									  ,Technology
									  ,Channel
									  ,IsCustom
									  ,Location
									  ,ProgramType
									  ,UnitType
									  ,Comments
									  ,DataField
								 FROM [SourceMeasurevw]'



	SET @MappingProgramvw = 'ALTER VIEW [dbo].[MappingProgramvw]
							 AS 
								SELECT ' + CONVERT(VARCHAR,@jobId) + ' JobID, 
								PA,
								PrgID,
								ProgramName,
								ClaimYearQuarter,
								[AdminCostsOverheadAndGA],
								[AdminCostsOther],
								[MarketingOutreach],
								[DIActivity],
								[DIInstallation],
								[DIHardwareAndMaterials],
								[DIRebateAndInspection],
								[EMV],
 								[UserInputIncentive],
								[CostsRecoveredFromOtherSources], 
								[OnBillFinancing]
								FROM SourceProgramvw' 

END


IF @SourceType = 'CETDatabase' OR @SourceType = 'CETInput'
BEGIN

	SET @MappingMeasurevwSql = 'ALTER VIEW [dbo].[MappingMeasurevw]
								AS

--#################################################################################################
-- Name             :  MappingMeasurevw
-- Date             :  06/30/2016
-- Author           :  Wayne Hauck
-- Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
-- Purpose          :  This view maps the source input to CET-compatible field names. This allows multiple input formats to be mapped to one format.
-- Usage            :  n/a
-- Called by        :  n/a
-- Copyright ©      :  Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
-- Change History   :  06/30/2016  Wayne Hauck added comment header
--                     
--#################################################################################################

								SELECT ' + Convert(varchar,@jobId) + ' JobID 
									  ,CET_ID
									  ,PA
									  ,PrgID
									  ,ProgramName
									  ,Measurename
									  ,MeasureID
 									  , CASE WHEN ElecEndUseShape like ''Non_res:DEER%'' THEN ''Non_res'' ELSE  CASE WHEN ElecEndUseShape like ''res:DEER%'' THEN ''Res'' ELSE  ElecTargetSector END END AS ElecTargetSector
									  , CASE WHEN ElecEndUseShape like ''Non_res:DEER%'' THEN Replace(ElecEndUseShape,''Non_Res:'','''') ELSE  CASE WHEN ElecEndUseShape like ''res:DEER%'' THEN Replace(ElecEndUseShape,''res:'','''') ELSE  ElecEndUseShape END END AS ElecEndUseShape
									  ,ClimateZone
									  ,GasSector
									  ,GasSavingsProfile
									  ,'''' ElecRateSchedule
									  ,''''GasRateSchedule
									  ' + @CombType + '
									  ,ClaimYearQuarter
									  ,Qty
									  ,UESkW
									  ,UESkWh
									  ,UESThm
									  ,UESkW_ER
									  ,UESkWh_ER
									  ,UESThm_ER
									  ,EUL
									  ,RUL
									  ,NTGRkW
									  ,NTGRkWh
									  ,NTGRThm
									  ,NTGRCost
									  ,IRkWh IR
									  ,IRkW
									  ,IRkWh
									  ,IRThm
									  ,RRkWh
									  ,RRkW
									  ,RRThm
									  ,[IncentiveToOthers]
									  ,[EndUserRebate]
									  ,DILaborCost
									  ,DIMaterialCost
									  ,UnitMeasureGrossCost
									  ,UnitMeasureGrossCost_ER
									  ' + @MeasInflation + '
									  ,MarketEffectBens MEBens
									  ,MarketEffectCost MECost
									  ,Sector
									  ,EndUse
									  ,BuildingType
									  ,MeasureGroup
									  ,SolutionCode
									  ,Technology
									  ,Channel
									  ,IsCustom
									  ,Location
									  ,ProgramType
									  ,UnitType
									  ,Comments
									  ,DataField
								 FROM [SourceMeasurevw]'


END

IF @SourceType = 'CETDatabase'
BEGIN
	SET @MappingProgramvw = 'ALTER VIEW [dbo].[MappingProgramvw]
								AS
								SELECT ' + Convert(varchar,@jobId) + ' JobID, 
									PA,
									PrgID,
									'''' ProgramName,
									ClaimYearQuarter,
									[AdminCostsOverheadAndGA],
									[AdminCostsOther],
									[MarketingOutreach],
									[DIActivity],
									[DIInstallation],
									[DIHardwareAndMaterials],
									[DIRebateAndInspection],
									[EMV],
									IncentRebatesUserInputIncentive [UserInputIncentive],
									[CostsRecoveredFromOtherSources], 
									[OnBillFinancing]
									FROM [dbo].SourceProgramvw'
END

IF @SourceType = 'CETInput'
BEGIN
	SET @MappingProgramvw = 'ALTER VIEW [dbo].[MappingProgramvw]
								AS
								SELECT ' + Convert(varchar,@jobId) + ' JobID, 
									PA,
									PrgID,
									'''' ProgramName,
									ClaimYearQuarter,
									[AdminCostsOverheadAndGA],
									[AdminCostsOther],
									[MarketingOutreach],
									[DIActivity],
									[DIInstallation],
									[DIHardwareAndMaterials],
									[DIRebateAndInspection],
									[EMV],
									[UserInputIncentive],
									[CostsRecoveredFromOtherSources], 
									[OnBillFinancing]
									FROM [dbo].SourceProgramvw'
END


IF @SourceType = 'EDFilledDatabase'
BEGIN

	SET @MappingMeasurevwSql = 'ALTER VIEW [dbo].[MappingMeasurevw]
								AS

--#################################################################################################
-- Name             :  MappingMeasurevw
-- Date             :  06/30/2016
-- Author           :  Wayne Hauck
-- Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
-- Purpose          :  This view maps the source input to CET-compatible field names. This allows multiple input formats to be mapped to one format.
-- Usage            :  n/a
-- Called by        :  n/a
-- Copyright ©      :  Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
-- Change History   :  06/30/2016  Wayne Hauck added comment header
--                     
--#################################################################################################

								SELECT -1 as JobID
									  ,ClaimID CET_ID
									  ,PA
									  ,ProgramID PrgID
									  ,ProgramName
									  ,Measurename
									  ,MeasureID
 									  , CASE WHEN ElectricMeasureEndUseShape like ''Non_res:DEER%'' THEN ''Non_res'' ELSE  CASE WHEN ElectricMeasureEndUseShape like ''res:DEER%'' THEN ''Res'' ELSE  ElectricTargetSector END END AS ElecTargetSector
									  , CASE WHEN ElectricMeasureEndUseShape like ''Non_res:DEER%'' THEN Replace(ElectricMeasureEndUseShape,''Non_Res:'','''') ELSE  CASE WHEN ElectricMeasureEndUseShape like ''res:DEER%'' THEN Replace(ElectricMeasureEndUseShape,''res:'','''') ELSE  ElectricMeasureEndUseShape END END AS ElecEndUseShape
									  ,E3ClimateZone ClimateZone
									  ,GasSector
									  ,GasSavingsProfile
									  ,''''ElecRateSchedule
									  ,''''GasRateSchedule
									  ' + @CombType + '
									  ,ClaimYearQuarter
									  ,Quantity Qty
									  ,UESkW
									  ,UESkWh
									  ,UESTherms UESThm
									  ,UESkW_ER
									  ,UESkWh_ER
									  ,UESTherms_ER UESThm_ER
									  ,NTGRkW
									  ,NTGRkWh
									  ,NTGRTherms NTGRThm
									  ,NTGRCost
									  ,EUL
									  ,RUL
									  ,IRkWh IR 
									  ,IRkW 
									  ,IRkWh 
									  ,IRTherms IRThm 
									  ,RRkWh
									  ,RRkW
									  ,RRTherms RRThm
									  ,[IncentiveToOthers]
									  ,[EndUserRebate]
									  ,DirectInstallLaborCost DILaborCost
									  ,DirectInstallMaterialCost DIMaterialCost
									  ,UnitMeasureGrossCost
									  ,UnitMeasureGrossCost_ER
									  ' + @MeasInflation + '
									  ,Null MEBens
									  ,Null MECost
									  ,'''' Sector
									  ,'''' EndUse
									  ,'''' BuildingType
									  ,'''' MeasureGroup
									  ,'''' SolutionCode
									  ,'''' Technology
									  ,'''' Channel
									  ,'''' IsCustom
									  ,'''' Location
									  ,'''' ProgramType
									  ,'''' UnitType
									  ,'''' Comments
									  ,'''' DataField
								  FROM [dbo].[SourceMeasurevw]'



	SET @MappingProgramvw = 'ALTER VIEW [dbo].[MappingProgramvw]
								AS
								SELECT ' + CONVERT(VARCHAR,@jobId) + ' JobID, 
									PA,
									PrgID,
									'''' ProgramName,
									ClaimYearQuarter,
									[AdminCostsOverheadAndGA],
									[AdminCostsOther],
									[MarketingOutreach],
									[DIActivity],
									[DIInstallation],
									[DIHardwareAndMaterials],
									[DIRebateAndInspection],
									[EMV],
									IncentRebatesUserInputIncentive [UserInputIncentive],
									[CostsRecoveredFromOtherSources], 
									[OnBillFinancing]
									FROM [dbo].SourceProgramvw'

END


IF @SourceType = 'CEDARS' OR @SourceType = 'CEDARSDatabase' OR @SourceType = 'CEDARSExcel'
BEGIN

	SET @MappingMeasurevwSql = 'ALTER VIEW [dbo].[MappingMeasurevw]
								AS

--#################################################################################################
-- Name             :  MappingMeasurevw
-- Date             :  06/30/2016
-- Author           :  Wayne Hauck
-- Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
-- Purpose          :  This view maps the source input to CET-compatible field names. This allows multiple input formats to be mapped to one format.
-- Usage            :  n/a
-- Called by        :  n/a
-- Copyright ©      :  Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
-- Change History   :  06/30/2016  Wayne Hauck added comment header
--                     
--#################################################################################################

								SELECT ' + Convert(varchar,@jobId) + ' JobID 
									  ,CEInputID CET_ID
									  ,PA
									  ,PrgID
									  ,'''' ProgramName
									  ,MeasDescription Measurename
									  ,MeasureID
 									  , CASE WHEN E3MeaElecEndUseShape like ''Non_res:DEER%'' THEN ''Non_res'' ELSE  CASE WHEN E3MeaElecEndUseShape like ''res:DEER%'' THEN ''Res'' ELSE  E3TargetSector END END AS ElecTargetSector
									  , CASE WHEN E3MeaElecEndUseShape like ''Non_res:DEER%'' THEN Replace(E3MeaElecEndUseShape,''Non_Res:'','''') ELSE  CASE WHEN E3MeaElecEndUseShape like ''res:DEER%'' THEN Replace(E3MeaElecEndUseShape,''res:'','''') ELSE  E3MeaElecEndUseShape END END AS ElecEndUseShape
									  ,E3ClimateZone ClimateZone
									  ,E3GasSector GasSector
									  ,E3GasSavProfile GasSavingsProfile
									  ,RateScheduleElec ElecRateSchedule
									  ,RateScheduleGas GasRateSchedule
									  ,CombustionType
									  ,ClaimYearQuarter
									  ,NumUnits Qty
									  ,UnitkW1stBaseline UESkW
									  ,UnitkWh1stBaseline UESkWh
									  ,UnitTherm1stBaseline UESThm
									  ,UnitkW2ndBaseline UESkW_ER
									  ,UnitkWh2ndBaseline UESkWh_ER
									  ,UnitTherm2ndBaseline UESThm_ER
									  ,NTGRkW
									  ,NTGRkWh
									  ,NTGRTherm NTGRThm
									  ,NTGRCost
									  ,[EUL_Yrs] EUL
									  ,[RUL_Yrs] RUL
									  ,InstallationRatekWh IR 
									  ,InstallationRatekW IRkW 
									  ,InstallationRatekWh IRkWh 
									  ,InstallationRateTherm IRThm 
									  ,RealizationRatekWh RRkWh
									  ,RealizationRatekW RRkW
									  ,RealizationRateTherm RRThm
									  ,UnitIncentiveToOthers [IncentiveToOthers]
									  ,UnitEndUserRebate [EndUserRebate]
									  ,UnitDirectInstallLab DILaborCost
									  ,UnitDirectInstallMat DIMaterialCost
									  ,UnitMeaCost1stBaseline UnitMeasureGrossCost
									  ,UnitMeaCost2ndBaseline UnitMeasureGrossCost_ER
									  ,IsNull(MeasInflation,0) MeasInflation
									  ,Null MEBens
									  ,Null MECost
									  ,Sector
									  ,'''' EndUse
									  ,'''' BuildingType
									  ,'''' MeasureGroup
									  ,'''' SolutionCode
									  ,'''' Technology
									  ,'''' Channel
									  ,'''' IsCustom
									  ,'''' Location
									  ,'''' ProgramType
									  ,'''' UnitType
									  ,'''' Comments
									  ,'''' DataField
								  FROM [dbo].[SourceMeasurevw]'



	SET @MappingProgramvw = 'ALTER VIEW [dbo].[MappingProgramvw]
								AS
								SELECT ' + CONVERT(VARCHAR,@jobId) + ' JobID, 
									PA,
									PrgID,
									'''' ProgramName,
									ClaimYearQuarter,
									[AdminCostsOverheadAndGA],
									[AdminCostsOther],
									[MarketingOutreach],
									[DIActivity],
									[DIInstallation],
									[DIHardwareAndMaterials],
									[DIRebateAndInspection],
									[EMV],
									[UserInputIncentive],
									[CostsRecoveredFromOtherSources], 
									[OnBillFinancing]
									FROM [dbo].SourceProgramvw'
END

--**************************************************************************************
-- Script InputMeasurevw View because the calculated field 'Qm' is dependent on First Year.
	SET @InputMeasurevwSql = 'ALTER VIEW [dbo].[InputMeasurevw]
/*--#################################################################################################
-- Name             :  InputMeasurevw
-- Date             :  06/30/2016
-- Author           :  Wayne Hauck
-- Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
-- Purpose          :  This view 1) sets the core variables for cost effectiveness calculations, 2) handles nulls, 3) calculates quarters based on first year of implementation, and 4) calculates calculated fields.
-- Usage            :  n/a
-- Called by        :  n/a
-- Copyright ©      :  Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
-- Change History   :  06/30/2016  Wayne Hauck added comment header*/ with encryption
-- #################################################################################################

		AS

		SELECT ' + Convert(varchar,@jobId) + ' JobID 
		  ,m.CET_ID
		  ,m.PA
		  ,m.PrgID
		  ,ProgramName
		  ,MeasureName
		  ,MeasureID
		  , IsNull(ElecTargetSector,'''') TS
		  , IsNull(ElecEndUseShape,'''') EU
		  ,IsNull(ClimateZone,'''') CZ
		  ,IsNull(GasSector,'''') GS
		  ,IsNull(GasSavingsProfile,'''') GP
		  ,IsNull(ElecRateSchedule,'''') ElecRateSchedule
		  ,IsNull(GasRateSchedule,'''') GasRateSchedule
		  ,' + @AVCVersion + ' AVCVersion
		  ,CombustionType CombType
		  ,m.ClaimYearQuarter Qtr
		  ,(Convert(INT, SUBSTRING(m.ClaimYearQuarter, 1, 4)-' + Convert(varchar,@FirstYear) + ') * 4) + Convert(INT, SUBSTRING(m.ClaimYearQuarter, 6, 1)) AS Qm
		  ,(Convert(INT, SUBSTRING(m.ClaimYearQuarter, 1, 4)-' + Convert(varchar,@FirstYear) + ')) AS Qy
		  ,IsNull(Qty,0) Qty
		  ,IsNull(UESkW,0) kW1 
		  ,IsNull(UESkWh,0) kWh1
		  ,IsNull(UESThm,0) Thm1
		  ,IsNull(UESkW_ER, 0) kW2
		  ,IsNull(UESkWh_ER, 0) kWh2
		  ,IsNull(UESThm_ER, 0) Thm2
		  ,Coalesce(NTGRkW,NTGRkWh,1) NTGRkW
		  ,IsNull(NTGRkWh,1) NTGRkWh
		  ,Coalesce(NTGRThm,NTGRkWh,1) NTGRThm
		  ,Coalesce(NTGRCost,NTGRkWh,1) NTGRCost
		  ,IsNull(IRkWh,1) IR 
		  ,IsNull(IRkW,1) IRkW
		  ,IsNull(IRkWh,1) IRkWh
		  ,IsNull(IRThm,1) IRThm
		  ,IsNull(RRkWh,1) RR
		  ,IsNull(RRkWh,1) RRkWh
		  ,IsNull(RRkW,1) RRkW
		  ,IsNull(RRThm,1) RRThm
		  ,IsNull([IncentiveToOthers],0) IncentiveToOthers
		  ,IsNull([EndUserRebate],0) EndUserRebate
		  ,IsNull(DILaborCost,0) DILaborCost
		  ,IsNull(DIMaterialCost,0)  DIMaterialCost
		  ,IsNull(UnitMeasureGrossCost,0)  UnitMeasureGrossCost
		  ,IsNull(UnitMeasureGrossCost_ER,0) AS UnitMeasureGrossCost_ER
		  --*************************************************************
		  --Calculated fields
		  ,IsNull(EUL,0) * 4 eulq
 		,CASE WHEN IsNull(RUL,0)>=IsNull(EUL,0) THEN IsNull(RUL,0) WHEN IsNull(RUL,0)> 0 THEN RUL ELSE IsNull(EUL,0) END * 4 AS eulq1
		,CASE WHEN IsNull(CASE WHEN RUL>=EUL THEN 0 ELSE RUL END,0) > 0 THEN IsNull(EUL,0) * 4 ELSE 0 END AS eulq2
 		,CASE WHEN IsNull(RUL,0)>=IsNull(EUL,0) THEN IsNull(RUL,0) WHEN IsNull(RUL,0)> 0 THEN RUL ELSE IsNull(EUL,0) END AS eul1
		,CASE WHEN IsNull(CASE WHEN RUL>=EUL THEN 0 ELSE RUL END,0) > 0 THEN IsNull(EUL,0) ELSE 0 END AS eul2
		, IsNull(CASE WHEN RUL>=EUL THEN 0 ELSE RUL END,0) *4  AS rulq
		,CASE WHEN IsNull(RUL,0)>=IsNull(EUL,0) THEN IsNull(RUL,0) ELSE IsNull(EUL,0) END AS EUL
		, IsNull(CASE WHEN RUL>=EUL THEN 0 ELSE RUL END,0)  AS RUL
		,m.PA + ElecTargetSector + ElecEndUseShape + ClimateZone AS ACElecKey
		,m.PA + GasSector + GasSavingsProfile AS ACGasKey
		,IsNull(m.UnitMeasureGrossCost_ER,0) AS MeasIncrCost
		,IsNull(MeasInflation,0) MeasInflation
		,m.MEBens MEBens
		,m.MECost MECost
		,[Sector]
		,[EndUse]
		,[BuildingType]
		,[MeasureGroup]
		,[SolutionCode]
		,[Technology]
		,[Channel]
		,[IsCustom]
		,[Location]
		,[ProgramType]
		,[UnitType]
		,Comments
		,DataField
	  FROM MappingMeasurevw m 
	  '

IF @IncludeNonresourceCosts = 1
BEGIN

SET @InputMeasurevwSql = @InputMeasurevwSql +

'	  UNION
	SELECT 
	   [JobID]
      ,[CET_ID]
      ,[PA]
      ,[PrgID]
      ,[ProgramName]
      ,[MeasureName]
      ,[MeasureID]
      ,[TS]
      ,[EU]
      ,[CZ]
      ,[GS]
      ,[GP]
      ,[ElecRateSchedule]
      ,[GasRateSchedule]
	  ,' + @AVCVersion + ' AVCVersion
      ,[CombType]
      ,[Qtr]
      ,[Qm]
      ,[Qy]
      ,[Qty]
      ,[kW1]
      ,[kWh1]
      ,[Thm1]
      ,[kW2]
      ,[kWh2]
      ,[Thm2]
      ,[NTGRkW]
      ,[NTGRkWh]
      ,[NTGRThm]
      ,[NTGRCost]
      ,[IR]
      ,[IRkW]
      ,[IRkWh]
      ,[IRThm]
      ,[RR]
      ,[RRkWh]
      ,[RRkW]
      ,[RRThm]
      ,[IncentiveToOthers]
      ,[EndUserRebate]
      ,[DILaborCost]
      ,[DIMaterialCost]
      ,[UnitMeasureGrossCost]
      ,[UnitMeasureGrossCost_ER]
      ,[eulq]
      ,[eulq1]
      ,[eulq2]
      ,[eul1]
      ,[eul2]
      ,[rulq]
      ,[EUL]
      ,[RUL]
      ,[ACElecKey]
      ,[ACGasKey]
      ,[MeasIncrCost]
      ,0 [MeasInflation]
      ,[MEBens]
      ,[MECost]
      ,[Sector]
      ,[EndUse]
      ,[BuildingType]
      ,[MeasureGroup]
      ,[SolutionCode]
      ,[Technology]
      ,[Channel]
      ,[IsCustom]
      ,[Location]
      ,[ProgramType]
      ,[UnitType]
      ,[Comments]
      ,[DataField]
  FROM [InputMeasureNonResourcevw] 
  '
 
END

--PRINT 'Mapping Measure Sql:'
--PRINT @MappingMeasurevwSql
--PRINT 'Mapping Program Sql:'
--PRINT @MappingProgramvw
--PRINT 'Input Measure Sql:'
--PRINT @InputMeasurevwSql

BEGIN TRY

	EXEC  sp_executesql @MappingMeasurevwSql
	EXEC  sp_executesql @MappingProgramvw
	EXEC  sp_executesql @InputMeasurevwSql

---------End Mapping Source Data  --------


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
	WHERE [ID] = @jobId
    
    RAISERROR (@ErrorText, 
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );    
END CATCH







GO


