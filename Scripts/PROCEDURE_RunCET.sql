/*
################################################################################
Name             :  RunCET
Date             :  06/30/2016
Author           :  Wayne Hauck
Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose          :  This is the main entry point to run cost effectivensss both
				 :  from the Desktop and in the database. It creates the job,
				 :  and calls the InitializeTables and FinalizeTables sproc.
Usage            :  n/a
Called by        :  n/a
Copyright        :  Developed by Pinnacle Consulting Group (aka InTech Energy,
				 :  Inc.) for California Public Utilities Commission (CPUC). All
				 :  Rights Reserved.
Change History   :  06/30/2016  Wayne Hauck added comment header
################################################################################
*/
USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[RunCET]    Script Date: 12/16/2019 2:00:15 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[RunCET]
@MeasureTable VARCHAR(255)='EDFilled',
@ProgramTable VARCHAR(255)='ProgramCost',
@MEBens FLOAT=0.0,
@MECost FLOAT=0.0,
@Description NVARCHAR(255) = '',
@CETSourceDbName NVARCHAR(255) = '',
@CETDataDbName NVARCHAR(255) = '',
@SourceType NVARCHAR(25) = 'CETDatabase',
@FilePath NVARCHAR(500) = '',
@User NVARCHAR(255) = '',
@AVCDbName NVARCHAR(255) = '',
@AVCVersion NVARCHAR(255) = '',
@FirstYear INT = -1, -- Flag. Note: important: -1 indicates no parameter was passed used in later code. Do Not revise null option.
@IncludeNonresourceCosts BIT = 0

AS

--SET FMTONLY OFF
SET NOCOUNT ON;

DECLARE @JobID int
DECLARE @MTableName varchar(255)
DECLARE @PTableName varchar(255)
DECLARE @Rows int
DECLARE @SQL nvarchar(max)
DECLARE @Host nvarchar(255)
DECLARE @CETCoreDbName nvarchar(255)
DECLARE @Version nvarchar(255) 
DECLARE @VersionSource nvarchar(255) 
DECLARE @VersionCore nvarchar(255) 
DECLARE @VersionData nvarchar(255) 
DECLARE @BaseYear int
DECLARE @AVCElecTable nvarchar(255)
DECLARE @AVCGasTable nvarchar(255)
DECLARE @ValidateRun int
DECLARE @ValResult int

Print '*********************'
Print 'Starting RunCET at ' + Convert(varchar,GetDate())


-- *****Validate CET Input  **********
Print 'Validating CET Input for SourceType, AVCVersion, and FirstYear'
EXEC @ValResult = ValidateCETInputs @SourceType, @AVCVersion, @FirstYear
IF @ValResult > 0 
BEGIN 
Print 'Validation failed. Exiting Run.'
RETURN 
END
Print 'Validation passed'


SET @BaseYear = (SELECT BaseYear from dbo.CETAvoidedCostVersions WHERE [Version] = @AVCVersion)
SET @AVCElecTable = (SELECT AVCElecTable from dbo.CETAvoidedCostVersions WHERE [Version] = @AVCVersion)
SET @AVCGasTable = (SELECT AVCGasTable from dbo.CETAvoidedCostVersions WHERE [Version] = @AVCVersion)

IF @FirstYear = -1
BEGIN
	SET @FirstYear = @BaseYear
END

PRINT  'First Year=' + Convert(varchar,@FirstYear)
PRINT  'Avoided Cost Version=' + Convert(varchar,@AVCVersion)

SET @Host = Host_Name()
SET @CETCoreDbName = DB_Name()

-- Set Description
IF @Description = ''
BEGIN
	SET @Description = 'RunDB job started at ' +  Convert(nvarchar(25), GetDate())
END

-- Set User
IF @User = ''
BEGIN
	SET @User = System_User
END

IF @SourceType = 'Excel' OR @SourceType = 'CEDARS'
BEGIN
	SET @MTableName = ''
	SET @PTableName = ''
END

SET @PTableName = @ProgramTable

-- Determine if we need to set the measure database
SET @MeasureTable = Replace(Replace(@MeasureTable,'[',''),']','') --  remove brackets around 'dbo'

IF PATINDEX('%.dbo.%',@MeasureTable) > 0 -- there is a database name
	BEGIN
	IF @CETSourceDbName = '' -- LEGACY: Get the Source Database name from the measure table. 
		BEGIN
			SET @CETSourceDbName = LEFT(@MeasureTable,  PATINDEX('%.dbo.%',@MeasureTable)-1)
		END
		SET @MTableName = RIGHT(@MeasureTable, LEN(@MeasureTable)- (PATINDEX('%.dbo.%',@MeasureTable)+4))
	END
ELSE -- only measure table
	BEGIN
		IF @CETSourceDbName = '' -- DEFAULT. Use Core Database if no Source database passed
		BEGIN
			SET @CETSourceDbName = DB_Name()
		END
		SET @MTableName = @MeasureTable
	END

EXEC dbo.GetCETVersion @Version = @VersionSource OUTPUT
EXEC dbo.GetCETVersion @CETCoreDbName, @Version = @VersionCore OUTPUT
EXEC dbo.GetCETVersion @CETCoreDbName, @Version = @VersionData OUTPUT

IF @AVCDbName = '' -- DEFAULT. Use Core Database if no Source database passed
BEGIN
	SET @AVCDbName = DB_Name()
END

PRINT 'CETDataDbName=' + Case When @CETDataDbName='' THEN DB_Name() ELSE @CETDataDbName END

BEGIN
EXEC	[dbo].[CreateJob]
		@JobDescription = @Description,
		@CETDataDbName = @CETDataDbName,
		@CETSourceDbName = @CETSourceDbName,
		@CETCoreDbName = @CETCoreDbName,
		@WebUserId = @User,
		@Server = @Host,
		@UserID = @User,
		@Password = '',
		@SourceType = @SourceType,
		@InputProgramTable = @PTableName,
		@InputMeasureTable = @MTableName,
		@InputFilePathMeasure = @FilePath,
		@CETSourceVersion = @VersionSource,
		@CETCoreVersion = @VersionCore,
		@CETDataVersion = @VersionData,
		@Status = 'InProgress',
		@StatusDetail = '',
		@MarketEffectBens = @MEBens,
		@MarketEffectCost = @MECost,
		@SavingsOnly = 0,
		@AvoidedCostDbName = @AVCDbName,
		@AvoidedCostVersion = @AVCVersion,
		@FirstYear = @FirstYear,
		@JobIDOut = @JobID OUTPUT
END

SELECT @JobID JobID


IF @SourceType = 'Excel'
BEGIN
	UPDATE dbo.InputMeasure SET JobID = @JobID
END

PRINT 'AvoidedCost Elec Table = ' + CONVERT(VARCHAR,@AVCElecTable)
PRINT 'Initializing Avoided Cost Tables'
EXEC dbo.InitializeTablesAvoidedCosts @JobID, @AVCElecTable, @AVCGasTable, @BaseYear, @FirstYear, @AVCVersion

PRINT 'Initializing Source Tables'
EXEC InitializeSourceTables @JobID, @SourceType, @CETSourceDbName, @MTableName, @PTableName, @FirstYear, @AVCVersion, @IncludeNonresourceCosts

PRINT 'Initializing Mapping Tables, First Year = ' + CONVERT(VARCHAR,@FirstYear)
EXEC InitializeTables @JobID, @SourceType, @CETSourceDbName, @MTableName, @PTableName, @FirstYear, @AVCVersion, @IncludeNonresourceCosts

PRINT 'Finalizing Tables and Run CET'
SET @ValidateRun = 1 -- Set Validation so that valoidation will be run
EXEC FinalizeTables @JobID, @MEBens, @MECost, @CETDataDbName, @ValidateRun, @AVCVersion, @FirstYear, @SourceType


PRINT 'End of RunCET job ' + CONVERT(VARCHAR,@JobID) + ' at ' + CONVERT(VARCHAR,GETDATE())
PRINT '*********************'

SELECT CONVERT(INT,@JobID) 

RETURN CONVERT(INT,@JobID) 

GO