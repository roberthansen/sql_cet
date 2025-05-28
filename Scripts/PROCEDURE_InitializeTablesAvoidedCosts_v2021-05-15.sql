USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[InitializeTablesAvoidedCosts]    Script Date: 2019-12-16 1:57:45 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/*
################################################################################
Name             :  InitializeTablesAvoidedCosts
Date             :  2016-06-30
Author           :  Wayne Hauck
Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose          :  This stored procedure initializes the avoided costs, emissions, and RIM rate tables.
Usage            :  n/a
Called by        :  n/a
Copyright        :  Developed by Pinnacle Consulting Group (aka InTech Energy, Inc.) for California Public Utilities Commission (CPUC). All Rights Reserved.
Change History   :  2016-06-30  Wayne Hauck added comment header
                 :  2024-04-23  Robert Hansen renamed "PA" field to
				 :  			"IOU_AC_Territory"
                 :  2024-06-20  Robert Hansen reverted "IOU_AC_Territory" to
				 :				"PA"
				 :  2025-05-21  Robert Hansen added fields for the Societal Cost
				 :              Test: Gen_SB, Gen_SH, TD_SB, TD_SH, Cost_SB, and
				 :				Cost_SH
################################################################################
*/

CREATE PROCEDURE [dbo].[InitializeTablesAvoidedCosts]
@JobID INT=-1,
@AvoidedCostElecTable  NVARCHAR(255),
@AvoidedCostGasTable  NVARCHAR(255),
@BaseYear INT=2013,
@FirstYear INT=2013,
@AVCVersion NVARCHAR(255)

AS

SET NOCOUNT ON

DECLARE @AvoidedCostSourceElecvwSql NVARCHAR(MAX);
DECLARE @AvoidedCostSourceGasvwSql NVARCHAR(MAX);
DECLARE @E3RateScheduleSourceElecvwSql NVARCHAR(MAX);
DECLARE @E3RateScheduleSourceGasvwSql NVARCHAR(MAX);
DECLARE @E3EmissionsSourcevwSql NVARCHAR(MAX);
DECLARE @MaxElecQac int;
DECLARE @MaxGasQac int;
DECLARE @Qtrs int;

---------Start   --------

SET @Qtrs = CASE WHEN @FirstYear - @BaseYear >= 0 THEN (@FirstYear - @BaseYear) * 4 ELSE 0 END

SET @AvoidedCostSourceElecvwSql = 'ALTER VIEW [dbo].[AvoidedCostSourceElecvw]  
/*#################################################################################################
-- Name             :  AvoidedCostSourceElecvw
-- Date             :  2016-06-30
-- Author           :  Wayne Hauck
-- Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
-- Purpose          :  This view is the source of avoided costs used by the cost effectiveness calculations. If First Year is base year then it is just the avoided cost table. If first year is greater than base year, then avoided costs are adjusted to account for year shift.
-- Usage            :  n/a
-- Called by        :  n/a
-- Copyright �      :  Developed by Pinnacle Consulting Group (aka InTech Energy, Inc.) for California Public Utilities Commission (CPUC). All Rights Reserved.
-- Change History   :  2016-06-30  Wayne Hauck added comment header*/with encryption
--#################################################################################################

	AS
	
	SELECT * FROM ' + @AvoidedCostElecTable


--#################################################################################################
SET @AvoidedCostSourceGasvwSql = 'ALTER VIEW [dbo].[AvoidedCostSourceGasvw] 
/*#################################################################################################
-- Name             :  AvoidedCostSourceGasvw
-- Date             :  2016-06-30
-- Author           :  Wayne Hauck
-- Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
-- Purpose          :  This view is the source of avoided costs used by the cost effectiveness calculations. If First Year is base year then it is just the avoided cost table. If first year is greater than base year, then avoided costs are adjusted to account for year shift.
-- Usage            :  n/a
-- Called by        :  n/a
-- Copyright �      :  Developed by Pinnacle Consulting Group (aka InTech Energy, Inc.) for California Public Utilities Commission (CPUC). All Rights Reserved.
-- Change History   :  2016-06-30  Wayne Hauck added comment header*/with encryption
--#################################################################################################

	AS

	SELECT * FROM ' + @AvoidedCostGasTable


EXEC  sp_executesql @AvoidedCostSourceElecvwSql
EXEC  sp_executesql @AvoidedCostSourceGasvwSql

PRINT 'Count=' + Convert(nvarchar,@MaxElecQac)
PRINT 'Count=' + Convert(nvarchar,@MaxGasQac)

--#################################################################################################
IF @Qtrs > 0 
	BEGIN
		SET @MaxElecQac = (SELECT Max(Qac) FROM dbo.AvoidedCostSourceElecvw)
		SET @MaxGasQac = (SELECT Max(Qac) FROM dbo.AvoidedCostSourceGasvw)

    	SET @AvoidedCostSourceElecvwSql = 'ALTER VIEW [dbo].[AvoidedCostSourceElecvw] 
/* #################################################################################################
-- Name             :  AvoidedCostSourceElecvw
-- Date             :  2016-06-30
-- Author           :  Wayne Hauck
-- Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
-- Purpose          :  This view is the source of avoided costs used by the cost effectiveness calculations. If First Year is base year then it is just the avoided cost table. If first year is greater than base year, then avoided costs are adjusted to account for year shift.
-- Usage            :  n/a
-- Called by        :  n/a
-- Copyright �      :  Developed by Pinnacle Consulting Group (aka InTech Energy, Inc.) for California Public Utilities Commission (CPUC). All Rights Reserved.
-- Change History   :  2016-06-30  Wayne Hauck added comment header*/ with encryption
-- #################################################################################################
			
		AS 
				
		SELECT [PA]
			  ,[Version]
			  ,[TS]
			  ,[EU]
			  ,[CZ]
			  ,[Qtr]
			  ,[Qac]-' + Convert(nvarchar,@Qtrs)  + ' Qac
			  ,[Gen]
			  ,[TD]
			  ,[DSType]
			  ,[ACElecKey]
		  FROM [dbo].[' + @AvoidedCostElecTable + ']
		  WHERE Qac > ' + Convert(nvarchar,@Qtrs-1) + '
		UNION
		SELECT [PA]
			  ,[Version]
			  ,[TS]
			  ,[EU]
			  ,[CZ]
			  ,[Qtr]
			  ,[Qac]
			  ,[Gen]
			  ,[TD]
			  ,[DSType]
			  ,[ACElecKey]
		  FROM [dbo].[' + @AvoidedCostElecTable + ']
		  WHERE Qac > '  + Convert(nvarchar,@MaxElecQac - @Qtrs)

	SET @AvoidedCostSourceGasvwSql = 'ALTER VIEW [dbo].[AvoidedCostSourceGasvw]  
/* #################################################################################################
-- Name             :  AvoidedCostSourceGasvw
-- Date             :  2016-06-30
-- Author           :  Wayne Hauck
-- Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
-- Purpose          :  This view is the source of avoided costs used by the cost effectiveness calculations. If First Year is base year then it is just the avoided cost table. If first year is greater than base year, then avoided costs are adjusted to account for year shift.
-- Usage            :  n/a
-- Called by        :  n/a
-- Copyright �      :  Developed by Pinnacle Consulting Group (aka InTech Energy, Inc.) for California Public Utilities Commission (CPUC). All Rights Reserved.
-- Change History   :  2016-06-30  Wayne Hauck added comment header*/ with encryption
-- #################################################################################################

		AS

	    SELECT
		   [ID]
		  ,[PA]
		  ,[Version]
		  ,[FirstYear]
		  ,[GS]
		  ,[GP]
		  ,[ComboField]
		  ,[Qtr]
			  ,[Qac]-' + CONVERT(NVARCHAR,@Qtrs)  + ' Qac
		  ,[Commodity]
		  ,[TD]
		  ,[Total]
		  ,[ACGasKey]
	    FROM [dbo].[' + @AvoidedCostGasTable + ']
		WHERE Qac > ' + CONVERT(NVARCHAR,@Qtrs-1) + '
	UNION
	    SELECT
		   [ID]
		  ,[PA]
		  ,[Version]
		  ,[FirstYear]
		  ,[GS]
		  ,[GP]
		  ,[ComboField]
		  ,[Qtr]
		  ,[Qac]
		  ,[Commodity]
		  ,[TD]
		  ,[Total]
		  ,[ACGasKey]
	    FROM [dbo].[' + @AvoidedCostGasTable + ']
 	    WHERE Qac > '  + CONVERT(NVARCHAR,@MaxGasQac - @Qtrs) 

	END

SET @E3RateScheduleSourceElecvwSql = 'ALTER VIEW [dbo].[E3RateScheduleSourceElecvw] AS SELECT * FROM E3RateScheduleElec WHERE Version = ' + @AVCVersion
SET @E3RateScheduleSourceGasvwSql = 'ALTER VIEW [dbo].[E3RateScheduleSourceGasvw] AS SELECT * FROM E3RateScheduleGas WHERE Version = ' + @AVCVersion

IF @AVCVersion = '2013'
	BEGIN
		SET @E3EmissionsSourcevwSql = 'ALTER VIEW [dbo].[E3EmissionsSourcevw] AS SELECT * FROM E3Emissions2013 WHERE Version = ' + @AVCVersion
	END
ELSE
	BEGIN
		SET @E3EmissionsSourcevwSql = 
'
ALTER VIEW [dbo].[E3EmissionsSourcevw] AS 

SELECT co.[PA]
      ,co.[Version]
      ,co.[TS]
      ,co.[EU]
      ,co.[CZ]
      ,co.[Qtr]
      ,co.[Qac]
      ,co.[Gen]
      ,co.[TD]
      ,co.[CO2]
      ,co.[DSType]
      ,co.[ACElecKey]
	  ,em.NOx
	  ,em.PM10
  FROM [dbo].' + @AvoidedCostElecTable + ' co
  LEFT JOIN [dbo].E3Emissions em on co.PA = em.PA  and co.[Version] = em.[Version] and co.TS = em.TS and co.EU = em.EU and co.CZ = em.CZ
  AND co.Version = ''' + @AVCVersion + ''''

	END

--PRINT 'Avoided cost Elec SQL'
--PRINT @AvoidedCostSourceElecvwSql
--PRINT 'Avoided cost Gas SQL'
--PRINT @AvoidedCostSourceGasvwSql

-- Execute SQLs
BEGIN TRY
	EXEC  sp_executesql @AvoidedCostSourceElecvwSql
	EXEC  sp_executesql @AvoidedCostSourceGasvwSql
	EXEC  sp_executesql @E3RateScheduleSourceElecvwSql
	EXEC  sp_executesql @E3RateScheduleSourceGasvwSql
	EXEC  sp_executesql @E3EmissionsSourcevwSql
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
		Update [dbo].[CETJobs]
	SET [StatusDetail] =  @ErrorProcedure + ': ' + @ErrorMessage
	WHERE [ID] = @jobId
    
    RAISERROR (@ErrorText, 
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );    
END CATCH

GO