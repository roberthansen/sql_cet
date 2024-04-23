USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[GetJobStatusByUser]    Script Date: 2019-12-16 1:32:31 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetJobStatusByUser]
         @UserId NVARCHAR(256)		 
AS
BEGIN
SELECT [id]
      ,[dataLoadStatusId]
      ,[status]
      ,[message]
      ,[jobId]
      ,[modifiedUser]
      ,[modifiedDate]
  FROM [dbo].[CETDataLoadStatusHistory]
  WHERE dataLoadStatusId = (SELECT TOP 1 [id] FROM [dbo].[CETDataLoadStatus] WHERE modifiedUser=@UserId ORDER BY jobid DESC)
  ORDER BY id DESC
END
GO


