/*
################################################################################
Name             :  CalcSavings (procedure)
Date             :  06/30/2016
Author           :  Wayne Hauck
Company          :  Pinnacle Consulting Group (aka Intech Energy, Inc.)
Purpose          :  This stored procedure calculates savings outputs.
Usage            :  n/a
Called by        :  n/a
Copyright ©      :  Developed by Pinnacle Consulting Group (aka Intech Energy,
                 :  Inc.) for California Public Utilities Commission (CPUC),
                 :  All Rights Reserved
Change History   :  06/30/2016  Wayne Hauck added comment header
                 :  12/30/2016  Modified gross and net savings to use savings-
                 :              specific installation rate (IR) and realization
                 :              rate (RR)
                 :  05/25/2021  Robert Hansen removed MEBens field from
                 :              calculations
################################################################################
*/

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND OBJECT_ID = OBJECT_ID('dbo.CalcSavings'))
   exec('CREATE PROCEDURE [dbo].[CalcSavings] AS BEGIN SET NOCOUNT ON; END')
GO

ALTER PROCEDURE [dbo].[CalcSavings]
@JobID INT = -1,
@MEBens FLOAT=NULL

AS

SET NOCOUNT ON

DECLARE @ThermConv float
SET @ThermConv = 29.307111111

IF @MEBens Is Null
	BEGIN
		SET @MEBens = IsNull((SELECT MarketEffectBens from CETJobs WHERE ID = @JobID),0)
	END 

PRINT 'Inserting savings...'

CREATE TABLE [#OutputSavings](
	[JobID] [int] NULL,
	[PA] [nvarchar](8) NULL,
	[PrgID] [nvarchar](255) NULL,
	[CET_ID] [nvarchar](255) NOT NULL,
	[GrossKWh] [float] NULL,
	[GrossKW] [float] NULL,
	[GrossThm] [float] NULL,
	[NetKWh] [float] NULL,
	[NetKW] [float] NULL,
	[NetThm] [float] NULL,
	[LifecycleGrossKWh] [float] NULL,
	[LifecycleGrossThm] [float] NULL,
	[LifecycleNetKWh] [float] NULL,
	[LifecycleNetThm] [float] NULL,
	[GoalAttainmentkWh] [float] NULL,
	[GoalAttainmentKW] [float] NULL,
	[GoalAttainmentThm] [float] NULL,
	[FirstYearGrosskWh] [float] NULL,
	[FirstYearGrossKW] [float] NULL,
	[FirstYearGrossThm] [float] NULL,
	[FirstYearNetkWh] [float] NULL,
	[FirstYearNetKW] [float] NULL,
	[FirstYearNetThm] [float] NULL,
	[WeightedSavings] [float] NULL
) ON [PRIMARY]


BEGIN
	-- Insert into OutputSavings
	INSERT INTO #OutputSavings (
	JobID,
	PA,
	PrgID,
	CET_ID,
	GrossKWh,
	GrossKW,
	GrossThm,
	NetKWh,
	NetKW,
	NetThm,
	LifecycleGrossKWh,
	LifecycleGrossThm,
	LifecycleNetKWh,
	LifecycleNetThm,
	GoalAttainmentkWh,
	GoalAttainmentkW,
	GoalAttainmentThm,
	FirstYearGrosskWh,
	FirstYearGrossKW,
	FirstYearGrossThm,
	FirstYearNetkWh,
	FirstYearNetKW,
	FirstYearNetThm
		)
	SELECT @JobID
		,e.PA
		,e.PrgID
		,e.CET_ID
		,SUM(
			CASE
				WHEN RUL > 0
				THEN
					CASE
						WHEN EUL > 0
						THEN
							Qty * (IRkWh * RRkWh * kWh1 * RUL + IRkWh * RRkWh * kWh2 * (EUL - RUL)) / EUL
						ELSE 0
					END
				ELSE
					CASE
						WHEN EUL > 0
						THEN Qty * IRkWh * RRkWh * kWh1
						ELSE 0
					END
			END
		) AS GrossKWh
		,SUM(
			CASE
				WHEN RUL > 0
				THEN
					CASE
						WHEN EUL > 0
						THEN Qty * (IRkW * RRkW * kW1 * RUL + IRkW * RRkW * kW2 * (EUL - RUL)) / EUL
						ELSE 0
					END
				ELSE
					CASE
						WHEN EUL > 0
						THEN Qty * IRkW * RRkW * kW1
						ELSE 0
					END
			END
		) AS GrossKW
		
		,SUM(
			CASE
				WHEN RUL > 0
				THEN
					CASE
						WHEN EUL > 0
						THEN Qty * (IRThm * RRThm * Thm1 * RUL + IRThm * RRThm * Thm2 * (EUL - RUL)) / EUL
						ELSE 0
					END
				ELSE
					CASE
						WHEN EUL > 0
						THEN Qty * IRThm * RRThm * Thm1
						ELSE 0
					END
			END
		) AS GrossTherms
		,SUM(
			CASE
				WHEN RUL > 0
				THEN
					CASE
						WHEN EUL > 0
						THEN Qty * (NTGRkWh+@MEBens) * (IRkWh * RRkWh *  kWh1 * RUL + IRkWh * RRkWh *  kWh2 * (EUL - RUL)) / EUL
						ELSE 0
					END
				ELSE
					CASE
						WHEN EUL > 0
						THEN Qty * IRkWh * RRkWh * (NTGRkWh+@MEBens) * kWh1
						ELSE 0
					END
			END
		) AS NetKWh
		,SUM(
			CASE
				WHEN RUL > 0
				THEN
					CASE
						WHEN EUL > 0
						THEN Qty * (NTGRkW+@MEBens) * (IRkW * RRkW * kW1 * RUL + IRkW * RRkW * kW2 * (EUL - RUL)) / EUL
						ELSE 0
					END
				ELSE
					CASE
						WHEN EUL > 0
						THEN Qty * IRkW * RRkW * (NTGRkW+@MEBens) * kW1
						ELSE 0
					END
			END
		) AS NetKW
		,SUM(
			CASE
				WHEN RUL > 0
				THEN
					CASE
						WHEN EUL > 0
						THEN Qty * (NTGRThm+@MEBens) * (IRThm * RRThm * Thm1 * RUL + IRThm * RRThm * Thm2 * (EUL - RUL)) / EUL
						ELSE 0
					END
				ELSE
					CASE
						WHEN EUL > 0
						THEN Qty * IRThm * RRThm * (NTGRThm+@MEBens) * Thm1
						ELSE 0
					END
			END
		) AS NetTherms

		--Note: below are E3-compatible savings equations 
		--, Sum(CASE WHEN IsNull(rul, 0) > 0 THEN CASE WHEN eul > 0 THEN Qty * IR * RR * (kWh1 * Isnull(rul, 0) + kWh2 * (eul - Isnull(rul, 0))) / eul ELSE 0 END ELSE CASE WHEN eul > 0 THEN Qty * IR * RR * kWh1 ELSE 0 END END)
		-- AS GrossKWh

		--, Sum(CASE WHEN IsNull(rul, 0) > 0 THEN CASE WHEN eul > 0 THEN Qty * IR * RR * (kW1 * Isnull(rul, 0) + kW2 * (eul - Isnull(rul, 0))) / eul ELSE 0 END ELSE CASE WHEN eul > 0 THEN Qty * IR * RR * kW1 ELSE 0 END END)
		-- AS GrossKW
		
		--, Sum(CASE WHEN IsNull(rul, 0) > 0 THEN CASE WHEN eul > 0 THEN Qty * IR * RR * (Thm1 * Isnull(rul, 0) + Thm2 * (eul - Isnull(rul, 0))) / eul ELSE 0 END ELSE CASE WHEN eul > 0 THEN Qty * IR * RR * Thm1 ELSE 0 END END)
		-- AS GrossTherms
		
		--, Sum(CASE WHEN IsNull(rul, 0) > 0 THEN CASE WHEN eul > 0 THEN Qty * IR * RR *  (NTGRkWh+@MEBens) * (kWh1 * Isnull(rul, 0) + kWh2 * (eul - Isnull(rul, 0))) / eul ELSE 0 END ELSE CASE WHEN eul > 0 THEN Qty * IR * RR * (NTGRkWh+@MEBens) * kWh1 ELSE 0 END END)
		-- AS NetKWh
		
		--, Sum(CASE WHEN IsNull(rul, 0) > 0 THEN CASE WHEN eul > 0 THEN Qty * IR * RR * (NTGRkW+@MEBens) * (kW1 * Isnull(rul, 0) + kW2 * (eul - Isnull(rul, 0))) / eul ELSE 0 END ELSE CASE WHEN eul > 0 THEN Qty * IR * RR * (NTGRkW+@MEBens) * kW1 ELSE 0 END END)
		-- AS NetKW
		
		--, Sum(CASE WHEN IsNull(rul, 0) > 0 THEN CASE WHEN eul > 0 THEN Qty * IR * RR * (NTGRThm+@MEBens) * (Thm1 * Isnull(rul, 0) + Thm2 * (eul - Isnull(rul, 0))) / eul ELSE 0 END ELSE CASE WHEN eul > 0 THEN Qty * IR * RR * (NTGRThm+@MEBens) * Thm1 ELSE 0 END END)
		-- AS NetTherms

		,SUM(
			CASE WHEN IsNull(rul,0) = 0 AND eul >= 1 THEN
				Qty * eul * IRkWh * RRkWh * kwh1 
			ELSE CASE WHEN IsNull(rul,0) > 0 AND eul >= 1 THEN
				Qty * eul * IRkWh * RRkWh * (kwh1*Isnull(rul,0) + kwh2*(eul-Isnull(rul,0)))/eul 
			ELSE CASE WHEN IsNull(rul,0) = 0 AND eul < 1 THEN
				Qty * EUL * IRkWh * RRkWh * kwh1 
			ELSE 
				Qty * IRkWh * RRkWh * (rul * kwh1 + eul * kwh2) 
			END END END) AS LifecycleGrossKWh
		
		,SUM(
			CASE WHEN IsNull(rul,0) = 0 AND eul >= 1 THEN
				Qty * eul * IRThm * RRThm * Thm1 
			ELSE CASE WHEN IsNull(rul,0) > 0 AND eul >= 1 THEN
				Qty * eul * IRThm * RRThm * (Thm1*Isnull(rul,0) + Thm2*(eul-Isnull(rul,0)))/eul 
			ELSE CASE WHEN IsNull(rul,0) = 0 AND eul < 1 THEN
				Qty * EUL * IRThm * RRThm * Thm1 
			ELSE 
				Qty * IRThm * RRThm * (RUL * Thm1 + EUL * Thm2) 
			END END END) AS LifecycleGrossTherms
		
		,SUM(
			CASE WHEN IsNull(rul,0) = 0 AND eul >= 1 THEN
				Qty * (NTGRkWh+@MEBens) * eul * IRkWh * RRkWh * kwh1 
			ELSE CASE WHEN IsNull(rul,0) > 0 AND eul >= 1 THEN
				Qty * (NTGRkWh+@MEBens) * eul * IRkWh * RRkWh * (kwh1*Isnull(rul,0) + kwh2*(eul-Isnull(rul,0)))/eul 
			ELSE CASE WHEN IsNull(rul,0) = 0 AND eul < 1 THEN
				Qty * (NTGRkWh+@MEBens) * eul * IRkWh * RRkWh * kwh1 
			ELSE 
				Qty * (NTGRkWh+@MEBens) * IRkWh * RRkWh * (rul * kwh1 + eul * kwh2) 
			END END END) AS LifecycleNetKWh
		
		,SUM(
			CASE WHEN IsNull(rul,0) = 0 AND eul >= 1 THEN
				Qty * (NTGRThm+@MEBens) * eul * IRThm * RRThm * Thm1 
			ELSE CASE WHEN IsNull(rul,0) > 0 AND eul >= 1 THEN
				Qty * (NTGRThm+@MEBens) * eul * IRThm * RRThm * (Thm1*Isnull(rul,0) + Thm2*(eul-Isnull(rul,0)))/eul 
			ELSE CASE WHEN IsNull(rul,0) = 0 AND eul < 1 THEN
				Qty * (NTGRThm+@MEBens) * eul * IRThm * RRThm * Thm1 
			ELSE 
				Qty * (NTGRThm+@MEBens) * IRThm * RRThm * (rul * Thm1 + eul * Thm2) 
			END END END) AS LifecycleNetTherms
		

--*****************  Goal Attainment   ******************************************
		, SUM(CASE WHEN eul > 1 THEN 1 ELSE eul END * Qty * IRkWh * RRkWh * kWh1)
		 AS GoalAttainmentKWh

		, SUM(CASE WHEN eul > 1 THEN 1 ELSE eul END * Qty * IRkW * RRkW * kW1)
		 AS GoalAttainmentKW

		, SUM(CASE WHEN eul > 1 THEN 1 ELSE eul END * Qty * IRThm * RRThm * Thm1)
		 AS GoalAttainmentThm


--*****************  First Year Savings   ******************************************
	,SUM(CASE WHEN IsNull(RUL, 0) >= 1 THEN 1
		WHEN RUL > 0 AND RUL <= 1 THEN RUL
		WHEN RUL = 0 AND EUL >= 1 THEN 1
		ELSE 1 END * Qty * IRkWh * RRkWh * kWh1 
		+ CASE WHEN RUL > 0 AND RUL <= 1 AND EUL < 1 THEN EUL - RUL
		WHEN RUL > 0 AND RUL <= 1 AND (RUL + EUL) >= 1 THEN 1 - RUL
		ELSE 0 END * Qty * IRkWh * RRkWh * kWh2
		) AS FirstYearGrossKWh

	,SUM(CASE WHEN RUL >= 1 THEN 1
		WHEN RUL > 0 AND RUL <= 1 THEN RUL
		WHEN RUL = 0 AND EUL >= 1 THEN 1 
		ELSE 1 END * Qty * IRkW * RRkW * kW1 
		+ CASE WHEN RUL > 0 AND RUL <= 1 AND EUL < 1 THEN EUL - RUL
		WHEN RUL > 0 AND RUL <= 1 AND (RUL + EUL) >= 1 THEN 1 - RUL
		ELSE 0 END * Qty * IRkW * RRkW * kW2) AS FirstYearGrossKW

	,SUM(CASE WHEN RUL >= 1 THEN 1
		WHEN RUL > 0 AND RUL <= 1 THEN RUL
		WHEN RUL = 0 AND EUL >= 1 THEN 1 
		ELSE 1 END * Qty * IRThm * RRThm * Thm1 
		+ CASE WHEN RUL > 0 AND RUL <= 1 AND EUL < 1 THEN EUL - RUL
		WHEN RUL > 0 AND RUL <= 1 AND (RUL + EUL) >= 1 THEN 1 - RUL
		ELSE 0 END * Qty * IRThm * RRThm * Thm2) AS FirstYearGrossThm

	,SUM(CASE WHEN RUL >= 1 THEN 1
		WHEN RUL > 0 AND RUL <= 1 THEN RUL
		WHEN RUL = 0 AND EUL >= 1 THEN 1
		ELSE 1 END * Qty * (NTGRkWh+@MEBens) * IRkWh * RRkWh * kWh1 
		+ CASE WHEN RUL > 0 AND RUL <= 1 AND EUL < 1 THEN EUL - RUL
		WHEN RUL > 0 AND RUL <= 1 AND (RUL + EUL) >= 1 THEN 1 - RUL
		ELSE 0 END * Qty * (NTGRkWh+@MEBens) * IRkWh * RRkWh * kWh2) AS FirstYearNetKWh

	,SUM(CASE WHEN RUL >= 1 THEN 1
		WHEN RUL > 0 AND RUL <= 1 THEN RUL
		WHEN RUL = 0 AND EUL >= 1 THEN 1 
		ELSE 1 END * Qty * (NTGRkW+@MEBens) * IRkW * RRkW * kW1 
		+ CASE WHEN RUL > 0 AND RUL <= 1 AND EUL < 1 THEN EUL - RUL
		WHEN RUL > 0 AND RUL <= 1 AND (RUL + EUL) >= 1 THEN 1 - RUL
		ELSE 0 END * Qty * (NTGRkW+@MEBens) * IRkW * RRkW * kW2) AS FirstYearNetKW

	,SUM(CASE WHEN RUL >= 1 THEN 1
		WHEN RUL > 0 AND RUL <= 1 THEN RUL
		WHEN RUL = 0 AND EUL >= 1 THEN 1 
		ELSE 1 END * Qty * (NTGRThm+@MEBens) * IRThm * RRThm * Thm1 
		+ CASE WHEN RUL > 0 AND RUL <= 1 AND EUL < 1 THEN EUL - RUL
		WHEN RUL > 0 AND RUL <= 1 AND (RUL + EUL) >= 1 THEN 1 - RUL
		ELSE 0 END * Qty * (NTGRThm+@MEBens) * IRThm * RRThm * Thm2) AS FirstYearNetThm

	--,Sum(CASE WHEN RUL >= 1 THEN 1
	--	WHEN RUL > 0 AND IsNull(RUL, 0) <= 1 THEN RUL
	--	WHEN RUL = 0 AND EUL >= 1 THEN 1
	--	ELSE 1 END * Qty * (NTGRkWh+@MEBens) * IRkWh * RRkWh * kWh1 
	--	+ CASE WHEN RUL > 0 AND RUL <= 1 THEN 1 - RUL
	--	ELSE 0 END * Qty * (NTGRkWh+@MEBens) * IRkWh * RRkWh * kWh2) AS FirstYearNetKWh

	--,Sum(CASE WHEN IsNull(RUL, 0) >= 1 THEN 1 
	--	WHEN IsNull(RUL, 0) > 0 AND IsNull(RUL, 0) <= 1 THEN RUL
	--	WHEN RUL = 0 AND EUL >= 1 THEN 1
	--	ELSE 1 END * Qty * (NTGRkW+@MEBens) * IRkW * RRkW * kW1 
	--	+ CASE WHEN RUL > 0 AND RUL <= 1 THEN 1 - RUL
	--	ELSE 0 END * Qty * (NTGRkW+@MEBens) * IRkW * RRkW * kW2) AS FirstYearNetKW

	--,Sum(CASE WHEN IsNull(RUL, 0) >= 1 THEN 1
	--	WHEN IsNull(RUL, 0) > 0 AND IsNull(RUL, 0) <= 1 THEN RUL
	--	WHEN RUL = 0 AND EUL >= 1 THEN 1
	--	ELSE 1 END * Qty * (NTGRThm+@MEBens) * IRThm * RRThm * Thm1 
	--	+ CASE WHEN RUL > 0 AND RUL <= 1 THEN 1 - RUL
	--	ELSE 0 END * Qty * (NTGRThm+@MEBens) * IRThm * RRThm * Thm2) AS FirstYearNetThm

----*****************  First Year Savings OLD  ******************************************
--	,Sum(CASE WHEN IsNull(RUL, 0) >= 1 THEN 1
--		WHEN IsNull(RUL, 0) > 0 AND IsNull(RUL, 0) <= 1 THEN RUL
--		WHEN RUL = 0 AND EUL >= 1 THEN 1
--		ELSE 1 END * Qty * IRkWh * RRkWh * kWh1 
--	 + CASE WHEN RUL > 0 AND RUL <= 1 THEN 1 - RUL
--		ELSE 0 END * Qty * IRkWh * RRkWh * kWh2) AS FirstYearGrossKWh

--	,Sum(CASE WHEN IsNull(RUL, 0) >= 1 THEN 1
--		WHEN IsNull(RUL, 0) > 0 AND IsNull(RUL, 0) <= 1 THEN RUL
--		WHEN RUL = 0 AND EUL >= 1 THEN 1 
--		ELSE 1 END * Qty * IRkW * RRkW * kW1 
--		+ CASE WHEN RUL > 0 AND RUL <= 1 THEN 1 - RUL
--		ELSE 0 END * Qty * IRkW * RRkW * kW2) AS FirstYearGrossKW

--	,Sum(CASE WHEN IsNull(RUL, 0) >= 1 THEN 1
--		WHEN IsNull(RUL, 0) > 0 AND IsNull(RUL, 0) <= 1 THEN RUL
--		WHEN RUL = 0 AND EUL >= 1 THEN 1
--		ELSE 1 END * Qty * IRThm * RRThm * Thm1 
--		+ CASE WHEN RUL > 0 AND RUL <= 1 THEN 1 - RUL
--		ELSE 0 END * Qty * IRThm * RRThm * Thm2) AS FirstYearGrossThm

--	,Sum(CASE WHEN IsNull(RUL, 0) >= 1 THEN 1
--		WHEN IsNull(RUL, 0) > 0 AND IsNull(RUL, 0) <= 1 THEN RUL
--		WHEN RUL = 0 AND EUL >= 1 THEN 1
--		ELSE 1 END * Qty * (NTGRkWh+@MEBens) * IRkWh * RRkWh * kWh1 
--		+ CASE WHEN RUL > 0 AND RUL <= 1 THEN 1 - RUL
--		ELSE 0 END * Qty * (NTGRkWh+@MEBens) * IRkWh * RRkWh * kWh2) AS FirstYearNetKWh

--	,Sum(CASE WHEN IsNull(RUL, 0) >= 1 THEN 1 
--		WHEN IsNull(RUL, 0) > 0 AND IsNull(RUL, 0) <= 1 THEN RUL
--		WHEN RUL = 0 AND EUL >= 1 THEN 1
--		ELSE 1 END * Qty * (NTGRkW+@MEBens) * IRkW * RRkW * kW1 
--		+ CASE WHEN RUL > 0 AND RUL <= 1 THEN 1 - RUL
--		ELSE 0 END * Qty * (NTGRkW+@MEBens) * IRkW * RRkW * kW2) AS FirstYearNetKW

--	,Sum(CASE WHEN IsNull(RUL, 0) >= 1 THEN 1
--		WHEN IsNull(RUL, 0) > 0 AND IsNull(RUL, 0) <= 1 THEN RUL
--		WHEN RUL = 0 AND EUL >= 1 THEN 1
--		ELSE 1 END * Qty * (NTGRThm+@MEBens) * IRThm * RRThm * Thm1 
--		+ CASE WHEN RUL > 0 AND RUL <= 1 THEN 1 - RUL
--		ELSE 0 END * Qty * (NTGRThm+@MEBens) * IRThm * RRThm * Thm2) AS FirstYearNetThm

	FROM InputMeasurevw e
	
	GROUP BY e.PA
		,e.PrgID
		,e.CET_ID
	ORDER BY e.PA
		,e.PrgID
		,e.CET_ID

END

-- Calculate WeightedSavings
BEGIN
WITH SavingsSum (
	  PrgID
	, SumkWh
	, SumThm
)
AS (
	SELECT PrgID
		,SUM(CASE 
				WHEN FirstYearGrossKWh > 0
					THEN FirstYearGrossKWh
				ELSE 0
				END) AS SumkWh
		,SUM(CASE 
				WHEN FirstYearGrossThm > 0
					THEN @ThermConv * FirstYearGrossThm
				ELSE 0
				END) AS SumThm
	FROM #OutputSavings
	GROUP BY PrgID
)
, RecordCount (
	  PrgID
	, RecordCount
)
AS 
(
	SELECT PrgID
		,COUNT(CET_ID) AS RecordCount
	FROM #OutputSavings
	GROUP BY PrgID
)
, WeightedSavings (
	  CET_ID
	, WeightedSavings
)
AS 
(
	SELECT	CET_ID
		,CASE 
			WHEN (ss.SumkWh <> 0 OR ss.SumThm <> 0)
				THEN (
						CASE 
							WHEN FirstYearGrossKWh > 0
								THEN FirstYearGrossKWh
							ELSE 0
							END 
							+ CASE 
							WHEN FirstYearGrossThm > 0
								THEN @ThermConv * FirstYearGrossThm
							ELSE 0
							END
						) / (ss.SumkWh + ss.SumThm)
			ELSE 
				1.000 / cc.RecordCount -- If no benefits then divide program costs evenly among claims
			END  AS WeightedSavings
	FROM  #OutputSavings s
	LEFT JOIN SavingsSum ss ON s.PrgID = ss.PrgID
	LEFT JOIN RecordCount cc ON  s.PrgID = cc.PrgID
) 

UPDATE  s SET s.WeightedSavings = ws.WeightedSavings
FROM WeightedSavings ws
LEFT JOIN #OutPutSavings s ON ws.CET_ID = s.CET_ID

END

DELETE FROM OutputSavings WHERE JobID = @JobID
DELETE FROM SavedSavings WHERE JobID = @JobID

--Insert final output
INSERT INTO OutputSavings
SELECT 
      [JobID]
      ,[PA]
      ,[PrgID]
      ,[CET_ID]
      ,[GrossKWh]
      ,[GrossKW]
      ,[GrossThm]
      ,[NetKWh]
      ,[NetKW]
      ,[NetThm]
      ,[LifecycleGrossKWh]
      ,[LifecycleGrossThm]
      ,[LifecycleNetKWh]
      ,[LifecycleNetThm]
	  ,GoalAttainmentkWh
	  ,GoalAttainmentkW
	  ,GoalAttainmentThm
      ,[FirstYearGrossKWh]
      ,[FirstYearGrossKW]
      ,[FirstYearGrossThm]
      ,[FirstYearNetKWh]
      ,[FirstYearNetKW]
      ,[FirstYearNetThm]
	  ,[WeightedSavings]
  FROM [#OutputSavings]

--PRINT 'Done!'








GO


