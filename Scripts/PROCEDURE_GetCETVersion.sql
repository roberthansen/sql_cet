USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[GetCETVersion]    Script Date: 12/16/2019 1:25:12 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[GetCETVersion]
@CETDataDbName NVARCHAR(255) = '',
@Version VARCHAR(10) ='' OUTPUT

AS

DECLARE @SQL NVARCHAR(MAX);
DECLARE @Scope TABLE (Ver NVARCHAR(255));
DECLARE @Ver NVARCHAR(255)

IF @CETDataDbName =''
	BEGIN
		SET @CETDataDbName = 'dbo.'
	END 
ELSE
	BEGIN
		SET @CETDataDbName = @CETDataDbName + '.dbo.'
	END 

--************** Do Insert  ***************
SET @SQL = 
'SELECT [Version] FROM ' + @CETDataDbName + '[CETVersion] WHERE ID IN
(
	SELECT Max(ID)  FROM ' + @CETDataDbName + '[CETVersion]
)'

INSERT INTO @Scope
EXEC sp_executesql @SQL

SELECT @Version = Ver FROM @Scope 



GO


