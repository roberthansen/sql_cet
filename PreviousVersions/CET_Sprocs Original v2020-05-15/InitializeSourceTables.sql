USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[InitializeSourceTables]    Script Date: 2019-12-16 1:56:00 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/*
################################################################################
Name             :  InitializeSourceTables
Date             :  2016-06-30
Author           :  Wayne Hauck
Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose          :  This stored procedure initializes tables which prepares
				 :  views for running cost effectiveness.
Usage            :  n/a
Called by        :  n/a
Copyright        :  Developed by Pinnacle Consulting Group (aka InTech Energy,
				 :	Inc.) for California Public Utilities Commission (CPUC).
				 :  All Rights Reserved.
Change History   :  2016-06-30  Wayne Hauck added comment header
                 :  2016-09-01  Wayne Hauck modified to allow source database to
				 :              be passed and processed correctly 
                 :  2017-07-01  Wayne Hauck modified to pass  avoided cost
				 :              version to when Settingsvw view is created 
                 :  2025-05-21  Robert Hansen incorporated new societal discount
				 :              rates into Settingsvw definition
################################################################################
*/



CREATE PROCEDURE [dbo].[InitializeSourceTables]
@jobId INT,
@SourceType NVARCHAR(25),
@SourceDatabase NVARCHAR(255),
@MeasureTable NVARCHAR(255),
@ProgramTable NVARCHAR(255),
@FirstYear INT=2013,
@AVCVersion NVARCHAR(255),
@IncludeNonresourceCosts BIT = 0

AS

SET NOCOUNT ON

DECLARE @SourceMeasurevwSql NVARCHAR(MAX);
DECLARE @SourceProgramvwSql NVARCHAR(MAX);
DECLARE @MappingMeasurevwSql NVARCHAR(MAX);
DECLARE @SettingsvwSql NVARCHAR(MAX);
DECLARE @InputMeasurevwSql NVARCHAR(MAX);

---------Start Mapping Source Data  --------
BEGIN

PRINT 'Source Type = ' + @SourceType

SET @SourceMeasurevwSql = 'ALTER VIEW [dbo].[SourceMeasurevw] AS 

--#################################################################################################
-- Name             :  SourceMeasurevw
-- Date             :  2016-06-30
-- Author           :  Wayne Hauck
-- Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
-- Purpose          :  This view is a pointer to the source measure table and is code generated in the InitializeTables sproc. It does not care about fieldnames or formats. Only the location of the source table.
-- Usage            :  n/a
-- Called by        :  n/a
-- Copyright �      :  Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
-- Change History   :  2016-06-30  Wayne Hauck added comment header
--                     
--#################################################################################################

							SELECT * FROM ' + @SourceDatabase + '.dbo.' +  @MeasureTable

SET @SourceProgramvwSql = 'ALTER VIEW [dbo].[SourceProgramvw] AS 

--#################################################################################################
-- Name             :  SourceProgramvw
-- Date             :  2016-06-30
-- Author           :  Wayne Hauck
-- Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
-- Purpose          :  This view is a pointer to the source program table and is code generated in the InitializeTables sproc. It does not care about fieldnames or formats. Only the location of the source table.
-- Usage            :  n/a
-- Called by        :  n/a
-- Copyright �      :  Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
-- Change History   :  2016-06-30  Wayne Hauck added comment header
--                     
--#################################################################################################

							SELECT * FROM ' + @SourceDatabase + '.dbo.' + @ProgramTable


SET @SettingsvwSql = 'ALTER VIEW [dbo].[Settingsvw]  

/*--#################################################################################################
-- Name             :  Settingsvw
-- Purpose          :  This view is E3Settings table.
-- Date             :  2016-06-30
-- Author           :  Wayne Hauck
-- Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
-- Usage            :  n/a
-- Called by        :  n/a
-- Copyright        :  Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
-- Change History   :  2016-06-30  Wayne Hauck added comment header
--                  :  2017-07-01  Modified to settings based on avoided cost version by Wayne Hauck*/ with encryption
--                  :  2025-05-21  Robert Hansen incorporated new societal discount rate fields
----######################################################################################################################

		AS
 		
		SELECT    [Version]
		, PA -- Program administrator
		, DiscountRateAnnual AS Ra
		, DiscountRateAnnual+1 AS Raf
		, DiscountRateQtr AS Rq
		, DiscountRateQtr+1 AS Rqf
		, SocietalDiscountRateAnnual AS Ra_SCT
		, SocietalDiscountRateAnnual+1 AS Raf_SCT
		, SocietalDiscountRateQtr AS Rq_SCT
		, SocietalDiscountRateQtr+1 AS Rqf_SCT
		, BaseYear
		, CO2Gas
		, NOxGas
		FROM dbo.E3Settings WHERE [Version] = ''' + @AVCVersion + ''''


--**************************************************************************************
-- Script InputMeasurevw View because the calculated field 'Qm' is dependent on First Year.
	SET @InputMeasurevwSql = 'ALTER VIEW [dbo].[InputMeasurevw]
/*--#################################################################################################
-- Name             :  InputMeasurevw
-- Date             :  2016-06-30
-- Author           :  Wayne Hauck
-- Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
-- Purpose          :  This view 1) sets the core variables for cost effectiveness calculations, 2) handles nulls, 3) calculates quarters based on first year of implementation, and 4) calculates calculated fields.
-- Usage            :  n/a
-- Called by        :  n/a
-- Copyright        :  Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
-- Change History   :  2016-06-30  Wayne Hauck added comment header*/
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

--PRINT 'Source Measure Sql:'
--PRINT @SourceMeasurevwSql
--PRINT 'Source Program Sql:'
--PRINT @SourceProgramvwSql

BEGIN TRY

    EXEC  sp_executesql @SourceMeasurevwSql
	EXEC  sp_executesql @SourceProgramvwSql
	EXEC  sp_executesql @SettingsvwSql
	EXEC  sp_executesql @InputMeasurevwSql

---------End Mapping Source Data  --------


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


END











GO


