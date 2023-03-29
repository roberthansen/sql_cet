USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[GetCETVersionDBName]    Script Date: 12/16/2019 1:28:57 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[GetCETVersionDBName]
@Version VARCHAR(255),
@CETDataDbName NVARCHAR(255) OUTPUT

AS

SELECT @CETDataDbName = DBName FROM CETVersion v   WHERE v.YearDescription =  @Version



GO


