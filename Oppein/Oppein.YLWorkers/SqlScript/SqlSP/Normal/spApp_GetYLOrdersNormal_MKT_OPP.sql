﻿
ALTER PROC [dbo].[spApp_GetYLOrdersNormal_MKT_OPP]
	@ordID INT
	,@pageName NVARCHAR(10)=N'木框门条'
	,@Factory NVARCHAR(50)=NULL
AS
SET NOCOUNT ON;

--DECLARE @ordID INT=2850477
--	,@pageName NVARCHAR(10)=N'木框门条'
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
			,ori.oriismfg
			,ori.oriReqQty
			,itm.itmItemNumber
			,itm.itmDescription
			,itm.PrimaryUOMCode
			,pd.pdDescription
		FROM dbo.Orders ord (NOLOCK)
		JOIN dbo.OrderLines oln (NOLOCK) ON oln.ordID = ord.ordID
		JOIN dbo.OrderLineProducts olnp (NOLOCK) ON olnp.olnID =  oln.olnID
		JOIN Product.Products pd (NOLOCK)ON pd.pdID = olnp.pdID
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
		,CAST(t.oriReqQty AS FLOAT) AS oriReqQty
		,itmItemF.itmfCode
		,(CASE WHEN CHARINDEX(' ',t.itmDescription)> 0 THEN t.pdDescription ELSE t.itmDescription END) AS itmDescription
		,ISNULL(org.itmDescription,(CASE WHEN CHARINDEX(' ',t.itmDescription)> 0 THEN t.pdDescription ELSE t.itmDescription END)) AS oItmDescription
		,itmf.itmfDescription
		,ISNULL(org.itmfDescription,itmf.itmfDescription) AS oItmfDescription
		,oriMat.TopSurCode AS topSurCode
		,ISNULL(org.topSurCode,oriMat.TopSurCode) AS oTopSurCode
		,oriMat.corCode
		,ISNULL(org.corCode,oriMat.corCode) AS oCorCode
		,CAST(oDim.dimCX AS FLOAT) AS dimCX
		,CAST(ISNULL(org.dimCX,oDim.dimCX) AS FLOAT) AS oDimCX
		,CAST(oDim.dimCY AS FLOAT) AS dimCY
		,CAST(ISNULL(org.dimCY,oDim.dimCY) AS FLOAT) AS oDimCY
		,CAST(oDim.dimCZ AS FLOAT) AS dimCZ
		,CAST(ISNULL(org.dimCZ,oDim.dimCZ) AS FLOAT) AS oDimCZ
		,CAST(oDim.dimFX AS FLOAT) AS dimFX
		,CAST(ISNULL(org.dimFX,oDim.dimFX) AS FLOAT) AS oDimFX
		,CAST(oDim.dimFY AS FLOAT) AS dimFY
		,CAST(ISNULL(org.dimFY,oDim.dimFY) AS FLOAT) AS oDimFY
		,CAST(oDim.dimFZ AS FLOAT) AS dimFZ
		,CAST(ISNULL(org.dimFZ,oDim.dimFZ) AS FLOAT) AS oDimFZ
		,ISNULL(cEdge.edgeCode,N'0000') AS edgeCode
		,ISNULL(org.edgeCode,N'0000') AS oEdgeCode
		,org.actions
		--,itmAv.itmavValue AS info5
		,ISNULL(ha.Factory,@Factory) AS Factory
		,ha.Duty
		,ISNULL(ha.PlateCategory,@PlateCategory) AS PlateCategory
		,CAST(lp.LegacyPrice AS FLOAT) AS Price		--单价
		,(CASE WHEN ha.LegacyPrice IS NOT NULL THEN CAST(ha.LegacyPrice AS FLOAT)
			ELSE (CASE WHEN lp.LegacyPrice IS NOT NULL 
					THEN CAST(oDim.dimFX * oDim.dimFY/1000000 * ISNULL(lp.LegacyPrice,0) AS DECIMAL(18,0))
					END)
			END) AS LegacyPrice		--总价
		,(CASE WHEN lp.LegacyPrice IS NOT NULL THEN CAST(oDim.dimFX * oDim.dimFY/1000000 * ISNULL(lp.LegacyPrice,0) AS DECIMAL(18,0)) END)AS oLegacyPrice
		--,CAST(ISNULL(ha.LegacyPrice,CAST(oDim.dimFX * oDim.dimFY/1000000 * ISNULL(lp.LegacyPrice,0) AS DECIMAL(18,0))) AS FLOAT) AS LegacyPrice		--总价
		--,CAST(oDim.dimFX * oDim.dimFY/1000000 * ISNULL(lp.LegacyPrice,0) AS DECIMAL(18,0)) AS oLegacyPrice
	FROM T t
	JOIN T SA ON t.olnID=SA.olnID AND SA.dlCode=N'SA'
	JOIN dbo.ItemItemFamilies itmItemF (NOLOCK) ON itmItemF.itmID = t.itmID
	JOIN dbo.ItemFamilies itmf (NOLOCK) ON itmf.itmfCode = itmItemF.itmfCode
	OUTER APPLY
	(
		SELECT 
			MAX(CASE dim.dimID WHEN 1 THEN CAST(dim.dimX AS DECIMAL(19,2))  END) AS dimFX
			,MAX(CASE dim.dimID WHEN 1 THEN CAST(dim.dimY AS DECIMAL(19,2)) END) AS dimFY
			,MAX(CASE dim.dimID WHEN 1 THEN CAST(dim.dimZ AS DECIMAL(19,2)) END) AS dimFZ
			,MAX(CASE dim.dimID WHEN 3 THEN CAST(dim.dimX AS DECIMAL(19,2)) END) AS dimCX
			,MAX(CASE dim.dimID WHEN 3 THEN CAST(dim.dimY AS DECIMAL(19,2)) END) AS dimCY
			,MAX(CASE dim.dimID WHEN 3 THEN CAST(dim.dimZ AS DECIMAL(19,2)) END) AS dimCZ
		FROM dbo.ItemDimensions dim (NOLOCK)
		WHERE dim.itmID=t.itmID AND dim.dimID IN(1,3)
	)oDim
	--Join dbo.CustomSetting_Opp cs (NOLOCK) On itmf.itmfCode=cs.SCode  
	OUTER APPLY
	(  
		SELECT 
			MAX(Case when orie.orieEdgeNo=4 then IsNull(iatbv.itmavValue,0) end) as Edge1  
			,MAX(Case when orie.orieEdgeNo=2 then IsNull(iatbv.itmavValue,0) end) as Edge2  
			,MAX(Case when orie.orieEdgeNo=3 then IsNull(iatbv.itmavValue,0) end) as Edge3  
			,MAX(Case when orie.orieEdgeNo=1 then IsNull(iatbv.itmavValue,0) end) as Edge4  
		FROM dbo.OrderItemEdges orie (NOLOCK)  
			JOIN dbo.SurfaceSourceItems ssi (NOLOCK) ON orie.surCode=ssi.surCode  
			JOIN dbo.ItemAttributeValues iatbv (NOLOCK) ON ssi.itmID=iatbv.itmID  
			JOIN dbo.Attributes atb (NOLOCK) ON iatbv.atbID=atb.atbID  
			JOIN dbo.AttributeCategories atbc (NOLOCK) ON atb.atbcID=atbc.atbcID  
		WHERE  t.itmID=orie.itmID 
			AND t.itmIDInstance=orie.itmIDInstance
			AND t.olnID=orie.olnID 
			AND t.olnIDInstance=orie.olnIDInstance  
			AND orie.surCode<>N'No Edge Application'  
			AND atb.atbCode=N'Edge_Thickness_Code' 
			AND atbc.atbcCode=N'Item Info'
	) iatb
	LEFT JOIN [dbo].[CUS_mOrdItemEdgeCode_OPP] cEdge ON cEdge.edge1=iatb.Edge1
		AND cEdge.edge2=iatb.Edge2
		AND cEdge.edge3=iatb.Edge3
		AND cEdge.edge4=iatb.Edge4
	LEFT JOIN dbo.OrderItemMaterials oriMat (NOLOCK) ON oriMat.itmID = t.itmID
		AND oriMat.itmIDInstance = t.itmIDInstance
		AND oriMat.olnID = t.olnID
		AND oriMat.olnIDInstance = t.olnIDInstance
	LEFT JOIN dbo.Materials mr (NOLOCK) ON mr.corCode = oriMat.corCode 
		AND mr.TopSurCode = oriMat.TopSurCode 
		AND mr.BotSurCode = oriMat.BotSurCode
	LEFT JOIN dbo.MaterialSourceItems itmm (NOLOCK)
		on oriMat.TopSurCode = itmm.TopSurCode
		AND oriMat.corCode = itmm.corCode 
		AND oriMat.BotSurCode = itmm.BotSurCode
	LEFT JOIN dbo.Items itmMat on itmMat.itmID = itmm.itmID
	LEFT JOIN [dbo].[CUS_YLOrdOriginalBOMData_OPP] org ON org.itmID=t.itmID
		AND org.itmIDInstance=t.itmIDInstance
		AND org.olnID=t.olnID
		AND org.olnIDInstance=t.olnIDInstance
	LEFT JOIN dbo.CUS_LegacyPriceData_OPP lp ON lp.PageName=@pageName AND lp.Thick=CAST(oDim.dimFZ AS INT)
	LEFT JOIN dbo.hole_analysis ha (NOLOCK) ON ha.itmID = t.itmID AND ha.ordID=@ordID
	WHERE t.oriismfg = 1
		AND itmf.itmfCode=N'MKT'
	ORDER BY org.itmfCode,oDim.dimFX DESC,oDim.dimFY DESC,oDim.dimFZ DESC,t.itmID
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
			,ori.oriismfg
			,itm.itmItemNumber
			,itm.itmDescription
			,itm.PrimaryUOMCode
			,pd.pdDescription
		FROM dbo.Orders ord (NOLOCK)
		JOIN dbo.OrderLines oln (NOLOCK) ON oln.ordID = ord.ordID
		JOIN dbo.OrderLineProducts olnp (NOLOCK) ON olnp.olnID =  oln.olnID
		JOIN Product.Products pd (NOLOCK)ON pd.pdID = olnp.pdID
		JOIN dbo.OrderItems ori (NOLOCK) ON ori.olnID = oln.olnID
		JOIN dbo.Items itm (NOLOCK) ON itm.itmID = ori.itmID
		WHERE ord.ordID = @ordID
	)
	INSERT INTO [dbo].[CUS_YLOrdOriginalBOMData_OPP](ordId,pageName,itmID,itmIDInstance,olnID,olnIDInstance,itmIDParent,itmIDParentInstance,itmIDSA,itmDescriptionSA,dlCode,oriReqQty,primaryUOMCode,itmItemNumber,itmDescription,itmfCode,itmfDescription,topSurCode,corCode,edgeCode,dimCX,dimCY,dimCZ,dimFX,dimFY,dimFZ)
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
		--,t.itmDescription
		,(CASE WHEN CHARINDEX(' ',t.itmDescription)> 0 THEN t.pdDescription ELSE t.itmDescription END) AS itmDescription
		,itmItemF.itmfCode
		,itmf.itmfDescription
		,oriMat.TopSurCode AS topSurCode
		,oriMat.corCode
		,ISNULL(cEdge.edgeCode,N'0000') AS edgeCode
		,CAST(oDim.dimCX AS FLOAT) AS dimCX
		,CAST(oDim.dimCY AS FLOAT) AS dimCY
		,CAST(oDim.dimCZ AS FLOAT) AS dimCZ
		,CAST(oDim.dimFX AS FLOAT) AS dimFX
		,CAST(oDim.dimFY AS FLOAT) AS dimFY
		,CAST(oDim.dimFZ AS FLOAT) AS dimFZ
	FROM T t
	JOIN T SA ON t.olnID=SA.olnID AND SA.dlCode=N'SA'
	JOIN dbo.ItemItemFamilies itmItemF (NOLOCK) ON itmItemF.itmID = t.itmID
	JOIN dbo.ItemFamilies itmf (NOLOCK) ON itmf.itmfCode = itmItemF.itmfCode
	OUTER APPLY
	(
		SELECT 
			MAX(CASE dim.dimID WHEN 1 THEN CAST(dim.dimX AS DECIMAL(18,2)) END) AS dimFX
			,MAX(CASE dim.dimID WHEN 1 THEN CAST(dim.dimY AS DECIMAL(18,2)) END) AS dimFY
			,MAX(CASE dim.dimID WHEN 1 THEN CAST(dim.dimZ AS DECIMAL(18,2)) END) AS dimFZ
			,MAX(CASE dim.dimID WHEN 3 THEN CAST(dim.dimX AS DECIMAL(18,2)) END) AS dimCX
			,MAX(CASE dim.dimID WHEN 3 THEN CAST(dim.dimY AS DECIMAL(18,2)) END) AS dimCY
			,MAX(CASE dim.dimID WHEN 3 THEN CAST(dim.dimZ AS DECIMAL(18,2)) END) AS dimCZ
		FROM dbo.ItemDimensions dim (NOLOCK)
		WHERE dim.itmID=t.itmID AND dim.dimID IN(1,3)
	)oDim
	OUTER APPLY
	(  
		SELECT 
			MAX(Case when orie.orieEdgeNo=4 then IsNull(iatbv.itmavValue,0) end) as Edge1  
			,MAX(Case when orie.orieEdgeNo=2 then IsNull(iatbv.itmavValue,0) end) as Edge2  
			,MAX(Case when orie.orieEdgeNo=3 then IsNull(iatbv.itmavValue,0) end) as Edge3  
			,MAX(Case when orie.orieEdgeNo=1 then IsNull(iatbv.itmavValue,0) end) as Edge4  
		FROM dbo.OrderItemEdges orie (NOLOCK)  
			JOIN dbo.SurfaceSourceItems ssi (NOLOCK) ON orie.surCode=ssi.surCode  
			JOIN dbo.ItemAttributeValues iatbv (NOLOCK) ON ssi.itmID=iatbv.itmID  
			JOIN dbo.Attributes atb (NOLOCK) ON iatbv.atbID=atb.atbID  
			JOIN dbo.AttributeCategories atbc (NOLOCK) ON atb.atbcID=atbc.atbcID  
		WHERE  t.itmID=orie.itmID 
			AND t.itmIDInstance=orie.itmIDInstance
			AND t.olnID=orie.olnID 
			AND t.olnIDInstance=orie.olnIDInstance  
			AND orie.surCode<>N'No Edge Application'  
			AND atb.atbCode=N'Edge_Thickness_Code' 
			AND atbc.atbcCode=N'Item Info'
	) iatb
	LEFT JOIN [dbo].[CUS_mOrdItemEdgeCode_OPP] cEdge (NOLOCK) ON cEdge.edge1=iatb.Edge1
		AND cEdge.edge2=iatb.Edge2
		AND cEdge.edge3=iatb.Edge3
		AND cEdge.edge4=iatb.Edge4
	LEFT JOIN dbo.OrderItemMaterials oriMat (NOLOCK) ON oriMat.itmID = t.itmID
		AND oriMat.itmIDInstance = t.itmIDInstance
		AND oriMat.olnID = t.olnID
		AND oriMat.olnIDInstance = t.olnIDInstance
	LEFT JOIN dbo.Materials mr (NOLOCK) ON mr.corCode = oriMat.corCode 
		AND mr.TopSurCode = oriMat.TopSurCode 
		AND mr.BotSurCode = oriMat.BotSurCode
	WHERE t.oriismfg = 1
		AND itmf.itmfCode=N'MKT'
	ORDER BY itmf.itmfDescription,oDim.dimFX DESC,oDim.dimFY DESC,oDim.dimFZ DESC

	SELECT 
		org.itmID
		,org.itmIDInstance
		,org.olnID
		,org.olnIDInstance
		--,org.itmIDParent
		--,org.itmIDParentInstance
		,org.itmIDSA
		,org.itmDescriptionSA
		,CAST(org.oriReqQty AS FLOAT) AS oriReqQty
		,org.itmItemNumber
		,org.itmfCode
		--,org.itmfCode AS oItmfCode
		,org.itmDescription
		,org.itmDescription AS oItmDescription
		,org.itmfDescription
		,org.itmfDescription AS oItmfDescription
		,org.TopSurCode AS topSurCode
		,org.TopSurCode AS oTopSurCode
		,org.corCode
		,org.corCode AS oCorCode
		,CAST(org.dimCX AS FLOAT) AS dimCX
		,CAST(org.dimCX AS FLOAT) AS oDimCX
		,CAST(org.dimCY AS FLOAT) AS dimCY
		,CAST(org.dimCY AS FLOAT) AS oDimCY
		,CAST(org.dimCZ AS FLOAT) AS dimCZ
		,CAST(org.dimCZ AS FLOAT) AS oDimCZ
		,CAST(org.dimFX AS FLOAT) AS dimFX
		,CAST(org.dimFX AS FLOAT) AS oDimFX
		,CAST(org.dimFY AS FLOAT) AS dimFY
		,CAST(org.dimFY AS FLOAT) AS oDimFY
		,CAST(org.dimFZ AS FLOAT) AS dimFZ
		,CAST(org.dimFZ AS FLOAT) AS oDimFZ
		,ISNULL(org.edgeCode,N'0000') AS edgeCode
		,ISNULL(org.edgeCode,N'0000') AS oEdgeCode
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
	ORDER BY org.itmfCode,org.dimFX DESC,org.dimFY DESC,org.dimFZ DESC,org.itmID
END



