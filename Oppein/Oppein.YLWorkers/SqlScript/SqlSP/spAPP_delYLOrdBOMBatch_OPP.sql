/*
	批量处理BOM的挑板与删板功能
	注意：自定义类型mOrdTableType_OPP actions 的值为2、3、4（1为添加、3为删除、4为修改）
*/

ALTER PROC [dbo].[spAPP_delYLOrdBOMBatch_OPP]
	@ordID INT
    ,@YLOrdItmTable YLOrdDelTableType_OPP READONLY
AS 
SET NOCOUNT ON;
--判断，
IF EXISTS(SELECT 1 FROM tempdb.dbo.sysobjects WHERE id=OBJECT_ID(N'tempdb..#oriData')AND type='U')
BEGIN
	--删除临时表
	DROP TABLE #oriData
END
CREATE TABLE #oriData
(
	itmID INT NOT NULL
	,itmIDInstance SMALLINT NOT NULL
	,olnID INT NOT NULL
	,olnIDInstance SMALLINT NOT NULL
	,itmIDParent INT
	,itmIDParentInstance SMALLINT
	,oriReqQty DECIMAL(18,2) NOT NULL
	,dlCode NCHAR(2) NOT NULL
	,oriLevel TINYINT NOT NULL
	,oriNode BIT DEFAULT 0		--数据处理标记(0表示未处理，1表示已处理且用户操作数据，NULL 表示数据已处理)
	,oriAction TINYINT 			--操作标记（3 删除 2 添加 null 不作操作 22 表示添加子品项，23表示删除了品项）
	,itmIDSA INT
	,WhileRow SMALLINT
	,PRIMARY KEY(itmID,itmIDInstance,olnID,olnIDInstance)
	,INDEX IX_Parent(itmIDParent,itmIDParentInstance,olnID,olnIDInstance)
	,INDEX IX_dlCode(dlCode)
	,INDEX IX_oriLevel_oriNode(oriLevel,oriNode)
	,INDEX IX_oriAction(oriAction)
	,INDEX IX_oriAction_WhileRow(oriAction,WhileRow)
)
INSERT INTO #oriData(itmID,itmIDInstance,olnID,olnIDInstance,itmIDParent,itmIDParentInstance,oriReqQty,dlCode,oriLevel)
SELECT 
	ori.itmID
	,ori.itmIDInstance
	,ori.olnID
	,ori.olnIDInstance
	,ori.itmIDParent
	,ori.itmIDParentInstance
	,ori.oriReqQty
	,ori.dlCode 
	,ori.oriLevel
FROM dbo.OrderLines oln WITH(NOLOCK)
JOIN dbo.OrderItems ori WITH(NOLOCK) ON ori.olnID = oln.olnID
WHERE oln.ordID=@ordID

--第0层级SA层、第1层级SA下层，第2层级MA下的MP层级，第3层级最一层级
--处理第1层及其下层的非五金类物料
;WITH T AS
(
	SELECT 
		 ori.itmID
		,ori.itmIDInstance
		,ori.olnID
		,ori.olnIDInstance
		,ori.itmIDParent
		,ori.itmIDParentInstance
		,ori.itmIDParent AS itmIDSA
		--,ori.dlCode
		--,ori.oriLevel
		,1 AS oriNode
	FROM #oriData ori
	JOIN @YLOrdItmTable YLOrd ON YLOrd.itmID = ori.itmID
		AND YLOrd.itmIDInstance = ori.itmIDInstance
		AND YLOrd.olnID = ori.olnID
		AND YLOrd.olnIDInstance = ori.olnIDInstance
	WHERE ori.oriLevel= 1
		AND ori.oriNode = 0
),TT AS
(
SELECT 
	oriC.itmID
	,oriC.itmIDInstance
	,oriC.olnID
	,oriC.olnIDInstance
	,oriC.itmIDParent
	,oriC.itmIDParentInstance
	,t.itmIDSA
	--,oriC.dlCode
	--,oriC.oriLevel
	,(CASE WHEN YLOrd.itmID IS NOT NULL AND YLOrd.itmIDInstance IS NOT NULL AND YLOrd.olnID IS NOT NULL AND YLOrd.olnIDInstance IS NOT NULL
		THEN 1 END) AS oriNode	
	,(CASE WHEN YLOrd.itmID IS NOT NULL AND YLOrd.itmIDInstance IS NOT NULL AND YLOrd.olnID IS NOT NULL AND YLOrd.olnIDInstance IS NOT NULL
		THEN NULL ELSE 3 END)AS oriAction
FROM T t
JOIN #oriData oriC ON oriC.itmIDParent=t.itmID
	AND oriC.itmIDParentInstance=t.itmIDInstance
	AND oriC.olnID=t.olnID
	AND oriC.olnIDInstance=t.olnIDInstance
LEFT JOIN @YLOrdItmTable YLOrd ON YLOrd.itmID = oriC.itmID
		AND YLOrd.itmIDInstance = oriC.itmIDInstance
		AND YLOrd.olnID = oriC.olnID
		AND YLOrd.olnIDInstance = oriC.olnIDInstance
UNION ALL
SELECT 
	t.itmID
	,t.itmIDInstance
	,t.olnID
	,t.olnIDInstance
	,t.itmIDParent
	,t.itmIDParentInstance
	,t.itmIDSA
	--,t.dlCode
	--,t.oriLevel
	,t.oriNode
	,NULL AS oriAction
FROM T t
)
UPDATE ori SET ori.oriNode=tt.oriNode,ori.oriAction=tt.oriAction,ori.itmIDSA=tt.itmIDSA
FROM TT tt
JOIN #oriData ori ON tt.itmID=ori.itmID
	AND tt.itmIDInstance=ori.itmIDInstance
	AND tt.olnID=ori.olnID
	AND tt.olnIDInstance=ori.olnIDInstance

--处理第2层及其下层非五金物料
;WITH T AS
(
	SELECT 
		 ori.itmID
		,ori.itmIDInstance
		,ori.olnID
		,ori.olnIDInstance
		,ori.itmIDParent
		,ori.itmIDParentInstance
		,oriSA.itmID AS itmIDSA
		--,ori.dlCode
		--,ori.oriLevel
		,0 AS oriNode
	FROM #oriData ori
	JOIN @YLOrdItmTable YLOrd ON YLOrd.itmID = ori.itmID
		AND YLOrd.itmIDInstance = ori.itmIDInstance
		AND YLOrd.olnID = ori.olnID
		AND YLOrd.olnIDInstance = ori.olnIDInstance
	JOIN #oriData oriSA ON oriSA.dlCode=N'SA' AND oriSA.olnID=ori.olnID AND oriSA.olnIDInstance=ori.olnIDInstance
	WHERE ori.oriLevel= 2
		AND ori.oriNode = 0
),TT AS
(
SELECT 
	oriP.itmID
	,oriP.itmIDInstance
	,oriP.olnID
	,oriP.olnIDInstance
	,oriP.itmIDParent
	,oriP.itmIDParentInstance
	,t.itmIDSA
	--,oriP.dlCode
	--,oriP.oriLevel
	,NULL AS oriNode
	,3 AS oriAction
	,ROW_NUMBER()OVER(PARTITION BY oriP.itmID,oriP.itmIDInstance,oriP.olnID,oriP.olnIDInstance ORDER BY GETDATE())AS RowID
FROM T t
JOIN #oriData oriP ON oriP.itmID=t.itmIDParent
	AND oriP.itmIDInstance=t.itmIDParentInstance
	AND oriP.olnID=t.olnID
	AND oriP.olnIDInstance=t.olnIDInstance
WHERE oriP.oriLevel = 1		--层级2上级为1
	AND oriP.oriNode = 0
UNION ALL
SELECT 
	t.itmID
	,t.itmIDInstance
	,t.olnID
	,t.olnIDInstance
	,t.itmIDParent
	,t.itmIDParentInstance
	,t.itmIDSA
	--,t.dlCode
	--,t.oriLevel
	,t.oriNode
	,2 AS oriAction
	,1 AS RowID
FROM T t
UNION ALL
SELECT 
	oriC.itmID
	,oriC.itmIDInstance
	,oriC.olnID
	,oriC.olnIDInstance
	,oriC.itmIDParent
	,oriC.itmIDParentInstance
	,t.itmIDSA
	--,oriC.dlCode
	--,oriC.oriLevel
	,(CASE WHEN YLOrd.itmID IS NOT NULL AND YLOrd.itmIDInstance IS NOT NULL AND YLOrd.olnID IS NOT NULL AND YLOrd.olnIDInstance IS NOT NULL
		THEN 1 END) AS oriNode
	,(CASE WHEN YLOrd.itmID IS NOT NULL AND YLOrd.itmIDInstance IS NOT NULL AND YLOrd.olnID IS NOT NULL AND YLOrd.olnIDInstance IS NOT NULL
		THEN 22 ELSE 23 END)AS oriAction
	,1 AS RowID
FROM T t
JOIN #oriData oriC ON oriC.itmIDParent=t.itmID
	AND oriC.itmIDParentInstance=t.itmIDInstance
	AND oriC.olnID=t.olnID
	AND oriC.olnIDInstance=t.olnIDInstance
LEFT JOIN @YLOrdItmTable YLOrd ON YLOrd.itmID = oriC.itmID
		AND YLOrd.itmIDInstance = oriC.itmIDInstance
		AND YLOrd.olnID = oriC.olnID
		AND YLOrd.olnIDInstance = oriC.olnIDInstance
WHERE oriC.oriLevel = 3			--层级2下级为3
	AND oriC.oriNode = 0
)
UPDATE ori SET ori.oriNode=tt.oriNode,ori.oriAction=tt.oriAction,ori.itmIDSA=tt.itmIDSA
FROM TT tt
JOIN #oriData ori ON tt.itmID=ori.itmID
	AND tt.itmIDInstance=ori.itmIDInstance
	AND tt.olnID=ori.olnID
	AND tt.olnIDInstance=ori.olnIDInstance
WHERE tt.RowID=1

--处理第3层
-- 3.1 处理非五金类
;WITH T AS
(
	SELECT 
		 ori.itmID
		,ori.itmIDInstance
		,ori.olnID
		,ori.olnIDInstance
		,ori.itmIDParent
		,ori.itmIDParentInstance
		,oriSA.itmID AS itmIDSA
		--,ori.dlCode
		--,ori.oriLevel
		,1 AS oriNode
	FROM #oriData ori
	JOIN @YLOrdItmTable YLOrd ON YLOrd.itmID = ori.itmID
		AND YLOrd.itmIDInstance = ori.itmIDInstance
		AND YLOrd.olnID = ori.olnID
		AND YLOrd.olnIDInstance = ori.olnIDInstance
	JOIN #oriData oriSA ON oriSA.dlCode=N'SA' AND oriSA.olnID=ori.olnID AND oriSA.olnIDInstance=ori.olnIDInstance
	WHERE ori.oriLevel= 3
		AND ori.oriNode = 0
),TT AS
(
SELECT
	oriP.itmID
	,oriP.itmIDInstance
	,oriP.olnID
	,oriP.olnIDInstance
	,oriP.itmIDParent
	,oriP.itmIDParentInstance
	,t.itmIDSA
	--,oriP.dlCode
	--,oriP.oriLevel
	,NULL AS oriNode
	,3 AS oriAction
	,ROW_NUMBER()OVER(PARTITION BY oriP.itmID,oriP.itmIDInstance,oriP.olnID,oriP.olnIDInstance ORDER BY GETDATE())AS RowID
FROM T t
JOIN #oriData oriP ON oriP.itmID=t.itmIDParent
	AND oriP.itmIDInstance=t.itmIDParentInstance
	AND oriP.olnID=t.olnID
	AND oriP.olnIDInstance=t.olnIDInstance
WHERE oriP.oriLevel = 2			--层级3的上级为2
	AND oriP.oriNode = 0
UNION ALL
SELECT 
	t.itmID
	,t.itmIDInstance
	,t.olnID
	,t.olnIDInstance
	,t.itmIDParent
	,t.itmIDParentInstance
	,t.itmIDSA
	--,t.dlCode
	--,t.oriLevel
	,t.oriNode
	,2 AS oriAction
	,1 AS RowID
FROM T t
)
UPDATE ori SET ori.oriNode=tt.oriNode,ori.oriAction=tt.oriAction,ori.itmIDSA=tt.itmIDSA
FROM TT tt
JOIN #oriData ori ON tt.itmID=ori.itmID
	AND tt.itmIDInstance=ori.itmIDInstance
	AND tt.olnID=ori.olnID
	AND tt.olnIDInstance=ori.olnIDInstance
WHERE tt.RowID=1

--处理 五金类
;WITH T AS
(
SELECT 
	 org.itmID
	,org.itmIDInstance
	,org.olnID
	,org.olnIDInstance
	,org.itmIDSA
	,1 AS oriNode
	,NULL AS oriAction
FROM @YLOrdItmTable YLOrd
JOIN dbo.CUS_YLOrdOriginalBOMData_OPP org WITH(NOLOCK) ON org.itmID=YLOrd.olnID
WHERE YLOrd.itmIDInstance IS NULL
	AND org.ordId=@ordID
	AND org.itmIDParent=org.itmIDSA
),TT AS
(
SELECT 
	CAST(org.info3 AS INT) AS itmID
	,CAST(org.info4 AS SMALLINT) AS itmIDInstance
	,org.olnID
	,org.olnIDInstance
	,org.itmIDSA
	,1 AS oriNode
	,NULL AS oriAction
FROM @YLOrdItmTable YLOrd
JOIN dbo.CUS_YLOrdOriginalBOMData_OPP org WITH(NOLOCK) ON org.itmID=YLOrd.olnID
	AND org.info2=YLOrd.info2
WHERE YLOrd.itmIDInstance IS NULL
	AND org.ordId=@ordID
	AND NOT EXISTS(SELECT 1 FROM T t WHERE org.itmID=t.itmID AND org.itmIDInstance=t.itmIDInstance AND org.olnID=t.olnID AND org.olnIDInstance=t.olnIDInstance)
	AND org.info2 IS NOT NULL
	AND ISNUMERIC(org.info3)=1
	AND ISNUMERIC(org.info4)=1
UNION ALL
SELECT 
	org.itmID
	,org.itmIDInstance
	,org.olnID
	,org.olnIDInstance
	,org.itmIDSA
	,1 AS oriNode
	,(CASE WHEN oriP.oriNode=0 THEN 2 ELSE 
		(CASE WHEN oriP.oriAction IS NULL THEN NULL WHEN oriP.oriAction=2 THEN 22 ELSE 2 END) 
	END) AS oriAction
FROM @YLOrdItmTable YLOrd
JOIN dbo.CUS_YLOrdOriginalBOMData_OPP org WITH(NOLOCK) ON org.itmID=YLOrd.olnID
JOIN #oriData oriP ON oriP.itmID=org.itmIDParent
	AND oriP.itmIDInstance=org.itmIDParentInstance
	AND oriP.olnID=org.olnID
	AND oriP.olnIDInstance=org.olnIDInstance
WHERE YLOrd.itmIDInstance IS NULL
	AND org.ordId=@ordID
	AND NOT EXISTS(SELECT 1 FROM T t WHERE org.itmID=t.itmID AND org.itmIDInstance=t.itmIDInstance AND org.olnID=t.olnID AND org.olnIDInstance=t.olnIDInstance)
	AND org.info2 IS NULL
UNION ALL
SELECT 
	t.itmID
	,t.itmIDInstance
	,t.olnID
	,t.olnIDInstance
	,t.itmIDSA
	,t.oriNode
	,t.oriAction 
FROM T t
)
UPDATE ori SET ori.oriNode=tt.oriNode,ori.oriAction=tt.oriAction,ori.itmIDSA=tt.itmIDSA
FROM TT tt
JOIN #oriData ori ON tt.itmID=ori.itmID
	AND tt.itmIDInstance=ori.itmIDInstance
	AND tt.olnID=ori.olnID
	AND tt.olnIDInstance=ori.olnIDInstance

--处理第一层级，无操作数据情况
UPDATE #oriData SET oriAction=3,itmIDSA=itmIDParent WHERE oriLevel = 1 AND oriNode = 0 

-- 数据处理时循环使用
;WITH T AS
(
	SELECT 
		ROW_NUMBER()OVER(ORDER BY ori.olnID) AS RowID
		,ori.itmID
		,ori.itmIDInstance
		,ori.olnID
		,ori.olnIDInstance
	FROM #oriData ori
	WHERE ori.oriAction = 2
	UNION ALL
	SELECT 
		ROW_NUMBER()OVER(ORDER BY ori.olnID) AS RowID
		,ori.itmID
		,ori.itmIDInstance
		,ori.olnID
		,ori.olnIDInstance
	FROM #oriData ori
	WHERE ori.oriAction = 3
)
UPDATE ori SET ori.WhileRow=t.RowID
FROM T t 
JOIN #oriData ori ON ori.itmID = t.itmID
	AND ori.itmIDInstance = t.itmIDInstance
	AND ori.olnID = t.olnID
	AND ori.olnIDInstance = t.olnIDInstance

--公共参数
DECLARE @WhileRow SMALLINT =1 ,@WhileCount SMALLINT,@itmID INT,@itmIDInstance SMALLINT,@olnID INT,@olnIDInstance SMALLINT,@itmIDSA INT,@itmIDNew INT,@oriReqQty DECIMAL(18,2),@primaryUOMCode NCHAR(5),@AsOfDate datetime =GETDATE()

BEGIN TRY

	--开启事务
	BEGIN TRANSACTION

	--数据处理时先删除再加
	SELECT @WhileCount=MAX(ori.WhileRow) FROM #oriData ori WHERE ori.oriAction = 3
	IF @WhileCount>0
	BEGIN
		SET @WhileRow = 1;
		WHILE @WhileRow < (@WhileCount + 1)
		BEGIN
			SELECT 
				 @itmID = ori.itmID
				 ,@itmIDInstance = ori.itmIDInstance
				 ,@olnID = ori.olnID
				 ,@olnIDInstance = ori.olnIDInstance
				 ,@oriReqQty = ori.oriReqQty
				 ,@primaryUOMCode = itm.PrimaryUOMCode
				 ,@itmIDNew = ori.itmID
				 ,@itmIDSA = ori.itmIDSA
			FROM #oriData ori 
			JOIN dbo.Items itm WITH(NOLOCK) ON itm.itmID = ori.itmID
			WHERE ori.oriAction = 3 
				AND ori.WhileRow = @WhileRow
			--执行删除BOM操作
			EXEC dbo.spAPP_utlProcessOrderItemEditing 
				@olnID=@olnID
				,@olnIDInstance=@olnIDInstance
				,@itmID=@itmID
				,@itmIDInstance=@itmIDInstance
				,@Action=3
				,@itmIDNew=@itmIDNew
				,@oriReqQtyNew=@oriReqQty
				,@PrimaryUOMCode=@primaryUOMCode
				,@TransUOMCodeNew=@primaryUOMCode
				,@rotID=NULL
				,@rotIDNew=NULL
				,@itmIDpdv=NULL
				,@itmIDTop=@itmIDSA	--Use the SA level ori instance
				,@AsOfDate=@AsOfDate
				-- configuration settings
				,@EnableAllocationReassignments = 0
				,@EnableCustomProperties  = 1
				,@EnableSurfaceAlternates  = 1
				,@EnableParametricDimensions  = 1
				,@EnablePurchasedDemandReassignments  = 0
				,@EnableConditionalComponents  = 1
				,@EnableImpliedComponents  = 1
				,@EnableCriteriaMatchReplacementParts  = 1
				,@EnableExactComponentMatchReplacementParts  = 1
				,@EnableConfiguredItemReplacementParts  = 1
				,@EnableRoutingReassignments = 2
				,@EnableMultiLevelRoutingReassignments  = 0
				,@EnableConditionalOperations  = 1
				,@EnableProcessedCostComputation  = 0
				,@EnableOutsourcedOperations  = 0
				,@EnableRollupBOMMatching  = 0 -- Enable Rollup BOM Match Processing. [0] = False, [1] = Match, [2] = Match and Purge
				,@EnableOrderItemBackscheduleComputation  = 1
				,@EnableProcessGroupFillFactor  = 0
				-- additional parameter-matched setting values used in processing
				,@MaxBOMProcessingIterations  = 20 -- Maximum [number] of iterations when performing iterative BOM processing.
				,@WorkOrderStartDateCalculationMethod  = 0 -- Determines the technique used to calculate Work Order Start Date: [0] - Process Group Offset, [1] - Operation Schedule Offset
				,@InitialOrderItemStatusValue  = 11000 -- Initial [Status Value] for Order Items
				,@EnableBOMDebugInfoLogging  = 0 -- Enables debug info logging in Application Log during BOM Processing. [0] = False, [1] = True
				,@MaxItemEdgesInCriteriaProperties  = 4 -- Maximum [number] of item edges to process in Criteria Property processing.
				,@InitialOrderLineInstanceStatusValue  = 1000
				,@FirmedOrderLineInstanceStatusValue = 1200
				,@DefaultSARoutingCode  = 15100
				,@WorkOrderStartDateOperationScheduleOffsetMode  = 1 -- Determines the technique used to calculate Operation Schedule Offset Work Order Start Date: [0] - Time Optimized,[1] - Yield Optimized
				,@CLRDebugMode  = default -- Sets flag to produce extended textual processing logging. See CLR SP call below for more.
				,@OutputCLRDebugging  = default -- When CLR Debug Mode is set and this code is run from SQL Server Management Studio, it prints and outputs log.
		
			SET @WhileRow += 1;
		END
	END

	SELECT @WhileCount=MAX(ori.WhileRow) FROM #oriData ori WHERE ori.oriAction = 2
	IF @WhileCount>0
	BEGIN
		--定义组件表
		DECLARE @CompItmData TABLE(itmID INT,compItmID INT,itmcEffective DATE,itmcInactive DATE,itmcQty DECIMAL(19,4),PRIMARY KEY(itmID,compItmID,itmcEffective))

		SET @WhileRow = 1;
		WHILE @WhileRow < (@WhileCount + 1)
		BEGIN
			SELECT 
				 @itmID = addOri.itmIDSA
				 ,@itmIDInstance = 1
				 ,@olnID = addOri.olnID
				 ,@olnIDInstance = addOri.olnIDInstance
				 ,@oriReqQty = addOri.oriReqQty
				 ,@primaryUOMCode = itm.PrimaryUOMCode
				 ,@itmIDNew = addOri.itmID
				 ,@itmIDSA = addOri.itmIDSA
			FROM #oriData addOri 
			JOIN dbo.Items itm WITH(NOLOCK) ON itm.itmID = addOri.itmID
			WHERE addOri.oriAction = 2
				AND addOri.WhileRow = @WhileRow
			--先删除再添加
			DELETE FROM @CompItmData
			INSERT INTO @CompItmData( itmID ,compItmID ,itmcEffective ,itmcInactive ,itmcQty)
			SELECT 
				itmC.itmID
				,itmC.CompItmID
				,itmC.itmcEffective
				,itmC.itmcInactive
				,itmC.itmcQty 
			FROM dbo.ItemComponents itmC WITH(NOLOCK)
			JOIN #oriData oriC ON itmC.itmID = oriC.itmIDParent 
				AND itmC.CompItmID=oriC.itmID
			WHERE oriC.itmIDParent=@itmIDNew 
				AND oric.oriAction=23

			--删除该品项的组件
			DELETE s 
			FROM @CompItmData itmc
			JOIN dbo.ItemComponents s ON s.itmID=itmc.itmID
				AND s.CompItmID=itmc.compItmID
				AND s.itmcEffective=itmc.itmcEffective

			--添加BOM
			EXEC dbo.spAPP_utlProcessOrderItemEditing 
				@olnID=@olnID
				,@olnIDInstance=@olnIDInstance
				,@itmID=@itmID
				,@itmIDInstance=@itmIDInstance
				,@Action=2
				,@itmIDNew=@itmIDNew
				,@oriReqQtyNew=@oriReqQty
				,@PrimaryUOMCode=@primaryUOMCode
				,@TransUOMCodeNew=@primaryUOMCode
				,@rotID=NULL
				,@rotIDNew=NULL
				,@itmIDpdv=NULL
				,@itmIDTop=@itmIDSA	--Use the SA level ori instance
				,@AsOfDate=@AsOfDate
				-- configuration settings
				,@EnableAllocationReassignments = 0
				,@EnableCustomProperties  = 1
				,@EnableSurfaceAlternates  = 1
				,@EnableParametricDimensions  = 1
				,@EnablePurchasedDemandReassignments  = 0
				,@EnableConditionalComponents  = 1
				,@EnableImpliedComponents  = 1
				,@EnableCriteriaMatchReplacementParts  = 1
				,@EnableExactComponentMatchReplacementParts  = 1
				,@EnableConfiguredItemReplacementParts  = 1
				,@EnableRoutingReassignments = 2
				,@EnableMultiLevelRoutingReassignments  = 0
				,@EnableConditionalOperations  = 1
				,@EnableProcessedCostComputation  = 0
				,@EnableOutsourcedOperations  = 0
				,@EnableRollupBOMMatching  = 0 -- Enable Rollup BOM Match Processing. [0] = False, [1] = Match, [2] = Match and Purge
				,@EnableOrderItemBackscheduleComputation  = 1
				,@EnableProcessGroupFillFactor  = 0
				-- additional parameter-matched setting values used in processing
				,@MaxBOMProcessingIterations  = 20 -- Maximum [number] of iterations when performing iterative BOM processing.
				,@WorkOrderStartDateCalculationMethod  = 0 -- Determines the technique used to calculate Work Order Start Date: [0] - Process Group Offset, [1] - Operation Schedule Offset
				,@InitialOrderItemStatusValue  = 11000 -- Initial [Status Value] for Order Items
				,@EnableBOMDebugInfoLogging  = 0 -- Enables debug info logging in Application Log during BOM Processing. [0] = False, [1] = True
				,@MaxItemEdgesInCriteriaProperties  = 4 -- Maximum [number] of item edges to process in Criteria Property processing.
				,@InitialOrderLineInstanceStatusValue  = 1000
				,@FirmedOrderLineInstanceStatusValue = 1200
				,@DefaultSARoutingCode  = 15100
				,@WorkOrderStartDateOperationScheduleOffsetMode  = 1 -- Determines the technique used to calculate Operation Schedule Offset Work Order Start Date: [0] - Time Optimized,[1] - Yield Optimized
				,@CLRDebugMode  = default -- Sets flag to produce extended textual processing logging. See CLR SP call below for more.
				,@OutputCLRDebugging  = default -- When CLR Debug Mode is set and this code is run from SQL Server Management Studio, it prints and outputs log.
		
			--再添加已删除该品项的组件
			INSERT INTO dbo.ItemComponents(itmID,compItmID,itmcEffective,itmcInactive,itmcQty)
			SELECT itmID,compItmID,itmcEffective,itmcInactive,itmcQty FROM @CompItmData

			SET @WhileRow += 1;
		END
	END

	--记录日志
	/*
	INSERT INTO [dbo].[CUS_YLOrdOriginalBOMDataLog_OPP](ordId,pageName,itmID,itmIDInstance,olnID,olnIDInstance,oriReqQty,actions,createdOn,createdBy)
	SELECT 
		@ordID AS ordID
		,org.pageName AS pageName
		,YLOrd.itmID
		,YLOrd.itmIDInstance
		,YLOrd.olnID
		,YLOrd.olnIDInstance
		,org.oriReqQty
		,10
		,GETDATE()
		,USER_NAME()
	FROM @YLOrdItmTable YLOrd
	JOIN dbo.CUS_YLOrdOriginalBOMData_OPP org WITH(NOLOCK) ON YLOrd.itmID=org.itmID
		AND YLOrd.itmIDInstance=org.itmIDInstance
		AND YLOrd.olnID=org.olnID
		AND YLOrd.olnIDInstance=org.olnIDInstance

	--记录日志
	INSERT INTO [dbo].[CUS_YLOrdOriginalBOMDataLog_OPP](ordId,pageName,itmID,olnID,oriReqQty,actions,createdOn,createdBy)
	SELECT 
		@ordID AS ordID
		,ISNULL(o.pageName,N'数据变动') AS pageName
		,YLOrd.itmID
		,YLOrd.olnID
		,ISNULL(o.oriReqQty,0)AS oriReqQty
		,10
		,GETDATE()
		,USER_NAME()
	FROM @YLOrdItmTable YLOrd
	LEFT JOIN(
		SELECT org.pageName,org.itmID,org.info2,SUM(org.oriReqQty) AS oriReqQty
		FROM dbo.CUS_YLOrdOriginalBOMData_OPP org WITH(NOLOCK) 
		WHERE org.ordId=@ordID
			AND org.pageName IN(N'普通五金',N'实木五金')
		GROUP BY org.pageName,org.itmID,org.info2
	)o ON YLOrd.itmID=o.itmID AND ISNULL(YLOrd.info2,N'')=ISNULL(o.info2,N'')
	WHERE YLOrd.itmIDInstance IS NULL
	*/

	--记录日志,将修改后的BOM数据保存到日志表中
	;WITH T AS
	(
		SELECT 
			org.pageName
			,org.itmID
			,org.itmIDInstance
			,org.olnID
			,org.olnIDInstance
			,org.oriReqQty
			,ISNULL(org.info2,N'') AS info2 
		FROM dbo.CUS_YLOrdOriginalBOMData_OPP org WITH(NOLOCK)
		WHERE org.ordId=@ordID
			AND NOT EXISTS(SELECT 1 FROM @YLOrdItmTable YLOrd WHERE YLOrd.itmID=org.itmID
							AND YLOrd.itmIDInstance=org.itmIDInstance
							AND YLOrd.olnID=org.olnID
							AND YLOrd.olnIDInstance=org.olnIDInstance)
	)
	INSERT INTO [dbo].[CUS_YLOrdOriginalBOMDataLog_OPP](ordId,pageName,itmID,itmIDInstance,olnID,olnIDInstance,oriReqQty,actions,createdOn,createdBy)
	SELECT 
		@ordID AS ordID
		,tt.pageName
		,tt.itmID
		,tt.itmIDInstance
		,tt.olnID
		,tt.olnIDInstance
		,tt.oriReqQty
		,10
		,GETDATE()
		,USER_NAME()
	FROM T tt WITH(NOLOCK)
	WHERE NOT EXISTS(
		SELECT 1 FROM(SELECT t.itmID,t.itmIDInstance,t.olnID,t.olnIDInstance,t.oriReqQty
				FROM T t WHERE t.pageName IN (N'普通五金',N'实木五金') 
					AND EXISTS(SELECT 1 FROM @YLOrdItmTable YLOrd WHERE YLOrd.itmIDInstance IS NULL AND YLOrd.itmID=t.itmID AND ISNULL(YLOrd.info2,N'')=t.info2)
		)a WHERE tt.itmID=a.itmID AND tt.itmIDInstance=a.itmIDInstance AND tt.olnID=a.olnID AND tt.olnIDInstance=a.olnIDInstance
	)
	--删除原始
	DELETE dbo.CUS_YLOrdOriginalBOMData_OPP WHERE @ordID=@ordID AND pageName NOT IN(N'趟门',N'铝框门')
	
	--删除临时表
	DROP TABLE #oriData

	--提交事务
	COMMIT TRANSACTION
END TRY
BEGIN CATCH
	DECLARE @msg nvarchar(200)=ERROR_MESSAGE()    --将捕捉到的错误信息存在变量@msg中               
    RAISERROR (@msg,16,1)    --此处才能抛出(好像是这样子....)
	--回滚事务
	ROLLBACK TRANSACTION
END CATCH


