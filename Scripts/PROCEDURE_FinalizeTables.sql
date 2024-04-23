/*
################################################################################
Name             :  FinalizeTables
Date             :  2016-06-30
Author           :  Wayne Hauck
Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose          :  This stored procedure validates input, runs CalcAll sproc,
                 :  and saves the results.
Usage            :  n/a
Called by        :  n/a
Copyright        :  Developed by Pinnacle Consulting Group (aka Intech Energy,
                 :  Inc.) for California Public Utilities Commission (CPUC), All
                 :  Rights Reserved
Change History   :  2016-06-30  Wayne Hauck added comment header
                 :  2016-12-30  Wayne Hauck added  @AVCVersion and @FirstYear
                 :              parameters to ValidateInput sp, which are needed
                 :              to validate EUL > years in avoided cost tables.
################################################################################
*/
USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[FinalizeTables]    Script Date: 2019-12-16 1:23:17 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[FinalizeTables]
@JobID INT = -1,
@MEBens FLOAT=NULL,
@MECost FLOAT=NULL,
@CETDataDbName NVARCHAR(255) = '',
@ValidateRun BIT = 1,
@AVCVersion VARCHAR(255),
@FirstYear INT,
@SourceType VARCHAR(255) = ''

AS

SET NOCOUNT ON

DECLARE @Rows int;
DECLARE @ValidatedRows int;
DECLARE @SQL nvarchar(max);
DECLARE @RetValOut int;
DECLARE @ParmDef nvarchar(500);
DECLARE @Status varchar(255);
DECLARE @StartTime DateTime;
DECLARE @FinishTime DateTime;
DECLARE @Secs int;
DECLARE @Duration varchar(12);
DECLARE @return_value int;
DECLARE @StatusDetail nvarchar(255)

------Set Start Time-----
SET @StartTime = GetDate()


-- Validate Input -- Note: if @ValidateRun is 0 validation will not be done
IF @ValidateRun = 1 
    BEGIN
        delete from InputValidation
        delete from SavedValidation WHERE JobID = @JobID
        EXEC ValidateInput @JobID, @AVCVersion, @FirstYear
    END
-- END Validate Input -----


-- Get number of rows to be processed
SET @SQL = N'SELECT @RetValOut = Count(*) FROM [InputMeasurevw]'
SET @ParmDef = N'@RetValOUT int OUTPUT';
EXEC sp_executesql @SQL, @ParmDef, @RetValOut = @Rows OUTPUT;


--*************************************************************
----Start Execute Main Calc-----
EXEC    @return_value = [dbo].[CalcAll] @JobID, @MEBens, @MECost, @AVCVersion, @FirstYear

----End Execute Calc-----
--*************************************************************

-- Validate Output
IF @ValidateRun = 1 -- if @ValidateRun is 0 validation will not be done
    BEGIN
        exec ValidateOutput @JobID
    END

-- Save CE
exec SaveCE @JobID, @CETDataDbName

-- Save Savings
exec SaveSavings @JobID, @CETDataDbName

-- Save Emissions
exec SaveEmissions @JobID, @CETDataDbName

-- Save CE
exec SaveCost @JobID, @CETDataDbName

-- Save Input Measure and Program levels
IF @SourceType = 'CEDARS' OR @SourceType = 'CEDARSDatabase' OR @SourceType = 'CEDARSExcel'
    BEGIN
        PRINT 'Saving CEDARS format'
        exec SaveInputCEDARS @JobID, @MEBens, @MECost, @CETDataDbName
        EXEC SaveProgramCostCEDARS @JobID, @CETDataDbName
    END
ELSE
    BEGIN
        PRINT 'Saving CET format'
        exec SaveInput @JobID, @MEBens, @MECost, @CETDataDbName
        EXEC SaveProgramCost @JobID, @CETDataDbName
    END

-- Save Validation
IF @ValidateRun = 1  -- if @ValidateRun is 0 validation will not be done
    BEGIN
        exec SaveValidation @JobID, @CETDataDbName
    END

-- Get number of validated rows 
SET @SQL = N'SELECT @RetValOut = Count(*) FROM [InputValidation]'
EXEC sp_executesql @SQL, @ParmDef, @RetValOut = @ValidatedRows OUTPUT;


------Set Finish Time and Duration -----
SET @FinishTime = GETDATE()
SET @Secs = DATEDIFF(SECOND,@StartTime,@FinishTime)
SET @Duration = CASE WHEN @Secs >= 3600 THEN 
    CONVERT(VARCHAR(5), @Secs/60/60) + ':' ELSE '' END
  + RIGHT('0' + CONVERT(VARCHAR(2), @Secs/60%60), 2)
  + ':' + RIGHT('0' + CONVERT(VARCHAR(2), @Secs % 60), 2)
------End Time and Duration -----


-- Post processing and status update ---
IF @return_value = 0 
    IF @ValidatedRows =0
        SET @Status = 'Completed'
    ELSE
        SET @Status = 'Completed with Warnings'
ELSE
    SET @Status = 'Failed' 
-- Post processing and status update ---


-- ****** Update Jobs table with Job Status messages  ******
SET @StatusDetail = CONVERT(NVARCHAR(255),@Rows) + ' records processed with ' + CONVERT(NVARCHAR(255),@ValidatedRows) + ' validation messages.'

SET @SQL = N'UPDATE j SET [Rows] = ' + CONVERT(VARCHAR,@Rows) +', [Started] = ''' + CONVERT(VARCHAR,@StartTime) + ''',[Finished]=''' + CONVERT(VARCHAR,@FinishTime) +''', Duration = ''' + CONVERT(VARCHAR,@Duration) + ''', [Status]=''' + CONVERT(VARCHAR,@Status) + ''', StatusDetail=''' + @StatusDetail + ''', CETDataDbName=''' + CASE WHEN @CETDataDbName='' THEN DB_NAME() ELSE @CETDataDbName END
 +''' FROM ' + @CETDataDbName + '.dbo.CETJobs j  
WHERE ID = ' + CONVERT(VARCHAR,@JobID)

EXEC sp_executesql @SQL
PRINT CONVERT(VARCHAR,@Rows) +' Rows processed, Started = ''' + CONVERT(VARCHAR,@StartTime) + ''',Finished=''' + CONVERT(VARCHAR,@FinishTime) +''', Duration = ''' + CONVERT(VARCHAR,@Duration) + ''', Status=''' + CONVERT(VARCHAR,@Status) + ''', StatusDetail=''' + @StatusDetail
-- ***********************



SELECT  'ReturnValue' = @return_value 

--Defrag output and saved tables. This is required to keep indexes from getting defragmented, which can results in jobs hanging.
EXEC DefragSavedTables @CETDataDbName





GO


