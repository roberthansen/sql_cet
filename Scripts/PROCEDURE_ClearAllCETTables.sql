USE [CET_2018_new_release]
GO

/****** Object:  StoredProcedure [dbo].[ClearAllCETTables]    Script Date: 12/16/2019 1:17:40 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO






--#################################################################################################
-- Name             :  ClearAllCETTables
-- Date             :  06/30/2016
-- Author           :  Wayne Hauck
-- Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
-- Purpose          :  This stored procedure clears all output tables for all jobs including the CETJobs table.
-- Usage            :  n/a
-- Called by        :  n/a
-- Copyright ©      :  Developed by Pinnacle Consulting Group (aka Intech Energy, Inc.) for California Public Utilities Commission (CPUC), All Rights Reserved
-- Change History   :  06/30/2016  Wayne Hauck added comment header
--                     
--#################################################################################################


CREATE PROCEDURE [dbo].[ClearAllCETTables]
AS
BEGIN

SET NOCOUNT ON

    DELETE FROM [InputMeasure]
    DELETE FROM [InputProgram]

    TRUNCATE TABLE [CETJobs]
    DBCC CHECKIDENT ('CETJobs', RESEED, 1)

    TRUNCATE TABLE [dbo].[OutputCE]
    DBCC CHECKIDENT ('OutputCE', RESEED, 1)

    TRUNCATE TABLE [dbo].[OutputEmissions]
    DBCC CHECKIDENT ('OutputEmissions', RESEED, 1)

    TRUNCATE TABLE [dbo].[OutputSavings]
    DBCC CHECKIDENT ('OutputSavings', RESEED, 1)

    TRUNCATE TABLE [dbo].[OutputCost]
    DBCC CHECKIDENT ('OutputCost', RESEED, 1)

    TRUNCATE TABLE [InputValidation]
    DBCC CHECKIDENT ('InputValidation', RESEED, 1)

    TRUNCATE TABLE [SavedCE]
    DBCC CHECKIDENT ('SavedCE', RESEED, 1)

    TRUNCATE TABLE [SavedSavings]
    DBCC CHECKIDENT ('SavedSavings', RESEED, 1)

    TRUNCATE TABLE [SavedEmissions]
    DBCC CHECKIDENT ('SavedEmissions', RESEED, 1)

    TRUNCATE TABLE [SavedCost]
    DBCC CHECKIDENT ('SavedCost', RESEED, 1)

    TRUNCATE TABLE [SavedValidation]
    DBCC CHECKIDENT ('SavedValidation', RESEED, 1)

    TRUNCATE TABLE [SavedInput]
    DBCC CHECKIDENT ('SavedInput', RESEED, 1)

    TRUNCATE TABLE [SavedInputCEDARS]
    DBCC CHECKIDENT ('SavedInput', RESEED, 1)

    TRUNCATE TABLE [SavedProgramCost]
    DBCC CHECKIDENT ('SavedProgramCost', RESEED, 1)

    TRUNCATE TABLE [SavedProgramCostCEDARS]
    DBCC CHECKIDENT ('SavedProgramCost', RESEED, 1)

END

















GO


