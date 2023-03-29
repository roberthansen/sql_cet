USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[ValidateCETInputs]    Script Date: 12/16/2019 2:10:41 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO






--#################################################################################################
-- Name             :  ValidateCETInput
-- Date             :  06/30/2016
-- Author           :  Wayne Hauck
-- Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
-- Purpose          :  This is the main entry point to run cost effectivensss both from the Desktop and in the database. It creates the job, and calls the InitializeTables and FinalizeTables sproc.
-- Usage            :  n/a
-- Called by        :  n/a
-- Copyright ©      :  Developed by Pinnacle Consulting Group (aka InTech Energy, Inc.) for California Public Utilities Commission (CPUC). All Rights Reserved.
-- Change History   :  06/30/2016  Wayne Hauck added comment header
--                     
--#################################################################################################

CREATE PROCEDURE [dbo].[ValidateCETInputs]
@SourceType NVARCHAR(25) = 'CETDatabase',
@AVCVersion NVARCHAR(255) = '2013',
@FirstYear INT

AS

DECLARE @AVCCount INT
DECLARE @ErrorMsg NVARCHAR(255)

IF @SourceType <> 'Excel' AND @SourceType <> 'CEDARS' AND @SourceType <> 'CEDARSDatabase'  AND @SourceType <> 'CEDARSExcel'AND @SourceType <> 'CETInput' AND @SourceType <> 'CETDatabase' AND @SourceType <> 'EDFilledDatabase' 
BEGIN
	;THROW 50001, 'Input Validation Error: SourceType must be one of the following: Excel, CEDARS, CEDARSExcel, CEDARSDatabase, CETInput, CETDatabase, EDFilledDatabase',1;
END


SET @ErrorMsg = 'Avoided Cost Version 2013 cannot be run in CET_2018 v18.1. To run on 2013 avoided costs,  please use CET_2017 or CET_2018 v18.1' 
IF @AVCVersion = '2013'
BEGIN
	;THROW 50004, @ErrorMsg, 4;
END


SET @ErrorMsg = 'Input Validation Error: Avoided Cost Version ' + @AVCVersion + ' is not recognized. Please check to make sure it is a valid input (2017, 2018)' 
IF @AVCVersion = '2013'
BEGIN
	;THROW 50002, @ErrorMsg, 2;
END

SET @ErrorMsg = 'Input Validation Error: First Year must be between 2013 and 2025' 
IF @FirstYear <> -1 AND (@FirstYear <2013 OR @FirstYear >2025) 
BEGIN
	;THROW 50003, @ErrorMsg, 3;
END


SET @AVCCount = (SELECT COUNT(*) FROM CETAvoidedCostVersions WHERE [Version] =  + @AVCVersion)
SET @ErrorMsg = 'Input Validation Error: Avoided Cost Version ' + @AVCVersion + ' is not recognized. Please check to make sure it is a valid input (2017, 2018)' 
IF @AVCCount = 0 OR @AVCVersion = '2013'
BEGIN
	;THROW 50004, @ErrorMsg, 4;
END






GO


