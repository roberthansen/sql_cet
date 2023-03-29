USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[CalcAll]    Script Date: 12/16/2019 12:47:38 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





--#################################################################################################
-- Name             :  CalcAll
-- Date             :  06/30/2016
-- Author           :  Wayne Hauck
-- Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
-- Purpose          :  This stored procedure runs the main stored procedures for cost effectiveness, savings, emissions, and cost.
-- Usage            :  n/a
-- Called by        :  n/a
-- Copyright ©      :  Developed by Pinnacle Consulting Group (aka InTech Energy, Inc.) for California Public Utilities Commission (CPUC). All Rights Reserved.
-- Change History   :  06/30/2016  Wayne Hauck added comment header
--                     
--#################################################################################################


CREATE PROCEDURE [dbo].[CalcAll]
@JobID int = -1,
@MEBens float=Null,
@MECost float=Null,
@AVCVersion varchar(255),
@FirstYear int

AS

SET NOCOUNT ON

DECLARE @SavingsOnly bit

SET @SavingsOnly = (SELECT SavingsOnly from CETJobs where ID = @JobID)

IF @SavingsOnly = 1 
    BEGIN
        EXEC CalcSavings @JobID, @MEBens
    END
ELSE
    BEGIN
Print 'Running CalcCE at ' + Convert(varchar,GetDate())
        EXEC CalcCE @JobID, @MEBens, @MECost, @FirstYear, @AVCVersion

Print 'Running CalcSavings at ' + Convert(varchar,GetDate())
        EXEC CalcSavings @JobID, @MEBens

-- The emissions for 2017 have a CO2 rate dependent on the quarter. Because of this, there is a different (legacy) calculation for 2013
IF @AVCVersion <> '2013'
    BEGIN
        Print 'Running CalcEmissions at ' + Convert(varchar,GetDate())
        EXEC CalcEmissions @JobID, @MEBens, @AVCVersion
    END
ELSE
    BEGIN
        Print 'Running CalcEmissions2013 at ' + Convert(varchar,GetDate())
        EXEC CalcEmissions2013 @JobID, @MEBens
    END

Print 'Running CalcCost at ' + Convert(varchar,GetDate())
        EXEC CalcCost @JobID, @MEBens, @MECost, @FirstYear, @AVCVersion

Print 'End of CalcCost at ' + Convert(varchar,GetDate())

END




GO


