USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[GetAvoidedCostVersion]    Script Date: 12/16/2019 1:24:28 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[GetAvoidedCostVersion]
@Version VARCHAR(255),
@AvoidedCostVersion NVARCHAR(255) OUTPUT

AS

SELECT @AvoidedCostVersion = AvoidedCostVersion FROM CETVersion v WHERE v.YearDescription =  @Version




GO


