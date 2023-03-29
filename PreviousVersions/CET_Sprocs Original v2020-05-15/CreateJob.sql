USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[CreateJob]    Script Date: 12/16/2019 1:20:47 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


--#################################################################################################
-- Name             :  CreateJob
-- Purpose          :  This stored procedure creates a job in the CETJob table.
-- Usage            :  n/a
-- Called by        :  n/a
-- Date             :  06/30/2016
-- Author           :  Wayne Hauck
-- Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
-- Copyright ©      :  Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
-- Change History   :  5/20/2017  Revised to return JobID as an output parameter.
-- Change History   :  06/30/2016  Wayne Hauck added comment header
--                     
--#################################################################################################
CREATE PROCEDURE [dbo].[CreateJob]
(
	@CETDataDbName AS NVARCHAR(128) = N'',
	@WebUserId AS NVARCHAR(256) = N'',
	@JobDescription AS NVARCHAR(255) = N'',
	@SourceType AS NVARCHAR(50) = N'',
	@Server AS NVARCHAR(255) = N'',
	@CETSourceDbName AS NVARCHAR(128) = N'',
	@UserID AS NVARCHAR(255) = N'',
	@Password AS NVARCHAR(255) = N'',
	@InputProgramTable AS NVARCHAR(255) = N'',
	@InputMeasureTable AS NVARCHAR(255) = N'',
	@InputFilePathMeasure AS NVARCHAR(298) = N'',
	@InputFilePathProgram AS NVARCHAR(298) = N'',
	@CETCoreDbName AS NVARCHAR(128) = N'',
	@Version AS NVARCHAR(255) = N'',
	@CETSourceVersion AS NVARCHAR(255) = N'',
	@CETCoreVersion AS NVARCHAR(255) = N'',
	@CETDataVersion AS NVARCHAR(255) = N'',
	@Status AS NVARCHAR(255) = N'',
	@StatusDetail AS NVARCHAR(MAX) = N'',
	@MarketEffectBens AS FLOAT = NULL,
	@MarketEffectCost AS FLOAT = NULL,
	@SavingsOnly AS BIT = 0,
	@AvoidedCostDbName AS NVARCHAR(255) = N'',
	@AvoidedCostVersion AS NVARCHAR(255) = N'2013',
	@FirstYear AS INT = 2013,
	@JobIDOut AS INT = -1 OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON;

	IF (@CETDataDbName = N'')
	BEGIN 
		SET @CETDataDbName = N'dbo.';
	END
	ELSE
	BEGIN
		SET @CETDataDbName = @CETDataDbName + N'.dbo.';
	END;

	/**************   DO INSERT   ***************/

	DECLARE @Sql AS NVARCHAR(MAX);
	DECLARE @Parameters AS NVARCHAR(MAX);
	DECLARE @CR_LF AS CHAR(2) = CHAR(13) + CHAR(10);

	SET @Parameters = N'@ID INT OUTPUT';

	SET @Sql = N'DECLARE @IdentityValue AS TABLE([ID] INT);'
	+ @CR_LF + N''
	+ @CR_LF + N'INSERT INTO ' + @CETDataDbName + '[CETJobs]'
	+ @CR_LF + N'('
	+ @CR_LF + N'		 [WebUserId]'
	+ @CR_LF + N'		,[JobDescription]'
	+ @CR_LF + N'		,[SourceType]'
	+ @CR_LF + N'		,[Server]'
	+ @CR_LF + N'		,[Database]'
	+ @CR_LF + N'		,[UserID]'
	+ @CR_LF + N'		,[Password]'
	+ @CR_LF + N'		,[InputProgramTable]'
	+ @CR_LF + N'		,[InputMeasureTable]'
	+ @CR_LF + N'		,[InputFilePathMeasure]'
	+ @CR_LF + N'		,[InputFilePathProgram]'
	+ @CR_LF + N'		,[CETCoreDbName]'
	+ @CR_LF + N'		,[CETDataDbName]'
	+ @CR_LF + N'		,[MappingType]'
	+ @CR_LF + N'		,[Version]'
	+ @CR_LF + N'		,[CETSourceVersion]'
	+ @CR_LF + N'		,[CETCoreVersion]'
	+ @CR_LF + N'		,[CETDataVersion]'
	+ @CR_LF + N'		,[Status]'
	+ @CR_LF + N'		,[ModifiedDate]'
	+ @CR_LF + N'		,[ModifiedUser]'
	+ @CR_LF + N'		,[Started]'
	+ @CR_LF + N'		,[StatusDetail]'
	+ @CR_LF + N'		,[MarketEffectBens]'
	+ @CR_LF + N'		,[MarketEffectCost]'
	+ @CR_LF + N'		,[AvoidedCostDbName]'
	+ @CR_LF + N'		,[AvoidedCostVersion]'
	+ @CR_LF + N'		,[FirstYear]'
	+ @CR_LF + N')'
	+ @CR_LF + N'OUTPUT  [INSERTED].[ID] INTO @IdentityValue'
	+ @CR_LF + N'SELECT	 [WebUserId]            = ' + QUOTENAME(@WebUserId, CHAR(39)) + 
	+ @CR_LF + N'		,[JobDescription]       = ' + QUOTENAME(@JobDescription, CHAR(39)) + 
	+ @CR_LF + N'		,[SourceType]           = ' + QUOTENAME(@SourceType, CHAR(39)) + 
	+ @CR_LF + N'		,[Server]               = ' + QUOTENAME(@Server, CHAR(39)) + 
	+ @CR_LF + N'		,[Database]             = ' + QUOTENAME(@CETSourceDbName, CHAR(39)) + 
	+ @CR_LF + N'		,[UserID]               = ' + QUOTENAME(@UserID, CHAR(39)) + 
	+ @CR_LF + N'		,[Password]             = ' + QUOTENAME(@Password, CHAR(39)) + 
	+ @CR_LF + N'		,[InputProgramTable]    = ' + QUOTENAME(@InputProgramTable, CHAR(39)) + 
	+ @CR_LF + N'		,[InputMeasureTable]    = ' + QUOTENAME(@InputMeasureTable, CHAR(39)) + 
	+ @CR_LF + N'		,[InputFilePathMeasure] = ' + QUOTENAME(@InputFilePathMeasure, CHAR(39)) + 
	+ @CR_LF + N'		,[InputFilePathProgram] = ' + QUOTENAME(@InputFilePathProgram, CHAR(39)) + 
	+ @CR_LF + N'		,[CETCoreDbName]        = ' + QUOTENAME(@CETCoreDbName, CHAR(39)) + 
	+ @CR_LF + N'		,[CETDataDbName]        = ' + QUOTENAME(REPLACE(@CETDataDbName, N'.dbo.', N''), CHAR(39)) + 
	+ @CR_LF + N'		,[MappingType]          = ' + QUOTENAME(@SourceType, CHAR(39)) + 
	+ @CR_LF + N'		,[Version]              = ' + QUOTENAME(@Version, CHAR(39)) + 
	+ @CR_LF + N'		,[CETSourceVersion]     = ' + QUOTENAME(@CETSourceVersion, CHAR(39)) + 
	+ @CR_LF + N'		,[CETCoreVersion]       = ' + QUOTENAME(@CETCoreVersion, CHAR(39)) + 
	+ @CR_LF + N'		,[CETDataVersion]       = ' + QUOTENAME(@CETDataVersion, CHAR(39)) + 
	+ @CR_LF + N'		,[Status]               = ' + QUOTENAME(@Status, CHAR(39)) + 
	+ @CR_LF + N'		,[ModifiedDate]         = ' + QUOTENAME(CONVERT(NVARCHAR, CURRENT_TIMESTAMP), CHAR(39)) + 
	+ @CR_LF + N'		,[ModifiedUser]         = ' + QUOTENAME(@WebUserId, CHAR(39)) + 
	+ @CR_LF + N'		,[Started]              = ' + QUOTENAME(CONVERT(NVARCHAR, CURRENT_TIMESTAMP), CHAR(39)) + 
	+ @CR_LF + N'		,[StatusDetail]         = ' + QUOTENAME(@StatusDetail, CHAR(39)) + 
	+ @CR_LF + N'		,[MarketEffectBens]     = ' + CONVERT(NVARCHAR, ISNULL(@MarketEffectBens, 0))
	+ @CR_LF + N'		,[MarketEffectCost]     = ' + CONVERT(NVARCHAR, ISNULL(@MarketEffectCost, 0))
	+ @CR_LF + N'		,[AvoidedCostDbName]    = ' + QUOTENAME(REPLACE(@AvoidedCostDbName, N'.dbo.', N''), CHAR(39)) + 
	+ @CR_LF + N'		,[AvoidedCostVersion]   = ' + QUOTENAME(@AvoidedCostVersion, CHAR(39)) + 
	+ @CR_LF + N'		,[FirstYear]            = ' + CONVERT(NVARCHAR, ISNULL(@FirstYear, 2013)) + N';'
	+ @CR_LF + N''
	+ @CR_LF + N'SET @ID = (SELECT [ID] FROM @IdentityValue);';

	--PRINT @Sql
	EXECUTE [sys].[sp_executesql] @Sql, @Parameters, @ID = @JobIDOut OUTPUT;

END;

GO


