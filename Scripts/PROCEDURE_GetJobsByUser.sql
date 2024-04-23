USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[GetJobsByUser]    Script Date: 2019-12-16 1:31:50 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetJobsByUser]
         @userID NVARCHAR(256)
AS
BEGIN
SELECT [ID]
      ,[WebUserId]
      ,[JobDescription]
	  ,[JobDescription] + ' (JobID: ' + CONVERT(NVARCHAR, ID) + ')' AS JobDescription2
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
  FROM [dbo].[CETJobs]
  WHERE [WebUserId] = @userID
  ORDER BY [ID] DESC

END

GO


