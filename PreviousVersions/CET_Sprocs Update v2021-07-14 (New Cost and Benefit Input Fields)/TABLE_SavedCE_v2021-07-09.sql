/*
################################################################################
Name             :  SavedCE (table)
Date             :  06/30/2016
Author           :  Wayne Hauck
Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose          :  This stored procedure calculates cost effectiveness.
Usage            :  n/a
Called by        :  n/a
Copyright �      :  Developed by Pinnacle Consulting Group (aka Intech Energy,
                 :  Inc.) for California Public Utilities Commission (CPUC),
				 :  All Rights Reserved
Change History   :  05/28/2021  Robert Hansen added "SupplyCost" and 
                 :  "TotalSystemBenefits" fields
				 :  07/08/2021  Robert Hansen renamed "TotalSystemBenefits" to
				 :  "TotalSystemBenefit"
				 :  07/09/2021  Robert Hansen added OtherBenGross and
				 :  OtherCostGross to outputs.
################################################################################
*/

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.SavedCE') IS NOT NULL
    DROP TABLE dbo.SavedCE
GO

CREATE TABLE dbo.SavedCE(
	ID INT IDENTITY(1,1) NOT NULL,
	JobID INT NOT NULL,
	PA NVARCHAR(8) NULL,
	PrgID NVARCHAR(255) NULL,
	CET_ID NVARCHAR(255) NOT NULL,
	ElecBen FLOAT NULL,
	GasBen FLOAT NULL,
	ElecBenGross FLOAT NULL,
	GasBenGross FLOAT NULL,
	OtherBen FLOAT NULL,
	OtherBenGross FLOAT NULL,
	ElecSupplyCost FLOAT NULL,
    GasSupplyCost FLOAT NULL,
    ElecSupplyCostGross FLOAT NULL,
    GasSupplyCostGross FLOAT NULL,
	OtherCost FLOAT NULL,
	OtherCostGross FLOAT NULL,
	TotalSystemBenefit FLOAT NULL,
	TotalSystemBenefitGross FLOAT NULL,
	TRCCost FLOAT NULL,
	PACCost FLOAT NULL,
	TRCCostGross FLOAT NULL,
	TRCCostNoAdmin FLOAT NULL,
	PACCostNoAdmin FLOAT NULL,
	TRCRatio FLOAT NULL,
	PACRatio FLOAT NULL,
	TRCRatioNoAdmin FLOAT NULL,
	PACRatioNoAdmin FLOAT NULL,
	BillReducElec FLOAT NULL,
	BillReducGas FLOAT NULL,
	RIMCost FLOAT NULL,
	WeightedBenefits FLOAT NULL,
	WeightedElecAlloc FLOAT NULL,
	WeightedProgramCost FLOAT NULL
) ON [PRIMARY]
GO

ALTER TABLE dbo.SavedCE ADD CONSTRAINT [PK_SavedCE] PRIMARY KEY CLUSTERED ([ID]) WITH (STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_CET_ID] ON [dbo].[SavedCE] ([CET_ID]) WITH (STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_JobID] ON [dbo].[SavedCE] ([JobID]) WITH (STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_PA] ON [dbo].[SavedCE] ([PA]) WITH (STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_PrgID] ON [dbo].[SavedCE] ([PrgID]) WITH (STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO