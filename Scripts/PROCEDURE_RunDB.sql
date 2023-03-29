USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[RunDB]    Script Date: 12/16/2019 2:01:23 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


--#################################################################################################
-- Name             :  RunDB
-- Date             :  06/30/2016
-- Author           :  Wayne Hauck
-- Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
-- Purpose          :  Note: This stored procedure has been super-ceded by RunCET. It is retained for legacy purposes.
-- Usage            :  n/a
-- Called by        :  n/a
-- Copyright ©      :  Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
-- Change History   :  06/30/2016  Wayne Hauck added comment header
--                     
--#################################################################################################


CREATE PROCEDURE [dbo].[RunDB]
@MeasureTable VARCHAR(255)='EDFilled',
@ProgramTable VARCHAR(255)='ProgramCost',
@MEBens FLOAT=0.0,
@MECost FLOAT=0.0,
@Description NVARCHAR(255) = ''
AS

SET NOCOUNT ON

-- Set Description
IF @Description = ''
BEGIN
	SET @Description = 'RunDB job started at ' +  Convert(nvarchar(25), GetDate())
END

DECLARE @MTableName varchar(255)
DECLARE @PTableName varchar(255)
DECLARE @DBName varchar(255)
DECLARE @JobID int
DECLARE @Rows int
DECLARE @SQL nvarchar(max)

-- Determine if we need to set the measure database
SET @MeasureTable = Replace(Replace(@MeasureTable,'[',''),']','') --  remove brackets around 'dbo'

IF PATINDEX('%.dbo.%',@MeasureTable) > 0 -- there is a database name
	BEGIN
		SET @DBName = LEFT(@MeasureTable,  PATINDEX('%.dbo.%',@MeasureTable)-1)
		SET @MTableName = RIGHT(@MeasureTable, LEN(@MeasureTable)- (PATINDEX('%.dbo.%',@MeasureTable)+4))
	END
ELSE -- only measure table
	BEGIN
		SET @DBName = DB_Name()
		SET @MTableName = @MeasureTable
	END

SET @PTableName = @ProgramTable

--Get Job ID
SELECT  @JobID = ISNULL(MAX(id), 0) + 1 from CETJobs

---- Get number of rows to be processed
--SET @SQL = 'SELECT Count(*) FROM ' + @MeasureTable
--EXEC @Rows = sp_executesql @SQL

EXEC InitializeTables @JobID, 'CETDatabase', @DBName, @MTableName, @PTableName, 'E3AvoidedCostElecSeq', 'E3AvoidedCostGasSeq'

INSERT INTO [dbo].[CETJobs]
           ([WebUserId]
           ,[JobDescription]
           ,[SourceType]
           ,[Server]
           ,[Database]
           ,[UserID]
           ,[Password]
           ,[InputProgramTable]
           ,[InputMeasureTable]
           ,[InputFilePathMeasure]
           ,[InputFilePathProgram]
           ,[MappingType]
           ,[Version]
           ,[Status]
           ,[SaveThisJob]
           ,[ModifiedDate]
           ,[ModifiedUser]
           ,[Saved]
           ,[Downloaded]
           ,[Started]
           ,[Finished]
           ,[Duration]
           ,[StatusDetail]
           ,[Rows]
           ,[MarketEffectBens]
           ,[MarketEffectCost])
 SELECT HOST_NAME(), @Description, 'CETDatabase', HOST_NAME(),  @DBName, 
 SYSTEM_USER, '', @ProgramTable, @MeasureTable, NULL, NULL, NULL, '1314', 'InProgress', 1, GETDATE(), SYSTEM_USER, 0, 0, GETDATE(), NULL, NULL, NULL, 0, @MEBens,@MECost

EXEC FinalizeTables @JobID 

RETURN @JobID














GO


