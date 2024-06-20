USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[ValidationSummary]    Script Date: 2019-12-16 2:13:27 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[ValidationSummary]

AS

--*********** Display Summary of Results  ********************
SELECT [Table], ErrorType, COUNT(*) [Count],MessageType 
FROM InputValidation
GROUP BY [Table], ErrorType, MessageType
UNION
SELECT [Table], ErrorType, COUNT(*) [Count],MessageType 
FROM InputValidation
GROUP BY [Table], ErrorType, MessageType
UNION
SELECT [Table], ErrorType, COUNT(*) [Count],MessageType 
FROM InputValidation
--where PA IN ('PGE','SCE','SCG','SDGE') 
--and ([Table]<>'ProgramCost' and [Table]<>'ProgramDefinition')
GROUP BY [Table], ErrorType, MessageType
ORDER BY ErrorType, MessageType



















GO


