USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[SaveCETVersionDBName]    Script Date: 12/16/2019 2:03:45 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[SaveCETVersionDBName]
@Version VARCHAR(255),
@CETDataDbName NVARCHAR(255)

AS

UPDATE CETVersion SET DBName=  @CETDataDbName WHERE YearDescription =  @Version



GO


