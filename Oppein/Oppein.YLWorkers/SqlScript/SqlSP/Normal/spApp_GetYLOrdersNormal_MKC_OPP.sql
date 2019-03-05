

ALTER PROC [dbo].[spApp_GetYLOrdersNormal_MKC_OPP]
	@ordID INT
	,@pageName NVARCHAR(10)=N'木框抽面'
	,@Factory NVARCHAR(50)=NULL
AS
SET NOCOUNT ON;

--DECLARE @ordID INT=2850477
--	,@pageName NVARCHAR(10)=N'木框抽面'
--	,@Factory NVARCHAR(50)

DECLARE @PlateCategory NVARCHAR(50)
SELECT @PlateCategory=PlateCategory FROM [dbo].[CUS_YLOrdPagesData_OPP] WHERE PageName=@pageName
SELECT @Factory=FactoryDefualt FROM [dbo].[CUS_YLOrdPageFactoryDefualt_OPP] WHERE Factory=@Factory AND PageName=@pageName 
--判断原始表数据是否存在(若存则关联，若不存在则插入)
IF EXISTS(SELECT 1 FROM [dbo].[CUS_YLOrdOriginalBOMData_OPP] WHERE ordId=@ordID AND pageName=@pageName)
BEGIN
	;WITH T AS
	(
		SELECT 
			oln.olnLineNo 
			,ori.itmID
			,ori.itmIDInstance
			,ori.olnID
			,ori.olnIDInstance
			,ori.itmIDParent
			,ori.itmIDParentInstance
			,ori.dlCode
			,ori.oriIsPurchased
			,ori.itmpID
			,ori.oriReqQty
			,itm.itmItemNumber
			,itm.itmDescription
			,itm.PrimaryUOMCode
		FROM dbo.Orders ord (NOLOCK)
		JOIN dbo.OrderLines oln (NOLOCK) ON oln.ordID = ord.ordID
		JOIN dbo.OrderItems ori (NOLOCK) ON ori.olnID = oln.olnID
		JOIN dbo.Items itm (NOLOCK) ON itm.itmID = ori.itmID
		WHERE ord.ordID = @ordID
	)
	SELECT
		t.itmID
		,t.itmIDInstance
		,t.olnID
		,t.olnIDInstance
		,t.itmItemNumber
		,SA.itmID AS itmIDSA
		,SA.itmDescription AS itmDescriptionSA
		,CAST(t.oriReqQty AS FLOAT) AS oriReqQty	--数量
		,t.itmDescription
		,itmF.itmfCode
		,imr.TopSurCode AS topSurCode
		,imr.corCode
		,CAST(CAST(dimF.dimX AS DECIMAL(18,1))AS FLOAT)AS dimFX
		,CAST(CAST(dimF.dimY AS DECIMAL(18,1))AS FLOAT) AS dimFY
		,CAST(CAST(dimF.dimZ AS DECIMAL(18,1))AS FLOAT) AS dimFZ
		,CAST(CAST(dimF.dimX*dimF.dimY/1000000 AS DECIMAL(18,3))AS FLOAT) AS Area
		,ha.Remark AS info6
		,ISNULL(ha.newdmRemark,itmAv.info1) AS info14
		,ISNULL(ha.holeRemark,itmAv.info2) AS info15
		,ISNULL(org.itmDescription,t.itmDescription) AS oItmDescription
		,ISNULL(org.topSurCode,imr.TopSurCode) AS oTopSurCode
		,ISNULL(org.corCode,imr.corCode) AS oCorCode
		,CAST(CAST(ISNULL(org.dimFX,dimF.dimX)AS DECIMAL(18,1))AS FLOAT) AS oDimFX
		,CAST(CAST(ISNULL(org.dimFY,dimF.dimY)AS DECIMAL(18,1))AS FLOAT) AS oDimFY
		,CAST(CAST(ISNULL(org.dimFZ,dimF.dimZ)AS DECIMAL(18,1))AS FLOAT) AS oDimFZ
		,CAST((CASE WHEN org.dimFX IS NOT NULL THEN CAST(org.dimFX*org.dimFY/1000000 AS DECIMAL(18,3))
			ELSE CAST(dimF.dimX*dimF.dimY/1000000 AS DECIMAL(18,3)) END)AS FLOAT) AS oArea
		,ISNULL(org.info6,ha.Remark) AS info6
		,COALESCE(org.info14,ha.newdmRemark,itmAv.info1) AS oInfo14
		,COALESCE(org.info15,ha.holeRemark,itmAv.info2) AS oInfo15
		,org.actions
		,ISNULL(ha.Factory,@Factory) AS Factory
		,ha.Duty
		,ISNULL(ha.PlateCategory,@PlateCategory) AS PlateCategory
		,CAST(lp.LegacyPrice AS FLOAT) AS Price
		,(CASE WHEN ha.LegacyPrice IS NOT NULL THEN CAST(ha.LegacyPrice AS FLOAT)
			ELSE (CASE WHEN lp.LegacyPrice IS NOT NULL 
					THEN CAST(dimF.dimX * dimF.dimY/1000000 * ISNULL(lp.LegacyPrice,0) AS DECIMAL(18,0))
					END)
			END) AS LegacyPrice		--总价
		,(CASE WHEN lp.LegacyPrice IS NOT NULL THEN CAST(dimF.dimX * dimF.dimY/1000000 * ISNULL(lp.LegacyPrice,0) AS DECIMAL(18,0)) END)AS oLegacyPrice
	FROM T t
	JOIN T SA ON t.olnID=SA.olnID AND SA.dlCode=N'SA'
	JOIN dbo.ItemItemFamilies itmF(NOLOCK) ON itmF.itmfCode =N'BFMKC' AND t.itmID =itmF.itmID
	JOIN dbo.ItemDimensions dimF(NOLOCK) ON dimF.dimID =1 AND dimF.itmID = t.itmID
	JOIN dbo.ItemMaterials imr(NOLOCK) ON imr.itmID = t.itmID
	/*获取imos传过来的值*/
	outer apply(
		SELECT
			max(case when ibv.atbID =44  then ibv.itmavValue end) info1   --备注
			,MAX(CASE WHEN ibv.atbID =45 THEN ibv.itmavValue END) AS info2	--开门方向
		from dbo.ItemAttributeValues ibv(NOLOCK)
		WHERE ibv.itmID = t.itmID
			AND ibv.atbID IN (44,45)
	)itmAv
	LEFT JOIN dbo.hole_analysis ha(NOLOCK) ON ha.itmID = t.itmID AND ha.ordID=@ordID
	LEFT JOIN [dbo].[CUS_YLOrdOriginalBOMData_OPP] org ON org.itmID=t.itmID
			AND org.itmIDInstance=t.itmIDInstance
			AND org.olnID=t.olnID
			AND org.olnIDInstance=t.olnIDInstance
	LEFT JOIN dbo.CUS_LegacyPriceData_OPP lp ON lp.PageName=@pageName AND lp.Thick=CAST(dimF.dimZ AS INT)
	WHERE t.dlCode=N'MA'
	ORDER BY itmF.itmfCode,dimF.dimX DESC,dimF.dimY DESC,dimF.dimZ DESC,t.itmID
END
ELSE
BEGIN
	;WITH T AS
	(
		SELECT 
			oln.olnLineNo 
			,ori.itmID
			,ori.itmIDInstance
			,ori.olnID
			,ori.olnIDInstance
			,ori.itmIDParent
			,ori.itmIDParentInstance
			,ori.dlCode
			,ori.oriIsPurchased
			,ori.itmpID
			,ori.oriReqQty
			,itm.itmItemNumber
			,itm.itmDescription
			,itm.PrimaryUOMCode
		FROM dbo.Orders ord (NOLOCK)
		JOIN dbo.OrderLines oln (NOLOCK) ON oln.ordID = ord.ordID
		JOIN dbo.OrderItems ori (NOLOCK) ON ori.olnID = oln.olnID
		JOIN dbo.Items itm (NOLOCK) ON itm.itmID = ori.itmID
		WHERE ord.ordID = @ordID
	)
	INSERT INTO [dbo].[CUS_YLOrdOriginalBOMData_OPP](ordId,pageName,itmID,itmIDInstance,olnID,olnIDInstance,itmIDParent,itmIDParentInstance,itmIDSA,itmDescriptionSA,dlCode,oriReqQty,primaryUOMCode,itmItemNumber,itmDescription,itmfCode,topSurCode,corCode,dimFX,dimFY,dimFZ,info6)
	SELECT 
		@ordID AS ordID
		,@pageName AS pageName
		,t.itmID
		,t.itmIDInstance
		,t.olnID
		,t.olnIDInstance
		,t.itmIDParent
		,t.itmIDParentInstance
		,sa.itmID
		,sa.itmDescription AS itmDescriptionSA
		,t.dlCode
		,t.oriReqQty
		,t.PrimaryUOMCode
		,t.itmItemNumber
		,t.itmDescription
		,itmF.itmfCode
		,imr.TopSurCode AS topSurCode
		,imr.corCode
		,CAST(dimF.dimX AS FLOAT) AS dimFX
		,CAST(dimF.dimY AS FLOAT) AS dimFY
		,CAST(dimF.dimZ AS FLOAT) AS dimFZ
		,itmAv.info1 AS info6
	FROM T t
	JOIN T SA ON t.olnID=SA.olnID AND SA.dlCode=N'SA'
	JOIN dbo.ItemItemFamilies itmF(NOLOCK) ON itmF.itmfCode =N'BFMKC' AND t.itmID =itmF.itmID
	JOIN dbo.ItemDimensions dimF(NOLOCK) ON dimF.dimID =1 AND dimF.itmID = t.itmID
	JOIN dbo.ItemMaterials imr(NOLOCK) ON imr.itmID = t.itmID
	/*获取imos传过来的值*/
	outer apply(
		SELECT
			max(case when ibv.atbID =44  then ibv.itmavValue end) info1   --备注
			,MAX(CASE WHEN ibv.atbID =45 THEN ibv.itmavValue END) AS info2	--开门方向
		from dbo.ItemAttributeValues ibv(NOLOCK)
		WHERE ibv.itmID = t.itmID
			AND ibv.atbID IN (44,45)
	)itmAv
	WHERE t.dlCode=N'MA'
	ORDER BY itmF.itmfCode,dimF.dimX DESC,dimF.dimY DESC,dimF.dimZ DESC,t.itmID

	SELECT 
		org.itmID
		,org.itmIDInstance
		,org.olnID
		,org.olnIDInstance
		,org.itmIDSA
		,org.itmDescriptionSA
		,org.oriReqQty
		,org.itmItemNumber
		,org.itmfCode
		,org.itmDescription
		,org.itmDescription AS oItmDescription
		,org.TopSurCode AS topSurCode
		,org.TopSurCode AS oTopSurCode
		,org.corCode
		,org.corCode AS oCorCode
		--,CAST(org.dimCX AS FLOAT) AS dimCX
		--,CAST(org.dimCX AS FLOAT) AS oDimCX
		--,CAST(org.dimCY AS FLOAT) AS dimCY
		--,CAST(org.dimCY AS FLOAT) AS oDimCY
		--,CAST(org.dimCZ AS FLOAT) AS dimCZ
		--,CAST(org.dimCZ AS FLOAT) AS oDimCZ
		,CAST(org.dimFX AS FLOAT) AS dimFX
		,CAST(org.dimFX AS FLOAT) AS oDimFX
		,CAST(org.dimFY AS FLOAT) AS dimFY
		,CAST(org.dimFY AS FLOAT) AS oDimFY
		,CAST(org.dimFZ AS FLOAT) AS dimFZ
		,CAST(org.dimFZ AS FLOAT) AS oDimFZ
		,org.info6
		,org.info6 AS oInfo6
		,org.info14
		,org.info14 AS oInfo14
		,org.info15
		,org.info15 AS oInfo15
		,org.actions
		,ISNULL(ha.Factory,@Factory) AS Factory
		,ha.Duty
		,ISNULL(ha.PlateCategory,@PlateCategory) AS PlateCategory
		,CAST(lp.LegacyPrice AS FLOAT) AS Price		--单价
		,(CASE WHEN ha.LegacyPrice IS NOT NULL THEN CAST(ha.LegacyPrice AS FLOAT)
			ELSE (CASE WHEN lp.LegacyPrice IS NOT NULL 
					THEN CAST(org.dimFX * org.dimFY/1000000 * ISNULL(lp.LegacyPrice,0) AS DECIMAL(18,0))
					END)
			END) AS LegacyPrice		--总价
		,(CASE WHEN lp.LegacyPrice IS NOT NULL THEN CAST(org.dimFX * org.dimFY/1000000 * ISNULL(lp.LegacyPrice,0) AS DECIMAL(18,0)) END)AS oLegacyPrice
	FROM [dbo].[CUS_YLOrdOriginalBOMData_OPP] org
	LEFT JOIN dbo.CUS_LegacyPriceData_OPP lp ON lp.PageName=@pageName AND lp.Thick=CAST(org.dimFZ AS INT)
	LEFT JOIN dbo.hole_analysis ha (NOLOCK) ON ha.ordID=org.ordId AND ha.itmID = org.itmID
	WHERE org.ordId=@ordID
		AND org.pageName=@pageName
END