
/*
	批量操作五金 actions IN(1,2、3,4)【1、替换品项，2、添加，3删除、4修改】
*/
CREATE PROC [dbo].[spAPP_utlYLOrdEditingBatch_WJ_OPP]
	@ordID INT
	,@pageName NVARCHAR(50)
	,@ordSource NVARCHAR(50)=NULL
    ,@YLOrdItmTable YLOrdTableType_OPP READONLY
	,@YLOrdTotalTable YLOrdTotalTableType_OPP READONLY
AS 
SET NOCOUNT ON;

/*
	A、获取数据操作
		一、操作为替换、修改且尺寸无变化（操作为替换、修改）
		二、操作为替换、修改且尺寸变化（尺寸变化统一新建物料）
		三、操作为删除
		四、操作为增加
		五、记录日志
	B、数据处理
		一、处理加工车间等信息
		二、处理@optOriData表的删除、替换、修改
		三、处理新增数据
			1、品项新增
			2、新增现有品项

*/
--操作BOM表，包含删除、替换、修改操作
DECLARE @optOriData TABLE(RowID INT IDENTITY(1,1),itmIDNew INT,itmID INT,itmIDInstance SMALLINT,olnID INT,olnIDInstance SMALLINT,oriReqQty DECIMAL(18,2),primaryUOMCode NCHAR(5),itmIDSA INT,actions TINYINT)
DECLARE @addOriData TABLE(RowID INT IDENTITY(1,1),itmIDCopy INT,itmDescription NVARCHAR(100),oriReqQty DECIMAL(18,2),dimCX DECIMAL(18,2),dimCY DECIMAL(18,2),dimCZ DECIMAL(18,2)
	,dimFX DECIMAL(18,2),dimFY DECIMAL(18,2),dimFZ DECIMAL(18,2),Factory NVARCHAR(50),Duty NVARCHAR(50),PlateCategory NVARCHAR(50),LegacyPrice DECIMAL(18,2))
DECLARE @HaData TABLE(itmID INT,Factory NVARCHAR(50),Duty NVARCHAR(50),PlateCategory NVARCHAR(50),LegacyPrice DECIMAL(18,2))
--存储过程公用参数
DECLARE @WhileRow INT,@While INT,@itmID INT,@itmIDInstance SMALLINT,@olnID INT,@olnIDInstance SMALLINT,@itmIDNew INT,@itmIDInstanceNew SMALLINT,@oriReqQtyNew DECIMAL(19,6),@primaryUOMCode NCHAR(5),@itmIDSA INT,@actions TINYINT,@AsOfDate datetime =GETDATE()
--一、操作为替换、修改且存在尺寸变化的
INSERT INTO @optOriData(itmIDNew,itmID,itmIDInstance,olnID,olnIDInstance,oriReqQty,primaryUOMCode,itmIDSA,actions)
SELECT
	(CASE WHEN org.info2 IS NOT NULL AND ISNUMERIC(org.info3)=1 THEN org.info3 ELSE org.itmID END)AS itmID 
	 ,(CASE WHEN org.info2 IS NOT NULL AND ISNUMERIC(org.info3)=1 THEN org.info3 ELSE org.itmID END)AS itmID
	 ,(CASE WHEN org.info2 IS NOT NULL AND ISNUMERIC(org.info4)=1 THEN org.info4 ELSE org.itmIDInstance END)AS itmIDInstance
	 ,org.olnID
	 ,org.olnIDInstance
	 ,org.oriReqQty
	 ,org.primaryUOMCode
	 ,org.itmIDSA
	 ,3 AS actions		--表示删除操作
FROM @YLOrdItmTable YLOrd
JOIN [dbo].[CUS_YLOrdOriginalBOMData_OPP] org ON YLOrd.olnID=org.itmID
	AND ISNULL(org.dimFX,0) = ISNULL(YLOrd.dimCX,0)
	AND ISNULL(org.dimFY,0) = ISNULL(YLOrd.dimCY,0)
	AND ISNULL(org.dimFZ,0) = ISNULL(YLOrd.dimCZ,0)	
WHERE YLOrd.actions IN(1,4)
	AND NOT
	(
		ISNULL(YLOrd.dimCX,0) = ISNULL(YLOrd.dimFX,0) 
		AND 
		ISNULL(YLOrd.dimCY,0) = ISNULL(YLOrd.dimFY,0)
		AND 
		ISNULL(YLOrd.dimCZ,0) = ISNULL(YLOrd.dimFZ,0)
	)
	AND org.ordId=@ordID
	AND org.pageName=@pageName

INSERT INTO @addOriData(itmIDCopy,itmDescription,oriReqQty,dimCX,dimCY,dimCZ,dimFX,dimFY,dimFZ,Factory,Duty,PlateCategory,LegacyPrice)
SELECT 
	YLOrd.itmID AS itmIDCopy
	,YLOrd.itmDescription
	,YLOrd.oriReqQty
	,YLOrd.dimCX
	,YLOrd.dimCY
	,YLOrd.dimCZ
	,YLOrd.dimFX
	,YLOrd.dimFY
	,YLOrd.dimFZ
	,YLOrd.Factory
	,YLOrd.Duty
	,YLOrd.PlateCategory
	,YLOrd.LegacyPrice
FROM @YLOrdItmTable YLOrd
WHERE YLOrd.actions IN(1,4)
	AND NOT
	(
		ISNULL(YLOrd.dimCX,0) = ISNULL(YLOrd.dimFX,0) 
		AND 
		ISNULL(YLOrd.dimCY,0) = ISNULL(YLOrd.dimFY,0)
		AND 
		ISNULL(YLOrd.dimCZ,0) = ISNULL(YLOrd.dimFZ,0)
	)

--二、操作为替换、修改且尺寸未变化
--2.1.1只替换（替换且数量相等）
INSERT INTO @optOriData(itmIDNew,itmID,itmIDInstance,olnID,olnIDInstance,oriReqQty,primaryUOMCode,itmIDSA,actions)
SELECT 
	YLOrd.itmID AS itmIDNew
	,org.itmID 
	,org.itmIDInstance
	,org.olnID
	,org.olnIDInstance
	,org.oriReqQty
	,org.primaryUOMCode
	,org.itmIDSA
	,1 AS actions
FROM @YLOrdItmTable YLOrd
JOIN [dbo].[CUS_YLOrdOriginalBOMData_OPP] org ON YLOrd.olnID=org.itmID
	AND ISNULL(org.dimFX,0) = ISNULL(YLOrd.dimCX,0)
	AND ISNULL(org.dimFY,0) = ISNULL(YLOrd.dimCY,0)
	AND ISNULL(org.dimFZ,0) = ISNULL(YLOrd.dimCZ,0)	
WHERE YLOrd.actions =1
	AND ISNULL(YLOrd.dimCX,0) = ISNULL(YLOrd.dimFX,0) 
	AND ISNULL(YLOrd.dimCY,0) = ISNULL(YLOrd.dimFY,0)
	AND ISNULL(YLOrd.dimCZ,0) = ISNULL(YLOrd.dimFZ,0)
	AND ISNUMERIC(YLOrd.info5)= 1
	AND YLOrd.oriReqQty = CAST(YLOrd.info5 AS DECIMAL(18,2))

--2.1.2 替换且数量减少
;WITH T AS
(
	SELECT 
		YLOrd.itmID AS itmIDNew
		,org.itmID
		,org.itmIDInstance
		,org.olnID
		,org.olnIDInstance
		,org.oriReqQty
		,org.primaryUOMCode
		,org.itmIDSA
		,CAST(YLOrd.info5 AS DECIMAL(18,2)) - YLOrd.oriReqQty - SUM(org.oriReqQty)OVER(PARTITION BY org.itmID,org.dimFX,org.dimFY,org.dimFZ ORDER BY org.olnID,org.olnIDInstance,org.itmIDInstance ROWS UNBOUNDED PRECEDING) AS Qty
	FROM @YLOrdItmTable YLOrd
	JOIN [dbo].[CUS_YLOrdOriginalBOMData_OPP] org ON YLOrd.olnID=org.itmID
		AND ISNULL(org.dimFX,0) = ISNULL(YLOrd.dimCX,0)
		AND ISNULL(org.dimFY,0) = ISNULL(YLOrd.dimCY,0)
		AND ISNULL(org.dimFZ,0) = ISNULL(YLOrd.dimCZ,0)	
	WHERE YLOrd.actions =1
		AND ISNULL(YLOrd.dimCX,0) = ISNULL(YLOrd.dimFX,0) 
		AND ISNULL(YLOrd.dimCY,0) = ISNULL(YLOrd.dimFY,0)
		AND ISNULL(YLOrd.dimCZ,0) = ISNULL(YLOrd.dimFZ,0)
		AND ISNUMERIC(YLOrd.info5)= 1
		AND YLOrd.oriReqQty < CAST(YLOrd.info5 AS DECIMAL(18,2))
		AND org.ordId=@ordID
		AND org.pageName=@pageName
)
INSERT INTO @optOriData(itmIDNew,itmID,itmIDInstance,olnID,olnIDInstance,oriReqQty,primaryUOMCode,itmIDSA,actions)
SELECT 
	t.itmIDNew
	,t.itmID
	,t.itmIDInstance
	,t.olnID
	,t.olnIDInstance
	,(CASE WHEN t.Qty>=0 THEN t.oriReqQty WHEN t.Qty<0 AND t.oriReqQty>ABS(t.Qty) THEN t.oriReqQty+t.Qty ELSE t.oriReqQty END) AS oriReqQtyNew
	,t.primaryUOMCode
	,t.itmIDSA
	,(CASE WHEN t.Qty>=0 THEN 3 ELSE 1 END) AS actions --	当递减数大于等于0时，该行数量已减完。标记删除，剩余标记替换
FROM T t

--2.1.3 替换且数量增加
;WITH T AS
(
SELECT 
	YLOrd.itmID AS itmIDNew
	,org.itmID
	,org.itmIDInstance
	,org.olnID
	,org.olnIDInstance
	,org.oriReqQty
	,org.primaryUOMCode
	,org.itmIDSA
	,YLOrd.oriReqQty - CAST(YLOrd.info5 AS DECIMAL(18,2)) AS Qty
	,ROW_NUMBER()OVER(PARTITION BY org.itmID,org.dimFX,org.dimFY,org.dimFZ ORDER BY org.olnID,org.olnIDInstance,org.itmIDInstance)AS RowID
FROM @YLOrdItmTable YLOrd
JOIN [dbo].[CUS_YLOrdOriginalBOMData_OPP] org ON YLOrd.olnID=org.itmID
	AND ISNULL(org.dimFX,0) = ISNULL(YLOrd.dimCX,0)
	AND ISNULL(org.dimFY,0) = ISNULL(YLOrd.dimCY,0)
	AND ISNULL(org.dimFZ,0) = ISNULL(YLOrd.dimCZ,0)	
WHERE YLOrd.actions =1
	AND ISNULL(YLOrd.dimCX,0) = ISNULL(YLOrd.dimFX,0) 
	AND ISNULL(YLOrd.dimCY,0) = ISNULL(YLOrd.dimFY,0)
	AND ISNULL(YLOrd.dimCZ,0) = ISNULL(YLOrd.dimFZ,0)
	AND ISNUMERIC(YLOrd.info5)= 1
	AND YLOrd.oriReqQty > CAST(YLOrd.info5 AS DECIMAL(18,2))
	AND org.ordId=@ordID
	AND org.pageName=@pageName
)
INSERT INTO @optOriData(itmIDNew,itmID,itmIDInstance,olnID,olnIDInstance,oriReqQty,primaryUOMCode,itmIDSA,actions)
SELECT 
	t.itmIDNew
	,t.itmID
	,t.itmIDInstance
	,t.olnID
	,t.olnIDInstance
	,(CASE WHEN t.RowID=1 THEN t.oriReqQty+t.Qty ELSE t.oriReqQty END) AS oriReqQtyNew
	,t.primaryUOMCode
	,t.itmIDSA
	,1 AS actions	--在第一行的品项加上增加的数量
FROM T t

--2.1.4 替换时加工车间等信息
INSERT INTO @HaData(itmID,Factory,Duty,PlateCategory,LegacyPrice)
SELECT 
	(CASE WHEN YLOrd.info2 IS NOT NULL AND ISNUMERIC(YLOrd.info2)=1 THEN CAST(YLOrd.info2 AS INT) ELSE YLOrd.itmID END) AS itmID
	,YLOrd.Factory
	,YLOrd.Duty
	,YLOrd.PlateCategory
	,YLOrd.LegacyPrice
FROM @YLOrdItmTable YLOrd
WHERE YLOrd.actions =1
	AND ISNULL(YLOrd.dimCX,0) = ISNULL(YLOrd.dimFX,0) 
	AND ISNULL(YLOrd.dimCY,0) = ISNULL(YLOrd.dimFY,0)
	AND ISNULL(YLOrd.dimCZ,0) = ISNULL(YLOrd.dimFZ,0)

--2.2.1 修改且数量减少
;WITH T AS
(
	SELECT 
		org.itmID
		,org.itmIDInstance
		,org.olnID
		,org.olnIDInstance
		,org.oriReqQty
		,org.primaryUOMCode
		,org.itmIDSA
		,CAST(YLOrd.info5 AS DECIMAL(18,2)) - YLOrd.oriReqQty - SUM(org.oriReqQty)OVER(PARTITION BY org.itmID,org.dimFX,org.dimFY,org.dimFZ ORDER BY org.olnID,org.olnIDInstance,org.itmIDInstance) AS Qty
	FROM @YLOrdItmTable YLOrd
	JOIN [dbo].[CUS_YLOrdOriginalBOMData_OPP] org ON YLOrd.itmID=org.itmID
		AND ISNULL(org.dimFX,0) = ISNULL(YLOrd.dimCX,0)
		AND ISNULL(org.dimFY,0) = ISNULL(YLOrd.dimCY,0)
		AND ISNULL(org.dimFZ,0) = ISNULL(YLOrd.dimCZ,0)	
	WHERE YLOrd.actions =4
		AND ISNULL(YLOrd.dimCX,0) = ISNULL(YLOrd.dimFX,0) 
		AND ISNULL(YLOrd.dimCY,0) = ISNULL(YLOrd.dimFY,0)
		AND ISNULL(YLOrd.dimCZ,0) = ISNULL(YLOrd.dimFZ,0)
		AND ISNUMERIC(YLOrd.info5)= 1
		AND YLOrd.oriReqQty < CAST(YLOrd.info5 AS DECIMAL(18,2))
		AND org.ordId=@ordID
		AND org.pageName=@pageName
)
INSERT INTO @optOriData(itmIDNew,itmID,itmIDInstance,olnID,olnIDInstance,oriReqQty,primaryUOMCode,itmIDSA,actions)
SELECT 
	t.itmID
	,t.itmID
	,t.itmIDInstance
	,t.olnID
	,t.olnIDInstance
	,(CASE WHEN t.Qty>=0 THEN t.oriReqQty WHEN t.Qty<0 AND t.oriReqQty>ABS(t.Qty) THEN ABS(t.Qty) ELSE t.oriReqQty END) AS oriReqQtyNew
	,t.primaryUOMCode
	,t.itmIDSA
	,(CASE WHEN t.Qty>=0 THEN 3 ELSE 4 END) AS actions		--当递减数大于等于0时，该行数量已减完。标记删除，剩余标记替换
FROM T t
WHERE NOT(t.Qty<0 AND ABS(t.Qty)>=t.oriReqQty)				--当数量减完后不作处理	

----2.2.2 修改且数量增加
;WITH T AS
(
SELECT 
	org.itmID
	,org.itmIDInstance
	,org.olnID
	,org.olnIDInstance
	,org.oriReqQty
	,org.primaryUOMCode
	,org.itmIDSA
	,YLOrd.oriReqQty - CAST(YLOrd.info5 AS DECIMAL(18,2)) AS Qty
	,ROW_NUMBER()OVER(PARTITION BY org.itmID,org.dimFX,org.dimFY,org.dimFZ ORDER BY org.olnID,org.olnIDInstance,org.itmIDInstance)AS RowID
FROM @YLOrdItmTable YLOrd
JOIN [dbo].[CUS_YLOrdOriginalBOMData_OPP] org ON YLOrd.itmID=org.itmID
	AND ISNULL(org.dimFX,0) = ISNULL(YLOrd.dimCX,0)
	AND ISNULL(org.dimFY,0) = ISNULL(YLOrd.dimCY,0)
	AND ISNULL(org.dimFZ,0) = ISNULL(YLOrd.dimCZ,0)	
WHERE YLOrd.actions =4
	AND ISNULL(YLOrd.dimCX,0) = ISNULL(YLOrd.dimFX,0) 
	AND ISNULL(YLOrd.dimCY,0) = ISNULL(YLOrd.dimFY,0)
	AND ISNULL(YLOrd.dimCZ,0) = ISNULL(YLOrd.dimFZ,0)
	AND ISNUMERIC(YLOrd.info5)= 1
	AND YLOrd.oriReqQty > CAST(YLOrd.info5 AS DECIMAL(18,2))
	AND org.ordId=@ordID
	AND org.pageName=@pageName
)
INSERT INTO @optOriData(itmIDNew,itmID,itmIDInstance,olnID,olnIDInstance,oriReqQty,primaryUOMCode,itmIDSA,actions)
SELECT 
	t.itmID
	,t.itmID
	,t.itmIDInstance
	,t.olnID
	,t.olnIDInstance
	,t.oriReqQty+t.Qty AS oriReqQtyNew
	,t.primaryUOMCode
	,t.itmIDSA
	,4 AS actions	--在第一行的品项加上增加的数量
FROM T t
WHERE t.RowID=1

--2.2.3 修改时加工车间等信息
INSERT INTO @HaData(itmID,Factory,Duty,PlateCategory,LegacyPrice)
SELECT 
	(CASE WHEN YLOrd.info2 IS NOT NULL AND ISNUMERIC(YLOrd.info2)=1 THEN CAST(YLOrd.info2 AS INT) ELSE YLOrd.itmID END) AS itmID
	,YLOrd.Factory
	,YLOrd.Duty
	,YLOrd.PlateCategory
	,YLOrd.LegacyPrice
FROM @YLOrdItmTable YLOrd
WHERE YLOrd.actions =4
	AND ISNULL(YLOrd.dimCX,0) = ISNULL(YLOrd.dimFX,0) 
	AND ISNULL(YLOrd.dimCY,0) = ISNULL(YLOrd.dimFY,0)
	AND ISNULL(YLOrd.dimCZ,0) = ISNULL(YLOrd.dimFZ,0)

--三、操作为删除
INSERT INTO @optOriData(itmIDNew,itmID,itmIDInstance,olnID,olnIDInstance,oriReqQty,primaryUOMCode,itmIDSA,actions)
SELECT 
		(CASE WHEN org.info2=N'1' AND ISNUMERIC(org.info3)=1 THEN org.info3 ELSE org.itmID END)AS itmID
		,(CASE WHEN org.info2=N'1' AND ISNUMERIC(org.info3)=1 THEN org.info3 ELSE org.itmID END)AS itmID
		,(CASE WHEN org.info2=N'1' AND ISNUMERIC(org.info4)=1 THEN org.info4 ELSE org.itmIDInstance END)AS itmIDInstance
		,org.olnID
		,org.olnIDInstance
		,org.oriReqQty
		,org.primaryUOMCode
		,org.itmIDSA
		,3 AS actions		--表示删除操作
FROM @YLOrdItmTable YLOrd
JOIN [dbo].[CUS_YLOrdOriginalBOMData_OPP] org ON YLOrd.itmID=org.itmID
	AND ISNULL(org.dimFX,0) = ISNULL(YLOrd.dimCX,0)
	AND ISNULL(org.dimFY,0) = ISNULL(YLOrd.dimCY,0)
	AND ISNULL(org.dimFZ,0) = ISNULL(YLOrd.dimCZ,0)	
WHERE YLOrd.actions = 3
	AND org.ordId=@ordID
	AND org.pageName=@pageName

--四、操作为增加
--4.1 品项需要要新建
INSERT INTO @addOriData(itmIDCopy,itmDescription,oriReqQty,dimCX,dimCY,dimCZ,dimFX,dimFY,dimFZ,Factory,Duty,PlateCategory,LegacyPrice)
SELECT 
	YLOrd.itmID AS itmIDCopy
	,YLOrd.itmDescription
	,YLOrd.oriReqQty
	,YLOrd.dimCX
	,YLOrd.dimCY
	,YLOrd.dimCZ
	,YLOrd.dimFX
	,YLOrd.dimFY
	,YLOrd.dimFZ
	,YLOrd.Factory
	,YLOrd.Duty
	,YLOrd.PlateCategory
	,YLOrd.LegacyPrice
FROM @YLOrdItmTable YLOrd
WHERE YLOrd.actions = 2
	AND NOT
	(
		ISNULL(YLOrd.dimCX,0) = ISNULL(YLOrd.dimFX,0) 
		AND 
		ISNULL(YLOrd.dimCY,0) = ISNULL(YLOrd.dimFY,0)
		AND 
		ISNULL(YLOrd.dimCZ,0) = ISNULL(YLOrd.dimFZ,0)
	)
--4.2 直接绑定BOM
INSERT INTO @addOriData(itmIDCopy,oriReqQty)
SELECT 
	YLOrd.itmID AS itmIDCopy
	,YLOrd.oriReqQty
FROM @YLOrdItmTable YLOrd
WHERE YLOrd.actions = 2
	AND ISNULL(YLOrd.dimCX,0) = ISNULL(YLOrd.dimFX,0) 
	AND ISNULL(YLOrd.dimCY,0) = ISNULL(YLOrd.dimFY,0)
	AND ISNULL(YLOrd.dimCZ,0) = ISNULL(YLOrd.dimFZ,0)

--4.3 操作新增的其他信息
INSERT INTO @HaData(itmID,Factory,Duty,PlateCategory,LegacyPrice)
SELECT 
	YLOrd.itmID
	,YLOrd.Factory
	,YLOrd.Duty
	,YLOrd.PlateCategory
	,YLOrd.LegacyPrice
FROM @YLOrdItmTable YLOrd
WHERE YLOrd.actions = 2
	AND ISNULL(YLOrd.dimCX,0) = ISNULL(YLOrd.dimFX,0) 
	AND ISNULL(YLOrd.dimCY,0) = ISNULL(YLOrd.dimFY,0)
	AND ISNULL(YLOrd.dimCZ,0) = ISNULL(YLOrd.dimFZ,0)

--开启事务
BEGIN TRANSACTION

--一、处理其他信息
MERGE INTO dbo.hole_analysis T
USING
(
	SELECT 
		@ordID AS ordId
		,h.itmID
		,h.Factory
		,h.Duty
		,h.PlateCategory
		,h.LegacyPrice 
	FROM @HaData h
	WHERE NOT EXISTS(SELECT 1 FROM dbo.hole_analysis ha (NOLOCK) WHERE ha.ordID=@ordID AND ha.itmID=h.itmID 
						AND ISNULL(ha.Factory,N'')=ISNULL(h.Factory,N'') AND ISNULL(ha.Duty,N'')=ISNULL(h.Duty,N'') 
						AND ISNULL(ha.PlateCategory,N'')=ISNULL(h.PlateCategory,N'') AND ISNULL(ha.LegacyPrice,0)=ISNULL(h.LegacyPrice,0)
	)
)U ON U.ordId=T.ordID AND U.itmID=T.itmID
WHEN NOT MATCHED THEN INSERT(ordID,itmID,Factory,Duty,PlateCategory,LegacyPrice)
	VALUES(U.ordID,U.itmID,U.Factory,U.Duty,U.PlateCategory,U.LegacyPrice)
WHEN MATCHED THEN UPDATE SET T.Factory=U.Factory,T.Duty=U.Duty,T.PlateCategory=U.PlateCategory,T.LegacyPrice=U.LegacyPrice;
--删除表变量数量
DELETE FROM @HaData

--二、数据处理操作BOM
--替换、删除、修改操作
SELECT @WhileRow=MAX(RowID) FROM @optOriData
SET @While =1;
WHILE @While < @WhileRow+1
BEGIN
	SELECT 
		@itmID=ori.itmID
		,@itmIDInstance=ori.itmIDInstance
		,@olnID=ori.olnID
		,@olnIDInstance=ori.olnIDInstance
		,@itmIDNew=ori.itmIDNew
		,@oriReqQtyNew=ori.oriReqQty
		,@primaryUOMCode=ori.primaryUOMCode
		,@itmIDSA=ori.itmIDSA
		,@actions=ori.actions
	FROM @optOriData ori 
	WHERE ori.RowID=@While	
	--操作BOM
	EXEC dbo.spAPP_utlProcessOrderItemEditing 
		@olnID=@olnID
		,@olnIDInstance=@olnIDInstance
		,@itmID=@itmID
		,@itmIDInstance=@itmIDInstance
		,@Action=@actions
		,@itmIDNew=@itmIDNew
		,@oriReqQtyNew=@oriReqQtyNew
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
		
	SET @While+=1;
END

--删除原始数据
;WITH T AS
(
	SELECT 
			(CASE WHEN org.info2 IS NOT NULL AND ISNUMERIC(org.info3)=1 THEN org.info3 ELSE org.itmID END)AS itmID
			,(CASE WHEN org.info2 IS NOT NULL AND ISNUMERIC(org.info4)=1 THEN org.info4 ELSE org.itmIDInstance END)AS itmIDInstance
			,org.olnID
			,org.olnIDInstance 
	FROM [dbo].[CUS_YLOrdOriginalBOMData_OPP] org
	WHERE org.ordId=@ordID
		AND org.pageName=@pageName
)
DELETE t
FROM @optOriData s
JOIN T t ON s.itmID=t.itmID
	AND s.itmIDInstance=t.itmIDInstance
	AND s.olnID=t.olnID
	AND s.olnIDInstance=t.olnIDInstance
WHERE s.actions=3

----替换原始数据
;WITH T AS
(
		SELECT 
		ori.itmIDNew
		,ISNULL(MAX(org.itmIDInstance)OVER(PARTITION BY ori.itmIDNew,ori.olnID,ori.olnIDInstance ORDER BY ori.itmIDNew),0)
			+ ROW_NUMBER()OVER(PARTITION BY ori.itmIDNew,ori.olnID,ori.olnIDInstance ORDER BY ori.itmID)  AS itmIDInstanceNew
		,ori.itmID
		,ori.itmIDInstance
		,ori.olnID
		,ori.olnIDInstance
		,ori.oriReqQty
		,ori.actions
	FROM @optOriData ori
	LEFT JOIN [dbo].[CUS_YLOrdOriginalBOMData_OPP] org(NOLOCK) ON ori.itmIDNew=org.itmID
		AND ori.olnID=org.olnID
		AND ori.olnIDInstance=org.olnIDInstance
	WHERE ori.actions=1
)
UPDATE org SET org.itmID=t.itmIDNew,org.itmIDInstance=t.itmIDInstanceNew,org.oriReqQty=t.oriReqQty,org.actions=t.actions
FROM T t 
JOIN [dbo].[CUS_YLOrdOriginalBOMData_OPP] org ON t.itmID=org.itmID
	AND t.itmIDInstance=org.itmIDInstance
	AND t.olnID=org.olnID
	AND t.olnIDInstance=org.olnIDInstance

--修改原始数据
UPDATE org SET org.oriReqQty=t.oriReqQty,org.actions=t.actions
FROM @optOriData t
JOIN [dbo].[CUS_YLOrdOriginalBOMData_OPP] org ON t.itmID=org.itmID
	AND t.itmIDInstance=org.itmIDInstance
	AND t.olnID=org.olnID
	AND t.olnIDInstance=org.olnIDInstance
WHERE t.actions=4

--三、数据处理-新增数据
SELECT @WhileRow=MAX(RowID) FROM @addOriData
IF @WhileRow>0
BEGIN
	DECLARE @itmIDCopy INT,@newItmItemNumber NVARCHAR(50),@newItmDescription NVARCHAR(100),@dimCX DECIMAL(18,2),@dimCY DECIMAL(18,2),@dimCZ DECIMAL(18,2)
		,@dimFX DECIMAL(18,2),@dimFY DECIMAL(18,2),@dimFZ DECIMAL(18,2),@Factory NVARCHAR(50),@Duty NVARCHAR(50),@PlateCategory NVARCHAR(50),@LegacyPrice DECIMAL(18,2)

	SELECT TOP 1
		@itmID=ori.itmID
		,@itmIDInstance=ori.itmIDInstance
		,@olnID=ori.olnID
		,@olnIDInstance=ori.olnIDInstance
		,@itmIDSA=ori.itmID
	FROM dbo.OrderLines oln
	JOIN dbo.OrderItems ori ON ori.olnID = oln.olnID
	WHERE oln.ordID=@ordID
		AND ori.dlCode=N'SA'
	ORDER BY ori.olnID,ori.olnIDInstance	

	SET @While=1;
	WHILE @While < @WhileRow + 1
	BEGIN
		SELECT 
			@itmIDNew=addOri.itmIDCopy
			,@itmIDCopy=addOri.itmIDCopy
			,@newItmItemNumber=REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR(50),GETDATE(),121),N'-',N''),N':',N''),N' ',N'')+CAST(addOri.RowID AS NVARCHAR(5))
			,@newItmDescription=addOri.itmDescription
			,@oriReqQtyNew=addOri.oriReqQty
			,@primaryUOMCode=itm.primaryUOMCode
			,@dimCX=addOri.dimCX
			,@dimCY=addOri.dimCY
			,@dimCZ=addOri.dimCZ
			,@dimFX=addOri.dimFX
			,@dimFY=addOri.dimFY
			,@dimFZ=addOri.dimFZ
			,@Factory=addOri.Factory
			,@Duty=addOri.Duty
			,@PlateCategory=addOri.PlateCategory
			,@LegacyPrice=addOri.LegacyPrice
		FROM @addOriData addOri
		JOIN dbo.Items itm(NOLOCK) ON itm.itmID=addOri.itmIDCopy
		WHERE addOri.RowID=@While

		--若品项描述为空，则品项已存在，直接添加BOM
		IF @newItmDescription IS NULL
		BEGIN
			--增加已存在的BOM
			EXEC dbo.spAPP_utlProcessOrderItemEditing 
					@olnID=@OlnID
					,@olnIDInstance=@OlnIDInstance
					,@itmID=@ItmID
					,@itmIDInstance=@ItmIDInstance
					,@Action=2
					,@itmIDNew=@itmIDNew
					,@oriReqQtyNew=@oriReqQtyNew
					--,@AllItemInstances=0
					--,@AllOrderLineInstances=0
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
			
			SELECT 
				 @itmIDInstanceNew=ISNULL(MAX(org.itmIDInstance),0)+1
			FROM [dbo].[CUS_YLOrdOriginalBOMData_OPP] org(NOLOCK) 
			WHERE org.ordId=@ordID 
				AND org.pageName=@pageName 
				AND org.itmID=@itmIDNew
				AND org.olnID=@olnID
				AND org.olnIDInstance=@olnIDInstance

			INSERT INTO [dbo].[CUS_YLOrdOriginalBOMData_OPP](ordId,pageName,itmID,itmIDInstance,olnID,olnIDInstance,itmIDParent,itmIDParentInstance,itmIDSA,dlCode,actions,oriReqQty,primaryUOMCode)
			VALUES(@ordID,@pageName,@itmIDNew,@itmIDInstanceNew,@olnID,@olnIDInstance,@itmID,@itmIDInstance,@itmID,N'PP',2,@oriReqQtyNew,@primaryUOMCode)
		END
		ELSE
		BEGIN
			--先新建品项
			--添加品项--SELECT @newItmItemNumber,@newItmDescription,1,1,@primaryUOMCode,1,N'2000-01-01',N'9999-12-31'
			INSERT INTO dbo.Items(itmItemNumber,itmDescription,itmIsPurchased,itmpID,PrimaryUOMCode,itmoID,itmEffective,itmInactive)
			SELECT @newItmItemNumber,@newItmDescription,1,1,@primaryUOMCode,1,N'2000-01-01',N'9999-12-31'
			SELECT @itmIDNew=SCOPE_IDENTITY()
			--品项系
			INSERT INTO dbo.ItemItemFamilies(itmID,itmfCode)
			SELECT @itmIDNew,itmfCode FROM dbo.ItemItemFamilies WHERE itmID=@itmIDCopy
			--尺寸
			IF NOT(@dimFX IS NULL AND @dimFY IS NULL AND @dimFZ IS NULL)
			BEGIN
				INSERT INTO dbo.ItemDimensions(itmID, dimID, dimX, dimY, dimZ )VALUES(@itmIDNew,1,ISNULL(@dimFX,0),ISNULL(@dimFY,0),ISNULL(@dimFZ,0))
			END
			----添加ItemManufacturing
			--INSERT INTO dbo.ItemManufacturing(itmID,rotID,itmLeadTime,itmMultiPartPatternL,itmMultiPartPatternW,itmMultiPartRefEdge,itmMultiPartOrient,itmCutToFit)
			--SELECT @itmIDNew,rotID,itmLeadTime,itmMultiPartPatternL,itmMultiPartPatternW,itmMultiPartRefEdge,itmMultiPartOrient,itmCutToFit FROM dbo.ItemManufacturing WHERE itmID=@itmIDCopy
			--添加采购信息
			INSERT INTO ItemPurchasing(itmID,itmDemandOffset,ippID)
			SELECT @itmIDNew,itmDemandOffset,ippID FROM ItemPurchasing (NOLOCK) WHERE itmID=@itmIDCopy
			--添加Stocking
			INSERT INTO dbo.ItemStocking(itmID,itmsReorderPoint,itmsMinOrderQty,itmsOrderMultiple,StockingUOMCode,DefIimID,itmsIssueStatusValue,itmsABCCode,itmsPlanningHorizon,itmsSafetyStock
				,itmsIsAllocatable,ipbID,itmsPlanningFence,idmIDPlanningFenceRule,idmIDPlanningHorizonRule,ilmID,itmsOrderPeriods,ispID,atpmID)
			SELECT @itmIDNew,itmsReorderPoint,itmsMinOrderQty,itmsOrderMultiple,StockingUOMCode,DefIimID,itmsIssueStatusValue,itmsABCCode,itmsPlanningHorizon,itmsSafetyStock
				,itmsIsAllocatable,ipbID,itmsPlanningFence,idmIDPlanningFenceRule,idmIDPlanningFenceRule,ilmID,itmsOrderPeriods,ispID,atpmID
			 FROM dbo.ItemStocking (NOLOCK) WHERE itmID=@itmIDCopy

			--添加已新增品项的BOM
			EXEC dbo.spAPP_utlProcessOrderItemEditing 
					@olnID=@OlnID
					,@olnIDInstance=@OlnIDInstance
					,@itmID=@ItmID
					,@itmIDInstance=@ItmIDInstance
					,@Action=2
					,@itmIDNew=@itmIDNew
					,@oriReqQtyNew=@oriReqQtyNew
					--,@AllItemInstances=0
					--,@AllOrderLineInstances=0
					,@PrimaryUOMCode=@primaryUOMCode
					,@TransUOMCodeNew=@primaryUOMCode
					,@rotID=NULL
					,@rotIDNew=NULL
					,@itmIDpdv=NULL
					,@itmIDTop=@ItmIDSA	--Use the SA level ori instance
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

			INSERT INTO [dbo].[CUS_YLOrdOriginalBOMData_OPP](ordId,pageName,itmID,itmIDInstance,olnID,olnIDInstance,itmIDParent,itmIDParentInstance,itmIDSA,dlCode,actions,oriReqQty,primaryUOMCode,dimCX,dimCY,dimCZ,dimFX,dimFY,dimFZ)
			VALUES(@ordID,@pageName,@itmIDNew,1,@olnID,@olnIDInstance,@itmID,@itmIDInstance,@itmID,N'PP',2,@oriReqQtyNew,@primaryUOMCode,@dimCX,@dimCY,@dimCZ,@dimFX,@dimFY,@dimFZ)
		END

		SET @While+=1;
	END
END

	--四、
	--4、日志记录
	INSERT INTO [dbo].[CUS_YLOrdOriginalBOMDataLog_OPP](ordId,pageName,itmID,olnID,oriReqQty,actions,itmDescription,itmfCode
			,dimFX,dimFY,dimFZ,info1,info2,info5,Factory,Duty,PlateCategory,LegacyPrice,createdOn,createdBy)
	SELECT 
		@ordID AS ordID
		,@pageName AS pageName
		,YLOrd.itmID
		,ISNULL(YLOrd.olnID,YLOrd.itmID)
		,YLOrd.oriReqQty
		,YLOrd.actions
		,YLOrd.itmDescription
		,YLOrd.itmfCode
		,YLOrd.dimFX
		,YLOrd.dimFY
		,YLOrd.dimFZ
		,YLOrd.info1
		,YLOrd.info2
		,YLOrd.info5
		,YLOrd.Factory
		,YLOrd.Duty
		,YLOrd.PlateCategory
		,YLOrd.LegacyPrice
		,GETDATE()
		,USER_NAME()
	FROM @YLOrdItmTable YLOrd

	-- 六、汇总信息
	IF EXISTS(SELECT TOP 1 1 FROM @YLOrdTotalTable)
	BEGIN
		--删除当前页签数据
		DELETE FROM [dbo].[CUS_YLOrdPagesTotalData_OPP] WHERE OrdID=@ordID AND PageName=@pageName
		--
		MERGE INTO [dbo].[CUS_YLOrdPagesTotalData_OPP] T
		USING(
			SELECT @ordID AS ordID
				,PageName
				,PlateCategory
				,TotalPrice 
			FROM @YLOrdTotalTable
		)U ON T.OrdID=U.ordID AND T.PageName=U.PageName AND T.PlateCategory=U.PlateCategory
		WHEN MATCHED THEN UPDATE SET T.TotalPrice=U.TotalPrice
		WHEN NOT MATCHED THEN INSERT(OrdID,PageName,PlateCategory,TotalPrice)
			VALUES(U.ordID,U.PageName,U.PlateCategory,U.TotalPrice);
		
		--添加汇总日志
		INSERT INTO [dbo].[CUS_YLOrdPagesTotalDataLog_OPP](ordID,PageName,PlateCategory,TotalPrice,CreatedOn,CreatedBy)
		SELECT @ordID AS ordID
				,PageName
				,PlateCategory
				,TotalPrice
				,GETDATE() AS CreatedOn
				,SYSTEM_USER AS CreatedBy
		FROM @YLOrdTotalTable
	END
	ELSE
	BEGIN
		--删除当前页签数据
		DELETE FROM [dbo].[CUS_YLOrdPagesTotalData_OPP] WHERE OrdID=@ordID
		--添加汇总日志
		INSERT INTO [dbo].[CUS_YLOrdPagesTotalDataLog_OPP](ordID,CreatedOn,CreatedBy)
		SELECT @ordID AS ordID,GETDATE() AS CreatedOn,SYSTEM_USER AS CreatedBy FROM @YLOrdTotalTable
	END

--提交事务
COMMIT TRANSACTION;