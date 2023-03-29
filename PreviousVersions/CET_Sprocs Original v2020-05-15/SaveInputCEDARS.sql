USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[SaveInputCEDARS]    Script Date: 12/16/2019 2:07:10 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO














--#################################################################################################

-- Name             :  SaveInput

-- Date             :  06/30/2016

-- Author           :  Wayne Hauck

-- Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)

-- Purpose          :  This stored procedure saves inputs by JobID into the SavedInputs table.

-- Usage            :  n/a

-- Called by        :  n/a

-- Copyright ©      :  Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved

-- Change History   :  06/30/2016  Wayne Hauck added comment header

--                     

--#################################################################################################







CREATE PROCEDURE [dbo].[SaveInputCEDARS]

@JobID INT = -1,

@MEBens FLOAT,

@MECost FLOAT,

@CETDataDbName VARCHAR(255)=''



AS

SET NOCOUNT ON



DECLARE @SQL1 nvarchar(max)

DECLARE @SQL2 nvarchar(max)



-- Clear SavedKeys table for Job

SET @SQL1 = 'DELETE FROM SavedInputCEDARS WHERE JobID=' + Convert(nvarchar,@JobID)

EXEC  sp_executesql @SQL1



IF @MEBens Is Null

	BEGIN

		SET @MEBens = IsNull((SELECT MarketEffectBens from CETJobs WHERE ID = @JobID),0)

	END 

IF @MECost Is Null

	BEGIN

		SET @MECost = IsNull((SELECT MarketEffectCost from CETJobs WHERE ID = @JobID),0)

	END 

IF @CETDataDbName =''

	BEGIN

		SET @CETDataDbName = 'dbo.'

	END 

ELSE

	BEGIN

		SET @CETDataDbName = @CETDataDbName + '.dbo.'

	END 



--************** Start Input  ***************

SET @SQL2 = 

'INSERT INTO ' + @CETDataDbName + 'SavedInputCEDARS

(

       [JobID]

      ,[CEInputID]

      ,[PA]

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

	  ,RateScheduleElec

      ,RateScheduleGas

	  ,CombustionType

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

	  ,MeasInflation

	  ,MarketEffectsBenefits

	  ,MarketEffectsCosts

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

)

SELECT ' + CONVERT(NVARCHAR,@JobID) + ' AS JobID

      ,[CEInputID]

      ,[PA]

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

	  ,RateScheduleElec

      ,RateScheduleGas

	  ,CombustionType

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

	  ,MeasInflation

	  ,MarketEffectsBenefits

	  ,MarketEffectsCosts

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

  FROM [dbo].[SourceMeasurevw]'





EXEC  sp_executesql @SQL2











GO


