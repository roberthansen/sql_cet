USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[GetMeasureInputsCEDARSAllByJobID]    Script Date: 2019-12-16 1:41:56 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetMeasureInputsCEDARSAllByJobID]
         @JobID INT
AS
BEGIN


DECLARE @SourceType varchar(255)

SET FMTONLY OFF;

SET @SourceType = (SELECT SourceType FROM dbo.CETJobs WHERE ID = @JobID ) 
PRINT 'Source Type = ' + @SourceType

CREATE TABLE [dbo].[#tmp](
	[Row] [bigint] NULL,
	[CEInputID] [nvarchar](255) NOT NULL,
	[IOU_AC_Territory] [nvarchar](255) NULL,
	[PrgID] [nvarchar](255) NULL,
	[ClaimYearQuarter] [nvarchar](6) NULL,
	[MeasDescription] [nvarchar](255) NULL,
	[MeasImpactType] [nvarchar](255) NULL,
	[MeasCode] [nvarchar](255) NULL,
	[MeasureID] [nvarchar](255) NULL,
	[E3TargetSector] [nvarchar](255) NULL,
	[E3MeaElecEndUseShape] [nvarchar](255) NULL,
	[E3ClimateZone] [nvarchar](8) NULL,
	[E3GasSavProfile] [nvarchar](255) NULL,
	[E3GasSector] [nvarchar](255) NULL,
	[RateScheduleElec] [nvarchar](255) NULL,
	[RateScheduleGas] [nvarchar](255) NULL,
	[CombustionType] [nvarchar](255) NULL,
	[NumUnits] [float] NOT NULL,
	[EUL_ID] [nvarchar](255) NULL,
	[EUL_Yrs] [float] NOT NULL,
	[RUL_ID] [nvarchar](255) NULL,
	[RUL_Yrs] [float] NOT NULL,
	[NTG_ID] [nvarchar](255) NULL,
	[NTGRkW] [float] NULL,
	[NTGRkWh] [float] NOT NULL,
	[NTGRTherm] [float] NULL,
	[NTGRCost] [float] NULL,
	[MeasInflation] [float] NULL,
	[MarketeffectsBenefits] [float] NULL,
	[MarketeffectsCosts] [float] NULL,
	[InstallationRatekW] [float] NOT NULL,
	[InstallationRatekWh] [float] NOT NULL,
	[InstallationRateTherm] [float] NOT NULL,
	[RealizationRatekW] [float] NOT NULL,
	[RealizationRatekWh] [float] NOT NULL,
	[RealizationRateTherm] [float] NOT NULL,
	[UnitkW1stBaseline] [float] NOT NULL,
	[UnitkW2ndBaseline] [float] NOT NULL,
	[UnitkWh1stBaseline] [float] NOT NULL,
	[UnitkWh2ndBaseline] [float] NOT NULL,
	[UnitTherm1stBaseline] [float] NOT NULL,
	[UnitTherm2ndBaseline] [float] NOT NULL,
	[UnitMeaCost1stBaseline] [float] NOT NULL,
	[UnitMeaCost2ndBaseline] [float] NOT NULL,
	[UnitDirectInstallLab] [float] NOT NULL,
	[UnitDirectInstallMat] [float] NOT NULL,
	[UnitEndUserRebate] [float] NOT NULL,
	[UnitIncentiveToOthers] [float] NOT NULL,
	[Sector] [nvarchar](255) NULL,
	[UseCategory] [nvarchar](255) NULL,
	[UseSubCategory] [nvarchar](255) NULL,
	[Residential_Flag] [bit] NULL,
	[Upstream_Flag] [bit] NULL,
	[GSIA_ID] [nvarchar](255) NULL,
	[BldgType] [nvarchar](255) NULL,
	[DeliveryType] [nvarchar](255) NULL,
	[MeasAppType] [nvarchar](255) NULL,
	[NormUnit] [nvarchar](255) NULL,
	[PreDesc] [nvarchar](255) NULL,
	[SourceDesc] [nvarchar](255) NULL,
	[StdDesc] [nvarchar](255) NULL,
	[TechGroup] [nvarchar](255) NULL,
	[TechType] [nvarchar](255) NULL,
	[Version] [nvarchar](255) NULL,
	[Comments] [nvarchar](255) NULL
) ON [PRIMARY]



IF @SourceType NOT IN ('CEDARS','CEDARSDatabase')
BEGIN  
INSERT INTO #tmp
SELECT ROW_NUMBER() OVER (ORDER BY ID ASC) AS Row
      ,CET_ID [CEInputID]
      ,[IOU_AC_Territory]
      ,[PrgID]
      ,Qtr [ClaimYearQuarter]
      ,Measurename [MeasDescription]
      ,'' [MeasImpactType]
      ,SolutionCode [MeasCode]
      ,[MeasureID]
      ,TS [E3TargetSector]
      ,EU [E3MeaElecEndUseShape]
      ,CZ [E3ClimateZone]
      ,GP [E3GasSavProfile]
      ,GS [E3GasSector]
      ,null [RateScheduleElec]
      ,null [RateScheduleGas]
      ,null [CombustionType]
      ,Qty [NumUnits]
      ,null [EUL_ID]
      ,EUL [EUL_Yrs]
      ,null [RUL_ID]
      ,RUL [RUL_Yrs]
      ,null [NTG_ID]
      ,[NTGRkW]
      ,[NTGRkWh]
      ,NTGRThm [NTGRTherm]
      ,[NTGRCost]
      ,[MeasInflation]
      ,[MEBens] [MarketeffectsBenefits]
      ,[MECost] [MarketeffectsCosts]
      ,IRkw [InstallationRatekW]
      ,IRkwh [InstallationRatekWh]
      ,IRThm [InstallationRateTherm]
      ,RRkW [RealizationRatekW]
      ,RRkWh [RealizationRatekWh]
      ,RRThm [RealizationRateTherm]
      ,kw1 [UnitkW1stBaseline]
      ,kw2 [UnitkW2ndBaseline]
      ,kwh1 [UnitkWh1stBaseline]
      ,kwh2 [UnitkWh2ndBaseline]
      ,Thm1 [UnitTherm1stBaseline]
      ,Thm2 [UnitTherm2ndBaseline]
      ,[UnitMeasureGrossCost] [UnitMeaCost1stBaseline]
      ,[UnitMeasureGrossCost_ER] [UnitMeaCost2ndBaseline]
      ,[DILaborCost] [UnitDirectInstallLab]
      ,[DIMaterialCost] [UnitDirectInstallMat]
      ,[EndUserRebate] [UnitEndUserRebate]
      ,[IncentiveToOthers] [UnitIncentiveToOthers]
      ,[Sector]
      ,EndUse [UseCategory]
      ,null [UseSubCategory]
      ,0 [Residential_Flag]
      ,0 [Upstream_Flag]
      ,null [GSIA_ID]
      ,[BuildingType] [BldgType]
      ,[Channel] [DeliveryType]
      ,[ProgramType][MeasAppType]
      ,[UnitType] [NormUnit]
      ,null [PreDesc]
      ,null [SourceDesc]
      ,null [StdDesc]
      ,[Technology] [TechGroup]
      ,null [TechType]
      ,null [Version]
      ,[Comments]
  FROM SavedInput 
  WHERE  JobID = @JobID
END

IF @SourceType = 'CEDARS' OR @SourceType = 'CEDARSDatabase'
BEGIN
PRINT 'SELECTING FROM CEDARS'

INSERT INTO #tmp
SELECT ROW_NUMBER() OVER (ORDER BY ID ASC) AS Row
      ,[CEInputID]
      ,[IOU_AC_Territory]
      ,[PrgID]
      ,[ClaimYearQuarter]
      ,[MeasDescription]
      ,[MeasImpactType]
      ,[MeasCode]
      ,[MeasureID]
      ,[E3TargetSector]
      ,[E3MeaElecEndUseShape]
      ,[E3ClimateZone]
      ,[E3GasSavProfile]
      ,[E3GasSector]
      ,[RateScheduleElec]
      ,[RateScheduleGas]
      ,[CombustionType]
      ,[NumUnits]
      ,[EUL_ID]
      ,[EUL_Yrs]
      ,[RUL_ID]
      ,[RUL_Yrs]
      ,[NTG_ID]
      ,[NTGRkW]
      ,[NTGRkWh]
      ,[NTGRTherm]
      ,[NTGRCost]
      ,[MeasInflation]
      ,[MarketeffectsBenefits]
      ,[MarketeffectsCosts]
      ,[InstallationRatekW]
      ,[InstallationRatekWh]
      ,[InstallationRateTherm]
      ,[RealizationRatekW]
      ,[RealizationRatekWh]
      ,[RealizationRateTherm]
      ,[UnitkW1stBaseline]
      ,[UnitkW2ndBaseline]
      ,[UnitkWh1stBaseline]
      ,[UnitkWh2ndBaseline]
      ,[UnitTherm1stBaseline]
      ,[UnitTherm2ndBaseline]
      ,[UnitMeaCost1stBaseline]
      ,[UnitMeaCost2ndBaseline]
      ,[UnitDirectInstallLab]
      ,[UnitDirectInstallMat]
      ,[UnitEndUserRebate]
      ,[UnitIncentiveToOthers]
      ,[Sector]
      ,[UseCategory]
      ,[UseSubCategory]
      ,[Residential_Flag]
      ,[Upstream_Flag]
      ,[GSIA_ID]
      ,[BldgType]
      ,[DeliveryType]
      ,[MeasAppType]
      ,[NormUnit]
      ,[PreDesc]
      ,[SourceDesc]
      ,[StdDesc]
      ,[TechGroup]
      ,[TechType]
      ,[Version]
      ,[Comments]
  FROM SavedInputCEDARS 
  WHERE  JobID = @JobID
END

SELECT 
	   [Row]
      ,[CEInputID]
      ,[IOU_AC_Territory]
      ,[PrgID]
      ,[ClaimYearQuarter]
      ,[MeasDescription]
      ,[MeasImpactType]
      ,[MeasCode]
      ,[MeasureID]
      ,[E3TargetSector]
      ,[E3MeaElecEndUseShape]
      ,[E3ClimateZone]
      ,[E3GasSavProfile]
      ,[E3GasSector]
      ,[RateScheduleElec]
      ,[RateScheduleGas]
      ,[CombustionType]
      ,[NumUnits]
      ,[EUL_ID]
      ,[EUL_Yrs]
      ,[RUL_ID]
      ,[RUL_Yrs]
      ,[NTG_ID]
      ,[NTGRkW]
      ,[NTGRkWh]
      ,[NTGRTherm]
      ,[NTGRCost]
      ,[MeasInflation]
      ,[MarketeffectsBenefits]
      ,[MarketeffectsCosts]
      ,[InstallationRatekW]
      ,[InstallationRatekWh]
      ,[InstallationRateTherm]
      ,[RealizationRatekW]
      ,[RealizationRatekWh]
      ,[RealizationRateTherm]
      ,[UnitkW1stBaseline]
      ,[UnitkW2ndBaseline]
      ,[UnitkWh1stBaseline]
      ,[UnitkWh2ndBaseline]
      ,[UnitTherm1stBaseline]
      ,[UnitTherm2ndBaseline]
      ,[UnitMeaCost1stBaseline]
      ,[UnitMeaCost2ndBaseline]
      ,[UnitDirectInstallLab]
      ,[UnitDirectInstallMat]
      ,[UnitEndUserRebate]
      ,[UnitIncentiveToOthers]
      ,[Sector]
      ,[UseCategory]
      ,[UseSubCategory]
      ,[Residential_Flag]
      ,[Upstream_Flag]
      ,[GSIA_ID]
      ,[BldgType]
      ,[DeliveryType]
      ,[MeasAppType]
      ,[NormUnit]
      ,[PreDesc]
      ,[SourceDesc]
      ,[StdDesc]
      ,[TechGroup]
      ,[TechType]
      ,[Version]
      ,[Comments]
  FROM #tmp


END

















GO


