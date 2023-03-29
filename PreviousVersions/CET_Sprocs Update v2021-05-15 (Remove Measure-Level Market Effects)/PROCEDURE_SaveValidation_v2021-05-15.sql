USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[SaveValidation]    Script Date: 12/16/2019 2:09:59 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



--#################################################################################################
-- Name             :  SaveValidation
-- Date             :  06/30/2016
-- Author           :  Wayne Hauck
-- Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
-- Purpose          :  This stored procedure saves validations by JobID into the SavedValidation table.
-- Usage            :  n/a
-- Called by        :  n/a
-- Copyright ©      :  Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
-- Change History   :  06/30/2016  Wayne Hauck added comment header
--                     
--#################################################################################################


CREATE PROCEDURE [dbo].[SaveValidation]
@JobID INT = -1,
@CETDataDbName VARCHAR(255)=''

AS

SET NOCOUNT ON

DECLARE @SQL1 NVARCHAR(MAX)
DECLARE @SQL2 NVARCHAR(MAX)

	IF @CETDataDbName <> '' AND @CETDataDbName <> DB_NAME()
	BEGIN

		--************** Start Validate Input  ***************
		SET @SQL1 = 
		'INSERT INTO ' + @CETDataDbName + '.dbo.SavedValidation  
		SELECT ' + CONVERT(NVARCHAR,@JobID) + ' AS JobID
			  ,[Table]
			  ,[ErrorType]
			  ,[CET_ID]
			  ,[MessageType]
			  ,[Detail]
				  FROM [dbo].[SavedValidation]'

		EXEC  sp_executesql @SQL1

		-- Clear table for Job
		SET @SQL2 = 'DELETE FROM dbo.SavedValidation WHERE JobID=' + CONVERT(NVARCHAR,@JobID)
		EXEC  sp_executesql @SQL2

	END






GO


