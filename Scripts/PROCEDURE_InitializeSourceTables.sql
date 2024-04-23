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
                 :  Inc.) for California Public Utilities Commission (CPUC).
				 :  All Rights Reserved.
Change History   :  2016-06-30  Wayne Hauck added comment header
                 :  2016-09-01  Wayne Hauck modified to allow source database
                 :              to be passed and processed correctly
                 :  2017-07-01  Wayne Hauck modified to pass  avoided cost
                 :              version to when Settingsvw view is created
                 :  2021-06-22  Robert Hansen removed ALTER InputMeasurevw block
				 :              from procedure
                 :  2022-09-02  Robert Hansen added the following new fields related to
                 :              water-energy nexus savings:
                 :                + UnitGalWater1stBaseline
                 :                + UnitGalWater2ndBaseline
                 :                + UnitkWhIOUWater1stBaseline
                 :                + UnitkWhIOUWater2ndBaseline
                 :                + UnitkWhTotalWater1stBaseline
                 :                + UnitkWhTotalWater2ndBaseline
                 :  2024-04-23  Robert Hansen renamed the "PA" field to
                 :              "IOU_AC_Territory"
################################################################################
*/

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('dbo.InitializeSourceTables'))
   exec('CREATE PROCEDURE [dbo].[InitializeSourceTables] AS BEGIN SET NOCOUNT ON; END')
GO

ALTER PROCEDURE [dbo].[InitializeSourceTables]
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
DECLARE @SettingsvwSql NVARCHAR(MAX);

---------Start Mapping Source Data  --------
BEGIN

PRINT 'Source Type = ' + @SourceType

SET @SourceMeasurevwSql = 'ALTER VIEW [dbo].[SourceMeasurevw] AS 
/*
################################################################################
Name : SourceMeasurevw
Date : 2016-06-30
Author : Wayne Hauck
Company : Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose : This view is a pointer to the source measure table and is code generated in the InitializeTables sproc. It does not care about fieldnames or formats. Only the location of the source table.
Usage : n/a
Called by : n/a
Copyright : Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
Change History : 2016-06-30  Wayne Hauck added comment header        
################################################################################
*/
SELECT * FROM ' + @SourceDatabase + '.dbo.' +  @MeasureTable

SET @SourceProgramvwSql = 'ALTER VIEW [dbo].[SourceProgramvw] AS 
/*
################################################################################
Name : SourceProgramvw
Date : 2016-06-30
Author : Wayne Hauck
Company : Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose : This view is a pointer to the source program table and is code generated in the InitializeTables sproc. It does not care about fieldnames or formats. Only the location of the source table.
Usage : n/a
Called by : n/a
Copyright : Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
Change History : 2016-06-30  Wayne Hauck added comment header
################################################################################
*/
SELECT * FROM ' + @SourceDatabase + '.dbo.' + @ProgramTable


SET @SettingsvwSql = 'ALTER VIEW [dbo].[Settingsvw] AS
/*
################################################################################
Name : Settingsvw
Purpose : This view is E3Settings table.
Date : 2016-06-30
Author : Wayne Hauck
Company : Pinnacle Consulting Group (aka Intech Energy, Inc.)
Usage : n/a
Called by : n/a
Copyright : Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
Change History : 2016-06-30  Wayne Hauck added comment header
               : 2017-07-01  Modified to settings based on avoided cost version by Wayne Hauck with encryption
               : 2024-04-23  Robert Hansen renamed the "PA" to "IOU_AC_Territory"
################################################################################
*/
SELECT
[Version]
,IOU_AC_Territory
,DiscountRateAnnual Ra
,DiscountRateAnnual+1 Raf
,DiscountRateQtr Rq
,DiscountRateQtr+1 Rqf
,BaseYear
,CO2Gas
,NOxGas
FROM dbo.E3Settings WHERE [Version] = ''' + @AVCVersion + ''''

BEGIN TRY
    EXEC  sp_executesql @SourceMeasurevwSql
	EXEC  sp_executesql @SourceProgramvwSql
	EXEC  sp_executesql @SettingsvwSql
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
               @ErrorSeverity,
               @ErrorState
               );    
END CATCH

END

GO


