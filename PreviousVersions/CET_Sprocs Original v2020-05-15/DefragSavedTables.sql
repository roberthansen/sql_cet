USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[DefragSavedTables]    Script Date: 12/16/2019 1:21:35 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[DefragSavedTables]
@CETDataDbName NVARCHAR(255) = '',
@ForceDefragAll BIT = 0
         
AS

DECLARE @FragPct float;
DECLARE @SQL NVARCHAR(MAX);
DECLARE @DBName NVARCHAR(255)

BEGIN

	IF @CETDataDbName = ''
		SET @DBName = DB_NAME()
	ELSE
		SET @DBName = @CETDataDbName

IF 	@ForceDefragAll = 0
BEGIN
	SET @SQL = 'DECLARE @FragPct float; SELECT @FragPct = avg_fragmentation_in_percent
	FROM sys.dm_db_index_physical_stats (DB_ID(''' + @DBname + '''), OBJECT_ID('''+ @DBname + '.dbo.OutputCE''), NULL, NULL, NULL) 
	BEGIN IF @FragPct > 1.25 ALTER INDEX ALL ON ' + @DBname + '.dbo.OutputCE REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON) END'
    EXEC  sp_executesql @SQL

	SET @SQL = 'DECLARE @FragPct float; SELECT @FragPct = avg_fragmentation_in_percent
	FROM sys.dm_db_index_physical_stats (DB_ID(''' + @DBname + '''), OBJECT_ID('''+ @DBname + '.dbo.OutputEmissions''), NULL, NULL, NULL) 
	BEGIN IF @FragPct > 1.25 ALTER INDEX ALL ON ' + @DBname + '.dbo.OutputEmissions REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON) END'
    EXEC  sp_executesql @SQL

	SET @SQL = 'DECLARE @FragPct float; SELECT @FragPct = avg_fragmentation_in_percent
	FROM sys.dm_db_index_physical_stats (DB_ID(''' + @DBname + '''), OBJECT_ID('''+ @DBname + '.dbo.OutputSavings''), NULL, NULL, NULL) 
	BEGIN IF @FragPct > 1.25 ALTER INDEX ALL ON ' + @DBname + '.dbo.OutputSavings REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON) END'
    EXEC  sp_executesql @SQL

	SET @SQL = 'DECLARE @FragPct float; SELECT @FragPct = avg_fragmentation_in_percent
	FROM sys.dm_db_index_physical_stats (DB_ID(''' + @DBname + '''), OBJECT_ID('''+ @DBname + '.dbo.OutputCost''), NULL, NULL, NULL) 
	BEGIN IF @FragPct > 1.25 ALTER INDEX ALL ON ' + @DBname + '.dbo.OutputCost REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON) END'
    EXEC  sp_executesql @SQL

	SET @SQL = 'DECLARE @FragPct float; SELECT @FragPct = avg_fragmentation_in_percent
	FROM sys.dm_db_index_physical_stats (DB_ID(''' + @DBname + '''), OBJECT_ID('''+ @DBname + '.dbo.SavedCE''), NULL, NULL, NULL) 
	BEGIN IF @FragPct > 1.25 ALTER INDEX ALL ON ' + @DBname + '.dbo.SavedCE REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON) END'
    EXEC  sp_executesql @SQL

	SET @SQL = 'DECLARE @FragPct float; SELECT @FragPct = avg_fragmentation_in_percent
	FROM sys.dm_db_index_physical_stats (DB_ID(''' + @DBname + '''), OBJECT_ID('''+ @DBname + '.dbo.SavedCost''), NULL, NULL, NULL) 
	BEGIN IF @FragPct > 1.25 ALTER INDEX ALL ON ' + @DBname + '.dbo.SavedCost REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON) END'
    EXEC  sp_executesql @SQL

	SET @SQL = 'DECLARE @FragPct float; SELECT @FragPct = avg_fragmentation_in_percent
	FROM sys.dm_db_index_physical_stats (DB_ID(''' + @DBname + '''), OBJECT_ID('''+ @DBname + '.dbo.SavedEmissions''), NULL, NULL, NULL) 
	BEGIN IF @FragPct > 1.25 ALTER INDEX ALL ON ' + @DBname + '.dbo.SavedEmissions REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON) END'
    EXEC  sp_executesql @SQL

	SET @SQL = 'DECLARE @FragPct float; SELECT @FragPct = avg_fragmentation_in_percent
	FROM sys.dm_db_index_physical_stats (DB_ID(''' + @DBname + '''), OBJECT_ID('''+ @DBname + '.dbo.SavedInput''), NULL, NULL, NULL) 
	BEGIN IF @FragPct > 1.25 ALTER INDEX ALL ON ' + @DBname + '.dbo.SavedInput REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON) END'
    EXEC  sp_executesql @SQL

	SET @SQL = 'DECLARE @FragPct float; SELECT @FragPct = avg_fragmentation_in_percent
	FROM sys.dm_db_index_physical_stats (DB_ID(''' + @DBname + '''), OBJECT_ID('''+ @DBname + '.dbo.SavedProgramCost''), NULL, NULL, NULL) 
	BEGIN IF @FragPct > 1.25 ALTER INDEX ALL ON ' + @DBname + '.dbo.SavedProgramCost REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON) END'
    EXEC  sp_executesql @SQL

	SET @SQL = 'DECLARE @FragPct float; SELECT @FragPct = avg_fragmentation_in_percent
	FROM sys.dm_db_index_physical_stats (DB_ID(''' + @DBname + '''), OBJECT_ID('''+ @DBname + '.dbo.SavedSavings''), NULL, NULL, NULL) 
	BEGIN IF @FragPct > 1.25 ALTER INDEX ALL ON ' + @DBname + '.dbo.SavedSavings REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON) END'
    EXEC  sp_executesql @SQL

	SET @SQL = 'DECLARE @FragPct float; SELECT @FragPct = avg_fragmentation_in_percent
	FROM sys.dm_db_index_physical_stats (DB_ID(''' + @DBname + '''), OBJECT_ID('''+ @DBname + '.dbo.SavedValidation''), NULL, NULL, NULL) 
	BEGIN IF @FragPct > 1.25 ALTER INDEX ALL ON ' + @DBname + '.dbo.SavedValidation REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON) END'
    EXEC  sp_executesql @SQL

	SET @SQL = 'DECLARE @FragPct float; SELECT @FragPct = avg_fragmentation_in_percent
	FROM sys.dm_db_index_physical_stats (DB_ID(''' + @DBname + '''), OBJECT_ID('''+ @DBname + '.dbo.PortfolioCosts''), NULL, NULL, NULL) 
	BEGIN IF @FragPct > 1.25 ALTER INDEX ALL ON ' + @DBname + '.dbo.PortfolioCosts REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON) END'
    EXEC  sp_executesql @SQL

	SET @SQL = 'DECLARE @FragPct float; SELECT @FragPct = avg_fragmentation_in_percent
	FROM sys.dm_db_index_physical_stats (DB_ID(''' + @DBname + '''), OBJECT_ID('''+ @DBname + '.dbo.PortfolioMeasures''), NULL, NULL, NULL) 
	BEGIN IF @FragPct > 1.25 ALTER INDEX ALL ON ' + @DBname + '.dbo.PortfolioMeasures REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON) END'
    EXEC  sp_executesql @SQL
END
ELSE
BEGIN
	SET @SQL = 'ALTER INDEX ALL ON ' + @DBname + '.dbo.OutputCE REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON)'
    EXEC  sp_executesql @SQL

	SET @SQL = 'ALTER INDEX ALL ON ' + @DBname + '.dbo.OutputEmissions REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON)'
    EXEC  sp_executesql @SQL

	SET @SQL = 'ALTER INDEX ALL ON ' + @DBname + '.dbo.OutputSavings REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON)'
    EXEC  sp_executesql @SQL

	SET @SQL = 'ALTER INDEX ALL ON ' + @DBname + '.dbo.OutputCost REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON)'
    EXEC  sp_executesql @SQL

	SET @SQL = 'ALTER INDEX ALL ON ' + @DBname + '.dbo.SavedCE REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON)'
    EXEC  sp_executesql @SQL

	SET @SQL = 'ALTER INDEX ALL ON ' + @DBname + '.dbo.SavedCost REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON)'
    EXEC  sp_executesql @SQL

	SET @SQL = 'ALTER INDEX ALL ON ' + @DBname + '.dbo.SavedEmissions REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON)'
    EXEC  sp_executesql @SQL

	SET @SQL = 'ALTER INDEX ALL ON ' + @DBname + '.dbo.SavedInput REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON)'
    EXEC  sp_executesql @SQL

	SET @SQL = 'ALTER INDEX ALL ON ' + @DBname + '.dbo.SavedProgramCost REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON)'
    EXEC  sp_executesql @SQL

	SET @SQL = 'ALTER INDEX ALL ON ' + @DBname + '.dbo.SavedSavings REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON)'
    EXEC  sp_executesql @SQL

	SET @SQL = 'ALTER INDEX ALL ON ' + @DBname + '.dbo.SavedValidation REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON)'
    EXEC  sp_executesql @SQL

	SET @SQL = 'ALTER INDEX ALL ON ' + @DBname + '.dbo.PortfolioCosts REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON)'
    EXEC  sp_executesql @SQL

	SET @SQL = 'ALTER INDEX ALL ON ' + @DBname + '.dbo.PortfolioMeasures REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON)'
    EXEC  sp_executesql @SQL

END

END


GO


